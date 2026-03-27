#!/usr/bin/env bash

gather_master_bytes ()
{
    head -c "${max_bytes:?}" /dev/urandom \
        | hexdump -v -e '1/1 "%u,\n"' \
            > master_bytes.txt
}


format_master_bytes ()
{
    # Uglier way of getting random decimal byte per line with trailing comma to avoid joining
    #   at every exponent interation (reading back, joining commas, etc etc).

    if [[ ! -d master_bytes ]]; then
        mkdir master_bytes
    fi

    rm -rf master_bytes/*
    pushd master_bytes 1> /dev/null || exit 1

    call gather_master_bytes

    # Pre-slice common byte ranges we're interested in.
    for ((b = "${min_exponent:?}" ; b <= "${max_exponent:?}" ; b++)); do
        declare bytes="$(( 2 ** b ))"

        for i in "${iterations[@]:?}"; do
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

    popd 1> /dev/null || exit 1
}
