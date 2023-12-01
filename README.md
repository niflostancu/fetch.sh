# Single-file release fetching script

This repository contains an embeddable utility script that could be used for
fetching versions / releases / files / hash strings from various hosting
services (GitHub, Docker Hub -- for now).

## Features

- automates fetching files / metadata from remote repositories;
- queryable metadata: version / tag + digest / hash, prefix/suffix matching, longest prefix ordering;
- download specific raw assets from a git repository (at requested / latest verison);
- supports GitHub files & releases, Docker Hub images, more to come (GitLab?)!;
- well documented & tested (hopefully)!

## Requirements

- [`bash`](https://www.gnu.org/software/bash/), since the script is written in it!
- [`curl`](https://curl.se/) for fetching URLs;
- [`jq`](https://jqlang.github.io/jq) for JSON parsing.

You should install them using your distribution's package manager.

## Installation

Download the script and put it in PATH or somewhere in your project's scripts directory (where you
intend to make use of it):

```sh
wget -O fetch.sh "https://raw.githubusercontent.com/niflostancu/release-fetch-script/master/fetch.sh"
chmod +x fetch.sh
```

## Usage

Excerpt from `fetch.sh --help`

```txt
Usage: `fetch.sh [OPTIONS] URL`
Fetches repository tag/asset/image version data and/or files.

The URL specifies the path to the repository & resource / asset to fetch.
You can specify custom service-specific filters inside the URI fragment (e.g., '#prefix=v2.')
You may also use a special '{VERSION}' placeholder in some of its components.
A service may have limited supported functions (e.g., no download / hash).

Options:
         --debug|-d: enable debug messages
         --version: prints the local fetch script's version string
         --latest: always fetch the latest version (overrides cache)
         --set-version=VERSION: fetch a specific version / commit string
         --set-*[=VALUE]: set configuration variables (alt. to fragment vars)
         --cache-file=FILE: file to cache the retrieved metadata vars
         --header|-H EXTRA_HEADER: specify extra headers to curl (for version fetching & download)
         --print-version: prints the version number (the default, if no other --print* present)
         --print-hash: prints the commit / asset's digest (multiple --print's are done in given order)
         --print-url: prints the download URL
         --download=DEST_NAME: uses curl to automatically download the asset to DEST_NAME
         --self-update: self updates this script (fetches the latest version and replaces self with it)
```

### Examples

Fetch latest [`fzf`](https://github.com/junegunn/fzf) release for `linux_amd64`:
```sh
fetch.sh --latest --download="fzf-{VERSION}.tar.gz" \
    "https://github.com/junegunn/fzf/releases/download/{VERSION}/fzf-{VERSION}-linux_amd64.tar.gz"
```

Retrieve the version & URL of Kubernetes' [`nginx-controller`] deployment script
(on multiple lines, in the order given by the arguments):
```sh
# this project has prefixed releases as version string, e.g.: "controller-v1.8.2"
URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/{VERSION}/deploy/static/provider/cloud/deploy.yaml"
fetch.sh --print-version --print-url --set-prefix="controller-" "$URL"
# or:
fetch.sh --print-version --print-url "$URL#prefix=controller-"
```

Of course, you can add `--download=<DEST_NAME>` at any time you also wish to
download the file! But you can also cache those in a separate file (this is
useful when using `fetch.sh` for Makefile dependency management):
```sh
fetch.sh --cache-file=.cached.ver --print-hash "$URL#..."
cat .cached.ver
# e.g.: "controller-v1.8.2" + commit hash on second line
```

For **DockerHub images**, there is no download capability (you use the container
deployment tool). But it's always useful to check whether a given base image has
a new version:

```sh
fetch.sh --print-version --print-hash "https://hub.docker.com/_/alpine"
```

You can also use `suffix` and `prefix` and `longest` (to prefer the longest
version string) specifiers! + _Note_: when the image has many
tags, it is useful to also set a larger `page_size` parameter (max. number of
entries returned by the request), otherwise the returned version may not be the
last (the API doesn't guarantee results ordering): 

```sh
fetch.sh --print-version "https://hub.docker.com/_/nextcloud#prefix=27.;suffix=-fpm-alpine;longest;page_size=200"
```

