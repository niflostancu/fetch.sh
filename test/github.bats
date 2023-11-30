#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

BATS_URL="https://github.com/bats-core/bats-core"
BATS_RAW_URL="https://raw.githubusercontent.com/bats-core/bats-core"

RUN=(run --separate-stderr)

setup() {
    [[ -n "$BATS_DELAY" ]] && sleep "$BATS_DELAY" || true
}

fetch() {
    ./fetch.sh "$@"
}

@test "fetch help" {
    "${RUN[@]}" fetch # https://github.com/bats-core/bats-core
    [ "$status" -eq 1 ]
    [[ "${output}" == *"Usage:"* ]]
}

@test "fetch latest bats version (no asset)" {
    "${RUN[@]}" fetch "$BATS_URL"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ ^v[1-9]+\. ]]
}

@test "fetch latest bats version (with asset)" {
    "${RUN[@]}" fetch "$BATS_URL/archive/refs/tags/{VERSION}.tar.gz"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ ^v[1-9]+\. ]]
}

@test "fetch specific version prefix" {
    "${RUN[@]}" fetch "$BATS_URL/archive/refs/tags/{VERSION}.tar.gz#prefix=v1.0"
    [ "$status" -eq 0 ]
    [[ "${output}" == "v1.0.2" ]]
}

@test "fetch specific version prefix (using --set-prefix)" {
    "${RUN[@]}" fetch --set-prefix=v1.0 "$BATS_URL/archive/refs/tags/{VERSION}.tar.gz"
    [ "$status" -eq 0 ]
    [[ "${output}" == "v1.0.2" ]]
}

@test "fetch latest commit digest" {
    "${RUN[@]}" fetch --latest --get-hash "$BATS_URL"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ ^[0-9a-z]{20,}$ ]]
}

@test "fetch specific commit digest" {
    "${RUN[@]}" fetch --set-version=v1.8.0 --get-hash "$BATS_URL"
    [ "$status" -eq 0 ]
    [[ "${output}" == "dbe636ed7ea9"* ]]
}

@test "cache version to file" {
    _CACHE=/tmp/test_ver_cache
    rm -f "$_CACHE"
    "${RUN[@]}" fetch --latest --cache-file="$_CACHE" "$BATS_URL"
    [ "$status" -eq 0 ]
    [[ -f "$_CACHE" ]]
    [[ "$(head -1 "$_CACHE")" =~ ^v[1-9]+\. ]]
}

@test "get download URL for cached version" {
    _CACHE=/tmp/test_ver_cache
    rm -f "$_CACHE"
    "${RUN[@]}" fetch --latest --cache-file="$_CACHE" "$BATS_URL/archive/refs/tags/{VERSION}.tar.gz"
    "${RUN[@]}" fetch --cache-file="$_CACHE" --print-url "$BATS_URL/archive/refs/tags/{VERSION}.tar.gz"
    [ "$status" -eq 0 ]
    local VERSION=$(head -1 "$_CACHE")
    [[ "${output}" =~ "$BATS_URL/archive/refs/tags/$VERSION.tar.gz" ]]
}

@test "download specific file (from bats repo)" {
    _DEST=/tmp/test_dld_script_bats
    rm -f "$_DEST"
    "${RUN[@]}" fetch --download="$_DEST" "$BATS_RAW_URL/{VERSION}/libexec/bats-core/bats"
    [ "$status" -eq 0 ]
    [[ -f "$_DEST" ]]
    [[ "$(head -1 "$_DEST")" =~ ^#!.+bash ]]
}

