#!/usr/bin/env bash

# XXX: For now only a single container variety considered, again until YSH or Zig rewrite.
declare -ar enabled=(
    'aztec'
)

# Easier to just use an associative with key/value for free de-duplication.
declare -A suites=()

# We do assume sensible naming here (no escaped / in the path).
for ff in suite/*/*.sh; do
    declare suite_name="$(cut -f2 -d'/' <<< "$ff")"
    
    declare -n suite_ptr="suite_$suite_name"
    suite_ptr+=("$(cut -f3 -d'/' <<< "$ff" | cut -f1 -d'.')")
    
    suites["$suite_name"]="suite_$suite_name"
    
    unset -nv suite_ptr
    unset -v suite_name
done; unset -v ff

# echo "suites: ${!suites[@]}"
# echo "aztec: ${suite_aztec[@]}"
# echo "starkware: ${suite_starkware[@]}"

list_enabled ()
{
    for i in "${!enabled[@]}"; do
        puts "    $(( i + 1 ))) ${enabled[$i]}"
    done
}

# XXX: For now all fixture definitions (benches to run) are defined centrally, until YSH or Zig rewrite.

declare -Ar fixtures=(
    'aztec'='aztec_fixtures'
)

declare -ar aztec_fixtures=(
    'bench_eddsa_poseidon'
    'bench_poseidon2_hash'
    'bench_poseidon2_hash_100'
    'bench_poseidon2_hash_30'
    'bench_poseidon_hash'
    'bench_poseidon_hash_100'
    'bench_poseidon_hash_30'
    'semaphore_depth_10'
    'sha512_100_bytes'
)
