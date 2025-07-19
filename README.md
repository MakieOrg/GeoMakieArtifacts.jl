# GeoMakieArtifacts.jl

[![Build Status](https://github.com/MakieOrg/GeoMakieArtifacts.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/MakieOrg/GeoMakieArtifacts.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia package for managing geographic data artifacts with proper attribution for use with GeoMakie.jl.

## Overview

GeoMakieArtifacts.jl provides a convenient way to distribute and access geographic datasets while ensuring proper attribution. Each artifact includes its data files along with complete attribution information including source, license, and authorship details.

## Installation

```julia
using Pkg
Pkg.add("GeoMakieArtifacts")
```

## Usage

### Accessing Artifacts

```julia
using GeoMakieArtifacts

# Get the path to an artifact
path = geomakie_artifact("natural_earth")

# List all available artifacts
artifacts = list_artifacts()
```

## Developer docs

Add new artifact definitions (download + unpack) to `gen/artifacts.jl`.  
This must save the data to a folder in `gen/data/`, which will get tarballed, 
gzipped, and turned into an artifact.  If a `.lazy` file is present in that 
folder, it will be ignored, but the artifact will be marked as lazy.

To prepare a release:
1. change the version number in Project.toml and push all outstanding changes
2. run `julia gen/prepare_artifacts.jl`
3. run `julia gen/create_release.jl`
4. invoke registrator