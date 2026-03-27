#!/usr/bin/env bash

nargo_base ()
{
    tee Nargo.toml <<EOF > /dev/null
[package]
name = "${category:?}__${scenario_name:?}"
type = "bin"
entry = "main.nr"

EOF
}


keccak256_circuit ()
{
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

    if [[ "${i:?}" -eq 1 ]]; then
    tee -a main.nr <<EOF > /dev/null
// Single iteration.
fn main(input_bytes: [u8; ${bytes:?}], length: u32) -> pub [u8; 32] {
    keccak256(input_bytes, length)
}
EOF
    else
    # Multiple iterations, circuit needs to output everything to prevent compiler optimising away.
    tee -a main.nr <<EOF > /dev/null
// ${i} iterations.
fn main(input_bytes: [[u8; ${bytes:?}]; ${i:?}], length: u32) -> pub [[u8; 32]; ${i:?}] {
    let mut output: [[u8; 32]; ${i:?}] = [[0; 32]; ${i:?}];
    for i in 0..${i:?} {
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
length = ${bytes:?}
EOF
}


sha256_circuit ()
{
    # **************************************************************************
    # Nargo.toml: does NOT DEPEND on iterations required.
    nargo_base

    tee -a Nargo.toml <<EOF > /dev/null
[dependencies]
sha256 = { tag = "v0.3.0", git = "https://github.com/noir-lang/sha256" }
EOF

    # **************************************************************************
    # Circuit: DEPENDS on iterations required.
    tee main.nr <<EOF > /dev/null
use sha256::sha256_var;

EOF

    if [[ "${i:?}" -eq 1 ]]; then
    tee -a main.nr <<EOF > /dev/null
// Single iteration.
fn main(input_bytes: [u8; ${bytes:?}], length: u32) -> pub [u8; 32] {
    sha256_var(input_bytes, length)
}
EOF
    else
    # Multiple iterations, circuit needs to output everything to prevent compiler optimising away.
    tee -a main.nr <<EOF > /dev/null
// ${i} iterations.
fn main(input_bytes: [[u8; ${bytes:?}]; ${i:?}], length: u32) -> pub [[u8; 32]; ${i:?}] {
    let mut output: [[u8; 32]; ${i:?}] = [[0; 32]; ${i:?}];
    for i in 0..${i:?} {
        output[i] = sha256_var(input_bytes[i], length);
    }

    output
}
EOF
    fi

    # **************************************************************************
    # Prover.toml: DEPENDS on iterations required.
    tee Prover.toml <<EOF > /dev/null
input_bytes = $(<../../master_bytes/"${scenario_name}.txt")
length = ${bytes:?}
EOF
}


poseidon2_circuit ()
{
    # **************************************************************************
    # Nargo.toml: does NOT DEPEND on iterations required.
    nargo_base

    tee -a Nargo.toml <<EOF > /dev/null
[dependencies]
poseidon = { tag = "v0.2.6", git = "https://github.com/noir-lang/poseidon" }
EOF

    # **************************************************************************
    # Circuit: DEPENDS on iterations required.
    tee main.nr <<EOF > /dev/null
use poseidon::poseidon2;

EOF

    if [[ "${i:?}" -eq 1 ]]; then
    tee -a main.nr <<EOF > /dev/null
// Single iteration.
fn main(input_bytes: [Field; ${bytes:?}], length: u32) -> pub Field {
    poseidon2::Poseidon2::hash(input_bytes, length)
}
EOF
    else
    # Multiple iterations, circuit needs to output everything to prevent compiler optimising away.
    tee -a main.nr <<EOF > /dev/null
// ${i} iterations.
fn main(input_bytes: [[Field; ${bytes:?}]; ${i:?}], length: u32) -> pub [Field; ${i:?}] {
    let mut output: [Field; ${i:?}] = [0; ${i:?}];
    for i in 0..${i:?} {
        output[i] = poseidon2::Poseidon2::hash(input_bytes[i], length);
    }

    output
}
EOF
    fi

    # **************************************************************************
    # Prover.toml: DEPENDS on iterations required.
    tee Prover.toml <<EOF > /dev/null
input_bytes = $(<../../master_bytes/"${scenario_name}.txt")
length = ${bytes:?}
EOF
}
