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


# TODO: Use underscores in image and container names instead of hyphens jam_foo_lorem instead of jam-foo-lorem.
# TODO: Rename (as appropriate) as this function should create (if not already exists), and start the container both.
run_container ()
{
    local container_user="$(podman image inspect localhost/jam/"$JAM_NAME" --format "{{.User}}")"
    # TODO: Error checking on above output exit status and value (not empty string). Also, what are valid linux usernames? Just realised I don't know concretely. Probably a-Z0-9 with underscore and hyphen only? i.e. regex validate as appropriate too.

    podman run -it -d --replace \
           --init \
           --userns keep-id \
	       --security-opt label=disable \
	       --hostname "jam-$JAM_NAME" \
	       --name "jam-$JAM_NAME" \
           --network=host \
           --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN \
           --cpuset-cpus=4 \
           --cpus=0 \
	       localhost/jam/"$JAM_NAME"
}
