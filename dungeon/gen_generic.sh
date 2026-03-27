#!/usr/bin/env bash

# We can generate the maximum amount of bytes we're going to pass to any of our
#   scenarios ahead of time. Artificially cap the size by setting a lower
#   length (in Noir) but the circuit still then has to take the "full" sized
#   input regardless.

source '../harness/stdlib.sh'

readonly min_exponent=5
# readonly max_exponent=20
readonly max_exponent=16

readonly -a iterations=(1 10 100)

readonly max_bytes="$(( 2 ** max_exponent * ${iterations[-1]} ))"

readonly scenario_type="keccak256"

pushd "$(pwd)" 1> /dev/null

if [[ ! -d "$scenario_type" ]]; then
    mkdir "$scenario_type"
fi

source 'aztec_templates_2.sh'
source 'gen_master_bytes.sh'
# source 'gen_master_bytes_v2.sh'

call format_master_bytes

rm -rf "$scenario_type"/*
pushd "$scenario_type" 1> /dev/null

for ((b = min_exponent ; b <= max_exponent ; b++)); do
    declare bytes="$(( 2 ** b ))"

    for i in "${iterations[@]}"; do
        # Perhaps a little cursed we keep the same prefix number for each iteration but
        #   honestly it's fine over three subfolders per input byte-sized I think.
        printf -v scenario_name '%02d__%d_bytes_%d' "$(( b + 1 - min_exponent ))" "${bytes}" "$i"
        printf '%s\n' "$scenario_name"

        # Check function name exists for the file templates we're going to try make.
        if [[ ! $(declare -F "${scenario_type}_circuit") ]]; then
            # TODO: Better error, import and use stdlib perhaps
            # die "Function '$f_ptr' not found."
            printf 'NO FUNCTION NAME FOUND\n'
            exit 1
        fi

        mkdir "${scenario_type}__${scenario_name}"
        pushd "${scenario_type}__${scenario_name}" 1> /dev/null

        call keccak256_circuit

        popd 1> /dev/null
    done

    unset -v bytes
    unset -v scenario_name
done
