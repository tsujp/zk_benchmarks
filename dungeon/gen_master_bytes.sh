#!/usr/bin/env bash


generate_thingy ()
{
    head -c "$max_bytes" /dev/urandom \
        | od -An -v -t u1 \
        | tr -s ' ' '\n' \
        | tail -n +2 \
        | sed 's/$/,/' \
              > master_bytes.txt
}

generate_thingy2 ()
{
    head -c "$max_bytes" /dev/urandom \
        | od -An -v -t u1 \
        | awk '{for(i=1;i<=NF;i++) printf "%s,\n", $i}' \
            > master_bytes.txt
}

generate_thingy3 ()
{
    head -c "$max_bytes" /dev/urandom \
        | hexdump -v -e '1/1 "%u,\n"' \
            > master_bytes.txt
}

generate_thingy4 ()
{
    hexdump -v -e '1/1 "%u,\n"' -n "$max_bytes" /dev/urandom > master_bytes.txt
}

generate_thingy_raw ()
{
    head -c "$max_bytes" /dev/urandom \
            > master_bytes.txt
}


gather_master_bytes ()
{
    head -c "$max_bytes" /dev/urandom \
        | hexdump -v -e '1/1 "%u,\n"' \
            > master_bytes.txt
}


format_master_bytes ()
{
    # Uglier way of getting random decimal byte per line with trailing comma to avoid joining
    #   at every exponent interation (reading back, joining commas, etc etc).
    # TODO: Later just dump this as-is from /dev/urandom and use head to get bytes from the front
    #       if it's cleaner.
    # shuf --random-source=/dev/urandom -i 0-255 -r -n "$bytes" | sed 's/$/,/' > master_bytes

    if [[ ! -d master_bytes ]]; then
        mkdir master_bytes
    fi

    rm -rf master_bytes/*
    pushd master_bytes 1> /dev/null

    call gather_master_bytes

    # Pre-slice common byte ranges we're interested in.
    for ((b = min_exponent ; b <= max_exponent ; b++)); do
        declare bytes="$(( 2 ** b ))"

        for i in "${iterations[@]}"; do
            printf "=> (bytes: %s), (slices: %s)\n" "$bytes" "$i"
            printf -v scenario_name '%02d__%d_bytes_%d' "$(( b + 1 - min_exponent ))" "${bytes}" "$i"

            awk -v byte_size="$bytes" -v slices="$i" '
NR > (byte_size * slices) { exit }

# Pre-format for array-based slices.
BEGIN {
    if (slices > 1)
        printf "["
}

{
    if ((NR - 1) % byte_size == 0)
        printf "["
    
    printf "%s", $0

    # Prevent trailing comma (invalid TOML) on non-array slices while leaving it (valid) for
    #   array inputs (in both cases to Prover.toml)
    if (NR % byte_size == 0)
        printf (slices > 1) ? "],\n" : "]\n"
}

# Pre-format for array-based slices.
END {
    if (slices > 1)
        printf "]"
}
' master_bytes.txt > "${scenario_name}.txt"
        done

        unset -v bytes
        unset -v scenario_name
    done

    popd 1> /dev/null
}


format_master_bytes_2 ()
{
    # Uglier way of getting random decimal byte per line with trailing comma to avoid joining
    #   at every exponent interation (reading back, joining commas, etc etc).
    # TODO: Later just dump this as-is from /dev/urandom and use head to get bytes from the front
    #       if it's cleaner.
    # shuf --random-source=/dev/urandom -i 0-255 -r -n "$bytes" | sed 's/$/,/' > master_bytes

    if [[ ! -d master_bytes ]]; then
        mkdir master_bytes
    fi

    rm -rf master_bytes/*
    pushd master_bytes 1> /dev/null

    call gather_master_bytes

    # Generated largest exponent master bytes (of each iteration type) for subset slicing later.
    declare -A iteration_masters=()

    # Generate iterations for largest exponent first since all others are effective subsets.
    for i in "${iterations[@]}"; do
        declare bytes="$(( 2 ** max_exponent ))"
        printf "=> (bytes: %s), (slices: %s)\n" "$bytes" "$i"

        printf -v scenario_name '%02d__%d_bytes_%d' "$(( max_exponent - min_exponent ))" "${bytes}" "$i"

        awk -v byte_size="$bytes" -v slices="$i" '
NR > (byte_size * slices) { exit }

{
    if ((NR - 1) % byte_size == 0)
        printf "["
    
    printf "%s", $0

    if (NR % byte_size == 0)
        printf "],\n"
}
' master_bytes.txt > "${scenario_name}.txt"

        iteration_masters["$i"]="${scenario_name}.txt"
    done

    unset -v bytes
    unset -v scenario_name


    # NOTE: This is incomplete and doesn't work properly since `head` cannot possibly read in bytes when we have decimal integers literally in the source file.
    # Now slice all subsets out of those larger iterations.
    for ((b = min_exponent ; b <= (max_exponent - 1) ; b++)); do
        declare bytes="$(( 2 ** b ))"
        for i in "${iterations[@]}"; do
            printf "=> (bytes: %s), (slices: %s)\n" "$bytes" "$i"
            printf -v scenario_name '%02d__%d_bytes_%d' "$(( b + 1 - min_exponent ))" "${bytes}" "$i"

            head -n "$bytes" "${iteration_masters["$i"]}" \
                 > "${scenario_name}.txt"
        done
    done

    unset -v bytes
    unset -v scenario_name
    
    unset -v iteration_masters

    popd 1> /dev/null
}
