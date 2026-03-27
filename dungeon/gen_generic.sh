#!/usr/bin/env bash

set -euo pipefail
set -o nounset
shopt -s lastpipe

if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi



# We can generate the maximum amount of bytes we're going to pass to any of our
#   scenarios ahead of time. Artificially cap the size by setting a lower
#   length (in Noir) but the circuit still then has to take the "full" sized
#   input regardless.

if [[ "$(uname -n)" = 'benchy-aztec-barretenberg' ]]; then
    source '../.benchy_imaged.sh'
else
    source '../harness/stdlib.sh'
fi

source 'gen_master_bytes.sh'
source 'aztec_templates.sh'

readonly min_exponent=0
# readonly max_exponent=20
readonly max_exponent=16

readonly -a iterations=(1 10 100)

readonly max_bytes="$(( 2 ** max_exponent * ${iterations[-1]} ))"

readonly -a category_types=(
    'keccak256'
    'sha256'
    'poseidon2'
)

# Non-absolute, used relative to current.
readonly OUTPUT_FOLDER='circuits'

pushd "$(pwd)" 1> /dev/null

if [[ ! -d "$OUTPUT_FOLDER" ]]; then
    mkdir "$OUTPUT_FOLDER"
fi

call format_master_bytes

rm -rf "${OUTPUT_FOLDER:?}"/*
pushd "$OUTPUT_FOLDER" 1> /dev/null

for category in "${category_types[@]}"; do
    # Check function name exists for the file templates we're going to try make.
    if [[ ! $(declare -F "${category}_circuit") ]]; then
        # TODO: Better error, import and use stdlib perhaps
        # die "Function '$f_ptr' not found."
        printf 'NO FUNCTION NAME FOUND\n'
        exit 1
    fi

    for ((b = min_exponent ; b <= max_exponent ; b++)); do
        declare bytes="$(( 2 ** b ))"

        for i in "${iterations[@]}"; do
            # Perhaps a little cursed we keep the same prefix number for each iteration but
            #   honestly it's fine over three subfolders per input byte-sized I think.
            printf -v scenario_name '%02d__%d_bytes_%d' "$(( b + 1 - min_exponent ))" "${bytes}" "$i"
            printf '%s\n' "$scenario_name"

            mkdir "${category}__${scenario_name}"
            pushd "${category}__${scenario_name}" 1> /dev/null

            call "${category}_circuit"

            popd 1> /dev/null || exit 1
        done

        unset -v bytes
        unset -v scenario_name
    done
done
