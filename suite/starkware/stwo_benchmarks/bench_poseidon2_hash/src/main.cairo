use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

#[executable]
fn main(input: [felt252; 2]) -> felt252 {
    PoseidonTrait::new().update_with(input).finalize()
}
