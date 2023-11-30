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

