#!/usr/bin/env bash

# TEMP: Some scenarios aren't viable (too long, even for benchmarks) so we nuke them
#       here. Later on change the templating to be more configurable so they are
#       never generated in the first place, i.e. something like 128:1,10,100 meaning
#       for 128 byte inputs generate the 1, 10, and 100 iteration versions and that
#       way when we get to say 65536 we can do only 65536:1,10 for some and the full
#       65536:1,10,100 for others.

# keccak256 2048 at 100 iterations is too big.

# These are all below 2048 * 100 = 204,800 and so should be okay.
#   'keccak256__13__4096_bytes_1'
#   'keccak256__13__4096_bytes_10'
#
#   'keccak256__14__8192_bytes_1'
#   'keccak256__14__8192_bytes_10'
#
#   'keccak256__15__16384_bytes_1'
#   'keccak256__15__16384_bytes_10'
#
#   'keccak256__16__32768_bytes_1'
#
#   'keccak256__17__65536_bytes_1'

readonly -a byebye=(
    # ***************************** KECCAK256
    # Uselessly small
    'keccak256__01__1_bytes_1'
    'keccak256__01__1_bytes_10'
    'keccak256__01__1_bytes_100'
    'keccak256__02__2_bytes_1'
    'keccak256__02__2_bytes_10'
    'keccak256__02__2_bytes_100'
    'keccak256__03__4_bytes_1'
    'keccak256__03__4_bytes_10'
    'keccak256__03__4_bytes_100'
    'keccak256__04__8_bytes_1'
    'keccak256__04__8_bytes_10'
    'keccak256__04__8_bytes_100'
    'keccak256__05__16_bytes_1'
    'keccak256__05__16_bytes_10'
    'keccak256__05__16_bytes_100'
    # Too big
    'keccak256__13__4096_bytes_100'
    'keccak256__14__8192_bytes_100'
    'keccak256__15__16384_bytes_100'
    'keccak256__16__32768_bytes_10'
    'keccak256__16__32768_bytes_100'
    'keccak256__17__65536_bytes_10'
    'keccak256__17__65536_bytes_100'

    # ***************************** SHA256
    # TDOO: If any

    # ***************************** POSEIDON2
    # TODO: If any
)

for bb in "${byebye[@]:?}"; do
    printf 'Deleting: %s\n' "${bb:?}"
    rm -rf circuits/"${bb:?}"
done
