#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

BATS_DOCKER_URL="https://hub.docker.com/r/bats/bats"

RUN=(run --separate-stderr)

setup() {
    [[ -n "$BATS_DELAY" ]] && sleep "$BATS_DELAY" || true
}

fetch() {
    ./fetch.sh "$@"
}

@test "fetch latest bats docker image version tag" {
    "${RUN[@]}" fetch "$BATS_DOCKER_URL#prefix=v"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ ^v[1-9]+\. ]]
}

@test "fetch specific docker tag with prefix/suffix" {
    "${RUN[@]}" fetch "$BATS_DOCKER_URL#prefix=v1.;suffix=no-faccessat2"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ ^v1\..+no-faccessat2 ]]
}

@test "fetch docker image digest" {
    "${RUN[@]}" fetch --get-hash "$BATS_DOCKER_URL"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ ^[0-9a-z]{20,}$ ]]
}

@test "fetch docker image digest for old version" {
    "${RUN[@]}" fetch --version=1.8.2 --get-hash "$BATS_DOCKER_URL"
    [ "$status" -eq 0 ]
    [[ "${output}" == "e83f0ac8b0f3"* ]]
}

