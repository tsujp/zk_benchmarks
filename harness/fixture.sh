#!/usr/bin/env bash

# XXX: For now only a single container variety considered, again until YSH or Zig rewrite.
declare -ar enabled=(
    'aztec'
)

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
