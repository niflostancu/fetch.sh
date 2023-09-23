#!/bin/bash
# Fetch - automatically retrieve the latest version / URL a repository release. 
# https://github.com/niflostancu/release-fetch-script
# v0.3
#
# Prerequisites: bash curl jq
#
# You can use it for the following services:
#  - github.com: released assets (tagged versions);
#  - raw.githubusercontent.com resources (version placeholders in tags);
#  - hub.docker.com: for docker tags (specify jq filtering using # in URL);

set -e
SCRIPT_SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd -P)

# Use for debugging shell calls from make
_debug() {
	[[ -n "$DEBUG" && "$DEBUG" -gt 0 ]] || return 0
	if [[ "$1" =~ ^-[0-9]$ ]]; then [[ $DEBUG -ge ${1#-} ]] || return 0; shift; fi
	echo "DEBUG: fetch.sh: $*" >&2;
}
_fatal() { echo "$@" >&2; exit 2; }

print_help() {
	echo -e "Usage: \`fetch.sh [OPTIONS] URL\`"
	echo -e "Fetches repository tag/asset/image version data and/or files.\n"
	echo -e "The URL specifies the path to the repository & resource / asset to fetch."
	echo -e "You can specify custom service-specific filters inside the URI fragment (e.g., '#prefix=v2.')"
	echo -e "You may also use a special '{VERSION}' placeholder in some of its components."
	echo -e "A service may have limited supported functions (e.g., no download / hash). \n"
	echo -e "Options:"
	echo -e "	 --debug|-d: enable debug messages"
	echo -e "	 --latest: fetch the latest version"
	echo -e "	 --version=VERSION: fetch a specific version"
	echo -e "	 --version-file=FILE: file to cache the version number for later use"
	echo -e "	 --header|-H EXTRA_HEADER: specify extra headers to curl (for version fetching & download)"
	echo -e "	 --get-hash: retrieves the commit / asset's digest instead of version number"
	echo -e "	 --print-url: prints the download URL"
	echo -e "	 --download=DEST_NAME: uses curl to automatically download the asset to DEST_NAME"
	echo -e "	 --self-update: self updates this script (fetches the latest version and replaces self with it)"
	echo && exit 1
}

VERSION=
VERSION_FILE=
CURL_ARGS=()
GET_URL=
GET_HASH=
SELF_UPDATE=
DOWNLOAD_DEST=

# Script setup
shopt -s expand_aliases
_debug "$*"; [[ "$#" -gt 0 ]] || print_help
_debug -2 "DEBUG: $DEBUG"
alias _parse_optval='if [[ "$1" == *"="* ]]; then _OPT_VAL="${1#*=}"; else _OPT_VAL="$2"; shift; fi'

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		--help|-h) print_help; ;;
		--debug|-d) DEBUG=1; ;;
		--latest) VERSION=__latest; ;;
		--version|--version=*) _parse_optval && VERSION=$_OPT_VAL; ;;
		--version-file|--version-file=*) _parse_optval && VERSION_FILE=$_OPT_VAL; ;;
		--header|--header=*|-H) _parse_optval && CURL_ARGS+=(-H "$_OPT_VAL"); ;;
		--get-hash) GET_HASH=1 ;;
		--get-url|--print-url) GET_URL=1 ;;
		--download|--download=*) _parse_optval && DOWNLOAD_DEST=$_OPT_VAL; ;;
		--self-update) SELF_UPDATE=1; break ;;
		-*) _fatal "Invalid argument: $1" ;;
		*) break ;;
	esac
	shift
done

# Supported services domains (used for URL detection)
declare -A SERVICES=(
	["github.com"]="github"
	["raw.githubusercontent.com"]="github_raw"
	["hub.docker.com"]="docker_hub"
)

# Parses an URL fragment and returns each pair on a newline
# (easy to iterate using `read -r line`)
# Accepted format: #key1=value;key2=value...
function parse_url_fragment() {
	local pair= PAIRS=()
	if [[ "$1" =~ ^[^#]*#(.+)$ ]]; then
		IFS=';' read -ra PAIRS <<< "${BASH_REMATCH[1]}"
		for pair in "${PAIRS[@]}"; do
			echo "$pair"
		done
	fi || true
}

# Parses a github URL
# Accepted formats:
# - https://github.com/{org}/{repo}(/releases/download/{VERSION}/...)?
# - https://github.com/{org}/{repo}(/archive/refs/tags/{VERSION}.(zip|tar.gz))?
function service:github:parse_url() {
	if [[ "$1" =~ ^https?://[^/]+/([^/]+/[^/]+)(/.+)? ]]; then
		_REPONAME="${BASH_REMATCH[1]}"
		_URL_REST="${BASH_REMATCH[2]#/}"
	else
		_fatal "Unable to parse URL: $1"
	fi
}
function service:github:get_version() {
	local API_URL="https://api.github.com/repos/$_REPONAME/releases" 
	local HASH= PREFIX= SUFFIX= line=
	if [[ "$1" == "--hash" ]]; then
		HASH=1; shift
	fi
	while IFS= read -r line; do
		case $line in
			prefix=*|pfx=*) PREFIX=${line#*=}; ;;
			suffix=*|sfx=*) SUFFIX=${line#*=}; ;;
		esac
	done < <( parse_url_fragment "$1" )
	local JQ_FILTERS="map(select(.prerelease==false)) | [.[].tag_name]"
	[[ -z "$PREFIX" ]] || \
		JQ_FILTERS+=" | map(select(tostring|startswith(\"$PREFIX\")))"
	[[ -z "$SUFFIX" ]] || \
		JQ_FILTERS+=" | map(select(tostring|endswith(\"$SUFFIX\")))"
	JQ_FILTERS+=" | first"
	_debug -2 "github:get_ver: curl:${CURL_ARGS[@]} $API_URL"
	_debug -2 "github:get_ver: jq: $JQ_FILTERS"
	local TAG=$(curl --fail --show-error --silent "${CURL_ARGS[@]}" "$API_URL" | jq -r "$JQ_FILTERS")
	if [[ -n "$HASH" ]]; then
		# fetch commit SHA from the GH API
		API_URL="https://api.github.com/repos/$_REPONAME/git/ref/tags/$TAG" 
		curl --fail --show-error --silent "${CURL_ARGS[@]}" "$API_URL" | jq -r ".object.sha[0:32]"
	else
		echo -n "$TAG"
	fi
}
function service:github:get_download_url() {
	echo -n "${1/{VERSION\}/$_VERSION}"
}

# Github Raw download URL parser
# Accepted formats:
# - https://raw.githubusercontent.com/{org}/{repository}/{VERSION}/...
function service:github_raw:parse_url() { service:github:parse_url "$@"; }
function service:github_raw:get_version() { service:github:get_version "$@"; }
function service:github_raw:get_download_url() { service:github:get_download_url "$@"; }

# Docker Hub latest tag query (via API v2)
# Accepted formats:
# - https://hub.docker.com/_/{repo}/#filter={VERSION}
# - https://hub.docker.com/(r|repository/docker)/{org}/{repo}/#filter={VERSION}
function service:docker_hub:parse_url() {
	if [[ "$1" =~ ^https?://[^/]+/_/([^/#]+)(/[^#]*)? ]]; then
		# official library
		_NAMESPACE=library
		_REPONAME="${BASH_REMATCH[1]}"
		_URL_REST="${BASH_REMATCH[2]#/}"
	elif [[ "$1" =~ ^https?://[^/]+/(r|repository/docker)/([^/]+)/([^#/]+)(/[^#]*)? ]]; then
		# named project
		_NAMESPACE="${BASH_REMATCH[2]}"
		_REPONAME="${BASH_REMATCH[3]}"
		_URL_REST="${BASH_REMATCH[4]#/}"
	else
		_fatal "Unable to parse URL: $1"
	fi
}
function service:docker_hub:get_version() {
	local API_URL="https://hub.docker.com/v2/namespaces/$_NAMESPACE/repositories/$_REPONAME/tags"
	API_URL+="?page_size=100"
	local HASH= PREFIX= SUFFIX= LONGEST= line=
	if [[ "$1" == "--hash" ]]; then
		HASH=1; shift
	fi
	while IFS= read -r line; do
		case "$line" in
			prefix=*|pfx=*) PREFIX=${line#*=}; ;;
			suffix=*|sfx=*) SUFFIX=${line#*=}; ;;
			longest|long) LONGEST=1; ;;
		esac
	done < <( parse_url_fragment "$1" )
	local JQ_FILTERS=".results | map(select(.name != \"latest\"))"
	[[ -z "$PREFIX" ]] || \
		JQ_FILTERS+=" | map(select(.name|tostring|startswith(\"$PREFIX\")))"
	[[ -z "$SUFFIX" ]] || \
		JQ_FILTERS+=" | map(select(.name|tostring|endswith(\"$SUFFIX\")))"
	# sort by date, desc + name length, asc
	local JQ_SORTBY=".last_updated"
	[[ -z "$LONGEST" ]] || JQ_SORTBY+=", (100-(.name|length))"
	JQ_FILTERS+=" | sort_by($JQ_SORTBY) | reverse | first"
	if [[ -n "$HASH" ]]; then
		# remove hash prefix from the digest value (e.g., 'sha256:...')
		JQ_FILTERS+=" | .digest | sub(\".*:\"; \"\") | .[0:32]"
	else
		JQ_FILTERS+=" | .name"
	fi
	_debug -2 "docker_hub:get_ver: jq: $JQ_FILTERS"
	curl --fail --show-error --silent "${CURL_ARGS[@]}" "$API_URL" | jq -r "$JQ_FILTERS"
}
function service:docker_hub:get_download_url() {
	_fatal "Docker Hub download not supported!"
}

# Self-upgrade function. Called when --self-update is set.
# (for out-of-tree usage of the fetch.sh script)
function fetch_self_update() {
	URL="https://raw.githubusercontent.com/niflostancu/release-fetch-script/{VERSION}/fetch.sh"
	VERSION=${VERSION:-__latest}
}

if ! type jq > /dev/null; then
	_fatal "jq not found (not installed or not in PATH)!"
fi

URL="$1"

if [[ -n "$SELF_UPDATE" ]]; then fetch_self_update; fi

SERVICE=$(echo "$URL" | sed -e 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/')
if [[ ! -v SERVICES["$SERVICE"] ]]; then
	_fatal "Service $SERVICE not supported!" >&2
fi
SERVICE=${SERVICES["$SERVICE"]}

service:$SERVICE:parse_url "$URL"

# check if we need to retrieve the latest version
_debug "Version File: $VERSION_FILE"
_VERSION="$VERSION"
_GET_VERSION_ARGS=()
if [[ -z "$_VERSION" && -n "$VERSION_FILE" && -f "$VERSION_FILE" ]]; then
	_VERSION="$(cat "$VERSION_FILE" | head -1)"
	_debug "version: found in file: $_VERSION"
fi
if [[ -z "$_VERSION" || "$_VERSION" == "__latest" ]]; then
	[[ -z "$GET_HASH" ]] || _GET_VERSION_ARGS=(--hash)
	_VERSION=$(service:$SERVICE:get_version "${_GET_VERSION_ARGS[@]}" "$URL")
	[[ -n "$_VERSION" ]] || _fatal "Could not determine a version for '$_NAME'" >&2
	_debug "version: retrieved from service: $_VERSION"
fi

if [[ "$GET_URL" == "1" ]]; then
	DOWNLOAD_URL="$(service:$SERVICE:get_download_url "$URL")"
	echo "$DOWNLOAD_URL"
else
	echo "$_VERSION"
fi

# Caches the retrieved version / metadata to a file
function cache_version() {
	[[ -n "$VERSION_FILE" ]] || return 0
	# prevent unneeded modification to keep makefile from re-building
	local _CONTENTS=
	[[ ! -f "$VERSION_FILE" ]] || _CONTENTS=$(cat "$VERSION_FILE" | head -1)
	if [[ "$_CONTENTS" != "$1" ]]; then
		mkdir -p "$(dirname "$VERSION_FILE")"
		echo "$1" > "$VERSION_FILE"
		_debug "version: cached '$1' to file!"
	fi
}

_debug "Download dest: $DOWNLOAD_DEST"
if [[ -n "$DOWNLOAD_DEST" ]]; then
	DOWNLOAD_URL="$(service:$SERVICE:get_download_url "$URL")"
	_debug "downloading $DOWNLOAD_URL to '$DOWNLOAD_DEST'"
	mkdir -p "$(dirname "$DOWNLOAD_DEST")"
	_debug -2 "download: curl:${CURL_ARGS[@]} -L -o $DOWNLOAD_DEST $DOWNLOAD_URL"
	curl --fail --show-error --silent "${CURL_ARGS[@]}" -L -o "$DOWNLOAD_DEST" "$DOWNLOAD_URL"
	cache_version "$_VERSION"
	echo "$DOWNLOAD_DEST"
else
	cache_version "$_VERSION"
fi

