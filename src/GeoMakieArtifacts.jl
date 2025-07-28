module GeoMakieArtifacts

using Artifacts, LazyArtifacts

"""
    geomakie_artifact_dir(name::String) -> String

Get the directory of a specific artifact.  
This will be a directory that contains the artifact as data 
(but you have to know what the file structure is after that),
and optionally an ATTRIBUTION.md file that contains the attribution information for the artifact.

# Example
```julia
artifact_dir = geomakie_artifact_dir("ne_110m_coastline")
println(artifact_dir)
```

"""
function geomakie_artifact_dir(name::String)
    return @artifact_str name
end

"""
    get_attribution(artifact_name::String) -> String

Get the attribution information for a specific artifact.
Returns the contents of the attributions.md file included with the artifact.

# Example
```julia
attribution = get_attribution("natural_earth")
println(attribution)
```
"""
function get_attribution(artifact_name::String)
    artifact_path = geomakie_artifact_dir(artifact_name)
    attribution_file = joinpath(artifact_path, "ATTRIBUTION.md")
    
    return if !isfile(attribution_file)
        "Attribution file not found for artifact: $artifact_name"
    else
        last(eachline(attribution_file))
    end
end

function get_attribution_info(artifact_name::String)
    artifact_path = geomakie_artifact_dir(artifact_name)
    attribution_file = joinpath(artifact_path, "ATTRIBUTION.md")
    if !isfile(attribution_file)
        return "Attribution file not found for artifact: $artifact_name"
    end
    attribution = read(attribution_file, String)
    return attribution
end

"""
    list_artifacts() -> Vector{String}

List all available artifacts in this package.
"""
function list_artifacts()
    artifacts_toml = joinpath(dirname(@__DIR__), "Artifacts.toml")
    if !isfile(artifacts_toml)
        return String[]
    end
    
    # Simple parsing - just get top-level keys
    artifacts = String[]
    for line in readlines(artifacts_toml)
        m = match(r"^\[([^\]]+)\]", line)
        if m !== nothing && !occursin(".", m[1])
            push!(artifacts, m[1])
        end
    end
    
    return sort(unique(artifacts))
end

export geomakie_artifact_dir, get_attribution_info, get_attribution, list_artifacts

end
