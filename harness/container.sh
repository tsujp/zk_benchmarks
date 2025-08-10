#!/usr/bin/env bash

make_container ()
{
    declare -ri fedora_version=42

    podman build \
           --layers \
           --cache-ttl '86400s' \
           --build-arg VERSION="$fedora_version" \
           --tag localhost/benchy/fedora-baseline:"$fedora_version" \
           --file 'suite/base.Containerfile'

    declare -r context="suite/${1}/build__${2}"
    
    podman build \
           --layers \
           --cache-ttl '86400s' \
           --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN \
           --build-arg SUITE_NAME="$1" \
           --build-arg VARIANT_NAME="$2" \
           --tag localhost/benchy/"${1}-${2}" \
           --file "${2}.Containerfile" \
           "$context"

    rm -rf "$context"
}


run_container ()
{
    # TODO: Run this for 1 core, 2 cores, 4 cores. Currently only 4 cores.

    podman run -it -d --replace \
           --init \
           --userns keep-id \
	       --security-opt label=disable \
	       --hostname "benchy-${1}-${2}" \
	       --name "benchy-${1}-${2}" \
           --network=host \
           --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN \
           --cpuset-cpus=4,5,6,7 \
           --cpus=0 \
	       localhost/benchy/"${1}-${2}"
}
