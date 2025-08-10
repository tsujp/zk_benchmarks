#!/usr/bin/env bash

declare -Ar __func_puts=(
    ['benchy_image']='Imaging benchy'
    ['benchy_run']='Running benchmarks'
    ['benchy_make']='Creating containers for all suites'
    ['make_container']='Building container'
    ['prepare']='Preparing circuit'
    ['warmup']='Warming up'
)


die ()
{
    printf '\033[1;31m%s\033[0m\n (exiting)' "$1"
    exit 1
}

error ()
{
    printf '\033[0;31m%s\033[0m%s\n' "$1" "${*:2}"
}

alert ()
{
    printf '\033[1;33m**\033[22m \033[0;33m%s\033[0m%s\n' "$1" "${*:2}"
}

puts_headline ()
{
    printf '==> \033[1;35m%s\033[0m%s\n' "$1" "${*:2}"
}

puts ()
{
    printf '%s\n' "${*}"
}


# Execute a shell function, wrapping it in section pretty-printing messages.
#   - $1 = shell function.
#   - $2 onwards passed down as-is.
call ()
{
    declare f_ptr="$1"

    # Check that f_ptr refers to a valid function name.
    if [[ ! $(declare -F "$f_ptr") ]]; then
        die "Function '$f_ptr' not found."
    fi

    # Avoiding use of `time` to reduce process hierarchy. Pedantic.
    declare start_time="$EPOCHREALTIME"

    puts_headline "${__func_puts[$f_ptr]:-$f_ptr}" '...'

    # Execute f_ptr
    # TODO: Pass further args.
    "$f_ptr" "${@:2}"

    declare end_time="$EPOCHREALTIME"

    printf -v duration '(\033[1;33m%.6f\033[0m s)' "$(bc -l <<< "$end_time - $start_time")"

    puts_headline 'done' " $duration" $'\033[1;30m'"${__func_puts[$f_ptr]:-$f_ptr}"$'\033[0m'
}

kurl ()
{
    # puts "Downloading: $1"
    curl -fsSL --progress-bar "$1"
}

reload_shell ()
{
    hash -r && _SHOW_MESSAGES=1 exec -a -bash bash
}
