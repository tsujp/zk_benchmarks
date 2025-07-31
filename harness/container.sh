#!/usr/bin/env bash

make_container ()
{
    podman build \
           --layers \
           --cache-ttl '86400s' \
           --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN \
           --build-arg PROJECT_NAME="benchy-${1}" \
           --build-arg HARNESS_LOC="harness/fixture/${1}" \
           -t localhost/benchy/"$1" \
           -f "harness/fixture/${1}/Containerfile" \
           "$BENCHY_LOC"
           # "harness/fixture/${1}" 
}


run_container ()
{
    podman run -it -d --replace \
           --init \
           --userns keep-id \
	       --security-opt label=disable \
	       --hostname "benchy-${1}" \
	       --name "benchy-${1}" \
           --network=host \
           --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN \
           --cpuset-cpus=4 \
           --cpus=0 \
	       localhost/benchy/"$1"
}
