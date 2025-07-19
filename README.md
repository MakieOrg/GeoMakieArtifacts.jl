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

# Get attribution information for an artifact
attribution = get_attribution("natural_earth")
println(attribution)
```

### Available Artifacts

The package includes attribution information for:
- `natural_earth` - Free vector and raster map data
- `gadm_world` - Global administrative boundaries
- `nasa_blue_marble` - High resolution satellite imagery
- `etopo1` - Global relief model
- `world_bank_cities` - Global cities database
- `osm_coastlines` - OpenStreetMap coastline data

## For Package Developers

### Adding New Artifacts

1. Add attribution information to `gen/attributions.toml`:
```toml
[my_dataset]
source = "Data Source Name"
license = "License Type"
author = "Author/Organization"
description = "Brief description"
url = "https://source-url.com"
```

2. Download your data into `gen/data/my_dataset/`

3. Run the preparation script:
```julia
julia gen/prepare_artifacts.jl
```

4. Create a GitHub release:
```julia
julia gen/create_release.jl v1.0.0
```

### Workflow

1. **Data Preparation**: Download data files into subdirectories of `gen/data/`
2. **Attribution**: Ensure each dataset has an entry in `gen/attributions.toml`
3. **Artifact Creation**: Run `prepare_artifacts.jl` to create tarballs with attribution
4. **Release**: Use `create_release.jl` to upload artifacts to GitHub releases
5. **Distribution**: The package automatically downloads artifacts on demand

## License and Attribution

Each artifact has its own license. Always check the attribution information:

```julia
# Always review the license before using data
attribution = get_attribution("gadm_world")
println(attribution)
```

## Contributing

Contributions are welcome! Please ensure any new datasets include complete attribution information.
