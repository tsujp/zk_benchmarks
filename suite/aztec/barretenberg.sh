#!/usr/bin/env bash

source "$HOME"/.benchy_imaged.sh

# SUITE BARRETENBERG

# TODO: In future multiple scenario sets
declare -Ar scenario_src=(
    ['repo']='https://github.com/noir-lang/noir.git'
    ['context']='test_programs/benchmarks'
)

declare -ar scenarios=(
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

# ******************************************************************************
# **************************** BENCHMARK LIFECYCLE

# XXX: Every suite definition must have functions:
#   - prepare
#   - warmup
#   - measure_witness
#   - measure_proving
#   - measure_verifying

# Prepare to warmup and then benchmark a specific fixture.
prepare ()
{
    # Compile circuit to bytecode so `nargo execute` does not include that time. We don't care about benchmarking compilation since it only consists of the lowering to ACVM bytecode IIRC. Nothing to do with witness generation happens here.
    nargo compile --force --workspace --silence-warnings
}

warmup ()
{
    puts 'Warming up benchmark fixture...'

    for ((i = 0 ; i < max ; i++ )); do
        echo "$i"
    done

    puts '... done'
}

measure_witness ()
{
    echo 'hi there'
}

measure_proving ()
{
    echo 'TODO: Proving'
}

measure_verifying ()
{
    echo 'TODO: Verifying'
}

benchmark ()
{
    printf '\033[35m------------ AZTEC BENCHMARKS ------------\033[0m\n'
    call prepare
}

# printf '\033[35m------------ AZTEC BENCHMARKS ------------\033[0m\n'

# benchmark



# ******************************************************************************
# **************************** BOOTSTRAP (if any)

# Install dependencies specific to Barretenberg.

# XXX: Currently this is only to whatever noirup and bbup gather, regression testing (prior major versions) and the like will be added when YSH rewrite is made.

# TODO: Ditto install_barretenberg's notice.
install_noir ()
{
    set +o nounset

    kurl 'https://raw.githubusercontent.com/noir-lang/noirup/main/install' \
        | bash

    # reload_shell
    source /home/"$USERNAME"/.bashrc

    noirup
}

# TODO: This is an Aztec problem mostly, but curling a shell script into Bash is.. not good. Deconstruct their desired installation strategy and keep it in-sync later.
install_barretenberg ()
{
    kurl 'https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/next/barretenberg/bbup/install' \
        | bash

    # reload_shell
    source /home/"$USERNAME"/.bashrc

    bbup
}

install_scenarios ()
{
    git clone \
        --no-checkout \
        --depth 1 \
        --filter=blob:none \
        "${scenario_src['repo']}" \
        scenarios

    cd scenarios
    git sparse-checkout set "${scenario_src['context']}"
    git checkout
}

bootstrap ()
{
    printf $'\033[35m'"------------ BOOTSTRAPPING $BENCHY_TARGET ------------"$'\033[0m\n'

    install_scenarios
    install_noir
    install_barretenberg
}


"$1"
