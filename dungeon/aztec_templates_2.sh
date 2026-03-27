#!/usr/bin/env bash

# - $1 = per input byte size
# - $2 = number of iterations (as array of inputs to circuit)
# - $3 = tempalted scenario (circuit) name

nargo_base ()
{
    tee Nargo.toml <<EOF > /dev/null
[package]
name = "${scenario_type}__${scenario_name}"
type = "bin"
entry = "main.nr"

EOF
}

keccak256_circuit ()
{
    # echo "received: ${*:1}"
    # pwd

    # declare -r __bytes="$1"
    # declare -r __iterations="$2"
    # declare -r __scenario_name="$3"

    # **************************************************************************
    # Nargo.toml: does NOT DEPEND on iterations required.
    nargo_base

    tee -a Nargo.toml <<EOF > /dev/null
[dependencies]
keccak256 = { tag = "v0.1.3", git = "https://github.com/noir-lang/keccak256" }
EOF

    # **************************************************************************
    # Circuit: DEPENDS on iterations required.
    tee main.nr <<EOF > /dev/null
use keccak256::keccak256;

EOF

    if [[ "${i}" -eq 1 ]]; then
    tee -a main.nr <<EOF > /dev/null
// Single iteration.
fn main(input_bytes: [u8; $bytes], length: u32) -> pub [u8; 32] {
    keccak256(input_bytes, length)
}
EOF
    else
    # Multiple iterations, circuit needs to output everything to prevent compiler optimising away.
    tee -a main.nr <<EOF > /dev/null
// ${i} iterations.
fn main(input_bytes: [[u8; $bytes]; ${i}], length: u32) -> pub [[u8; 32]; ${i}] {
    let mut output: [[u8; 32]; ${i}] = [[0; 32]; ${i}];
    for i in 0..${i} {
        output[i] = keccak256(input_bytes[i], length);
    }

    output
}
EOF
    fi

    # **************************************************************************
    # Prover.toml: DEPENDS on iterations required.
    tee Prover.toml <<EOF > /dev/null
input_bytes = $(<../../master_bytes/"${scenario_name}.txt")
length = $bytes
EOF
}
