#!/usr/bin/env bash

# SUITE CAIRO (rename me, the backend isn't cairo)

# TODO: In future multiple scenario sets
declare -Ar scenario_src=(
    ['repo']='https://TODO_CAIRO_REPO'
    ['context']='cairo/foo/bar'
)

declare -ar scenarios=(
    'cairo_one'
    'cairo_two'
)

