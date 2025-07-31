#!/usr/bin/env bash

set -euo pipefail
set -o nounset
shopt -s lastpipe

if [[ "0" == "1" ]]; then
    set -o xtrace
fi

declare -Ar __func_puts=([benchy_make]="Creating containers for all fixtures" [make_container]="Building container" [benchy_run]="Running benchmarks" [prepare]="Preparing circuit" )
declare -ar aztec_fixtures=([0]="bench_eddsa_poseidon" [1]="bench_poseidon2_hash" [2]="bench_poseidon2_hash_100" [3]="bench_poseidon2_hash_30" [4]="bench_poseidon_hash" [5]="bench_poseidon_hash_100" [6]="bench_poseidon_hash_30" [7]="semaphore_depth_10" [8]="sha512_100_bytes")
declare -ar enabled=([0]="aztec")
declare -Ar fixtures=([aztec=aztec_fixtures]="" )
alert () 
{ 
    printf '\033[1;33m**\033[22m \033[0;33m%s\033[0m%s\n' "$1" "${*:2}"
}
call () 
{ 
    declare f_ptr="$1";
    if [[ ! -n $(declare -F "$f_ptr") ]]; then
        die "Function '$f_ptr' not found.";
    fi;
    declare start_time="$EPOCHREALTIME";
    puts_headline "${__func_puts[$f_ptr]:-$f_ptr}" '...';
    "$f_ptr" "${@:2}";
    declare end_time="$EPOCHREALTIME";
    printf -v duration '(in: \033[1;33m%.6f\033[0m s)' "$(bc -l <<< "$end_time - $start_time")";
    puts_headline 'done:' " ${__func_puts[$f_ptr]:-$f_ptr}" " $duration"
}
die () 
{ 
    printf '\033[1;31m%s\033[0m\n (exiting)' "$1";
    exit 1
}
error () 
{ 
    printf '\033[0;31m%s\033[0m%s\n' "$1" "${*:2}"
}
kurl () 
{ 
    curl -fsSL "$1"
}
list_enabled () 
{ 
    for i in "${!enabled[@]}";
    do
        puts "    $(( i + 1 ))) ${enabled[$i]}";
    done
}
make_container () 
{ 
    podman build --layers --cache-ttl '86400s' --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN --build-arg PROJECT_NAME="benchy-${1}" --build-arg HARNESS_LOC="harness/fixture/${1}" -t localhost/benchy/"$1" -f "harness/fixture/${1}/Containerfile" "$BENCHY_LOC"
}
puts () 
{ 
    printf '%s\n' "${*}"
}
puts_headline () 
{ 
    printf '==> \033[1;35m%s\033[0m%s\n' "$1" "${*:2}"
}
reload_shell () 
{ 
    hash -r && _SHOW_MESSAGES=1 exec -a -bash bash
}
run_container () 
{ 
    local container_user="$(podman image inspect localhost/jam/"$JAM_NAME" --format "{{.User}}")";
    podman run -it -d --replace --init --userns keep-id --security-opt label=disable --hostname "jam-$JAM_NAME" --name "jam-$JAM_NAME" --network=host --cap-add=SYS_PTRACE,CAP_PERFMON,CAP_SYS_ADMIN --cpuset-cpus=4 --cpus=0 localhost/jam/"$JAM_NAME"
}
