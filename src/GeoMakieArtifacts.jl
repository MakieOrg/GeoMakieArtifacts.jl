module GeoMakieArtifacts

using Artifacts, LazyArtifacts

function geomakie_artifact(name::String)
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
    artifact_path = geomakie_artifact(artifact_name)
    attribution_file = joinpath(artifact_path, "attributions.md")
    
    if !isfile(attribution_file)
        error("Attribution file not found for artifact: $artifact_name")
    end
    
    return read(attribution_file, String)
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

export geomakie_artifact, get_attribution, list_artifacts

end
