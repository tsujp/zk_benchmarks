#!/usr/bin/env bash

source "$HOME"/.benchy_imaged.sh

# SUITE STWO

declare -ar scenarios=(
    # 'bench_eddsa_poseidon'
    'bench_poseidon2_hash'
    # 'bench_poseidon2_hash_100'
    # 'bench_poseidon2_hash_30'
    # 'bench_poseidon_hash'
    # 'bench_poseidon_hash_100'
    # 'bench_poseidon_hash_30'
    # 'semaphore_depth_10'
    # 'sha512_100_bytes'
)

# ******************************************************************************
# **************************** BENCHMARK LIFECYCLE

# Prepare to warmup and then benchmark a specific fixture.
prepare ()
{
    # TODO: Do we need --profile=release, or --release?
    scarb --offline build --workspace --no-warnings
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

measure_witness ()
{
    # Execute will populate target/execute/SCENARIO_NAME with folders executeN for each execution.
    # TODO: Pass --no-warnings, or --quiet?
    declare -r m_cmd='scarb --offline execute --arguments-file arguments.txt'

    if [[ "$#" -gt 1 ]]; then
        # XXX: Here and elsewhere poop panics trying to get width for detatched terminal via Podman, disabling colour stops the fancy progress bar fixes this.
        poop --color never --duration "$2" "${m_cmd}"
    else
        $m_cmd
    fi
}

measure_witness_size ()
{
    # TODO: Yet to see any docs on where the witness is and how to get it (very annoying).
    # It looks like it might be some combination of memory.bin and trace.bin but again no docs
    # that I can yet see, and no replies to my questions so..........................
    printf 'STUB\n'
}

measure_circuit_gates ()
{
    # TODO: Yet to see any docs on how to get gates (very annoying).
    printf 'STUB\n'
}

measure_proving ()
{
    # All executions should have been the same so we'll just use execution1. If they for some reason
    # aren't there are MUCH bigger problems.
    declare -r m_cmd="scarb --offline prove --execution-id 1"

    if [[ "$#" -gt 1 ]]; then
        poop --color never --duration "$2" "${m_cmd}"
    else
        $m_cmd
    fi
}

measure_proof_size ()
{
    stat --format '%n %s' target/execute/"$s"/execution1/proof/proof.json
}

measure_verifying ()
{
    declare -r m_cmd='scarb --offline verify --execution-id 1'

    if [[ "$#" -gt 1 ]]; then
        poop --color never --duration "$2" "${m_cmd}"
    else
        $m_cmd
    fi
}

benchmark ()
{
    printf '\033[35m------------ STARKWARE BENCHMARKS ------------\033[0m\n'

    for s in "${scenarios[@]}"; do
        alert 'Benchmarking:' " $s"

        pushd "$(pwd)" 1> /dev/null
        pushd "scenarios/${s}" 1> /dev/null

        call prepare "$s"

        warmup 'measure_witness' "$s"
        call measure_witness "$s" 10000

        # call measure_witness_size "$s"
        # call measure_circuit_gates "$s"

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

# Install dependencies specific to Stwo

# TODO: Specific versions of these for greater tracking and control. Starkware's ecosystem is a bit.. scuffed it feels like (with regards to tooling and versions etc).

# XXX: Scarb bundles Stwo.
install_scarb ()
{
    # TODO: Scarb uses a different target-triple convention, so let's save retrying for the Ruby version and just assume GNU/Linux x86_64 ___FOR NOW___
    curl --progress-bar -LO 'https://github.com/software-mansion/scarb/releases/download/v2.12.0/scarb-v2.12.0-x86_64-unknown-linux-gnu.tar.gz'

    tar xzvf 'scarb-v2.12.0-x86_64-unknown-linux-gnu.tar.gz' \
        scarb-v2.12.0-x86_64-unknown-linux-gnu/bin/ \
        -C /home/"$USERNAME"/bin \
        --strip-components=1

    rm -f scarb-v2.12.0-x86_64-unknown-linux-gnu.tar.gz
}

bootstrap ()
{
    printf $'\033[35m'"------------ BOOTSTRAPPING $BENCHY_TARGET ------------"$'\033[0m\n'

    install_scarb
}


"$1"
