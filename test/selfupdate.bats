#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# export DEBUG=2
FETCH_URL="https://hub.docker.com/r/bats/bats"

RUN=(run --separate-stderr)

setup() {
    [[ -n "$BATS_DELAY" ]] && sleep "$BATS_DELAY" || true
}

fetch() {
    ./fetch.sh "$@"
}

@test "print installed version" {
    "${RUN[@]}" -0 fetch --version
    [[ "${output}" =~ ^v[0-9]+ ]]
}

@test "self update to master version" {
    # since src dir is readonly, work from /tmp
    cp -f fetch.sh /tmp && cd /tmp
    echo "#TEST_DIRTY" >> fetch.sh
    "${RUN[@]}" -0 fetch --self-update --set-version=master
    run ! grep -q '#TEST_DIRTY' fetch.sh  # downloaded file not dirty
    "${RUN[@]}" -1 fetch --help
}

@test "self update to v0.2.x prerelease version" {
    cp -f fetch.sh /tmp && cd /tmp
    echo "#TEST_DIRTY" >> fetch.sh
    "${RUN[@]}" -0 fetch --self-update --set-prerelease=1 --set-prefix=v0.2.
    run ! grep -q '#TEST_DIRTY' fetch.sh  # downloaded file not dirty
    "${RUN[@]}" -1 fetch --help
}

