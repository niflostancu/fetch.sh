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
intend to make use of it).

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
         --latest: fetch the latest version
         --version=VERSION: fetch a specific version
         --version-file=FILE: file to cache the version number for later use
         --header|-H EXTRA_HEADER: specify extra headers to curl (for version fetching & download)
         --get-hash: retrieves the commit / asset's digest instead of version number
         --print-url: prints the download URL
         --download=DEST_NAME: uses curl to automatically download the asset to DEST_NAME
         --self-update: self updates this script (fetches the latest version and replaces self with it)
```

