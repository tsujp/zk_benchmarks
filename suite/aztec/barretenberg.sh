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
    printf '\033[35mWarming up for\033[0m %s' "$1"

    declare callback_measure="$1"

    # 5 times, arbitrary.
    for ((i = 0 ; i < 5 ; i++ )); do
        "$1" "$2" &> /dev/null
        printf ' %s..' "$i"
    done

    puts $'\033[35m done\033[0m'
}

# TODO: Better warmup mechanism than wrapping if-else.
measure_witness ()
{
    declare -r m_cmd='nargo execute --silence-warnings'
    
    if [[ "$#" -gt 1 ]]; then
        poop --color never --duration "$2" "${m_cmd}"
    else
        $m_cmd
    fi
}

measure_witness_size ()
{
    stat --format '%n %s' target/"$1".gz
}

measure_circuit_gates ()
{
    bb gates --bytecode_path target/"$1".json    
}

measure_proving ()
{
    # Make sure verification key already exists.
    bb write_vk --bytecode_path target/"$1".json
    
    declare -r m_cmd="bb prove --bytecode_path target/${1}.json --witness_path target/${1}"
    
    if [[ "$#" -gt 1 ]]; then
        poop --color never --duration "$2" "${m_cmd}"
    else
        $m_cmd
    fi
}

measure_proof_size ()
{
    stat --format '%n %s' out/proof
}

measure_verifying ()
{
    declare -r m_cmd='bb verify --vk_path out/vk --proof_path out/proof --public_inputs_path out/public_inputs'
    
    if [[ "$#" -gt 1 ]]; then
        poop --color never --duration "$2" "${m_cmd}"
    else
        $m_cmd
    fi
}

benchmark ()
{
    printf '\033[35m------------ AZTEC BENCHMARKS ------------\033[0m\n'

    for s in "${scenarios[@]}"; do
        alert 'Benchmarking:' " $s"

        pushd "$(pwd)" 1> /dev/null
        pushd "scenarios/${scenario_src['context']}/${s}" 1> /dev/null
        
        call prepare "$s"

        warmup 'measure_witness' "$s"
        call measure_witness "$s" 10000

        call measure_witness_size "$s"
        call measure_circuit_gates "$s"
        
        warmup 'measure_proving' "$s"
        call measure_proving "$s" 10000

        call measure_proof_size "$s"

        warmup 'measure_verifying' "$s"
        call measure_verifying "$s" 5000

        popd 1> /dev/null
    done; unset -n s
}


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

    set -o nounset
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
