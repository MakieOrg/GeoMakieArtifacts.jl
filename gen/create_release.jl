#!/usr/bin/env julia

# Script to create GitHub release and upload artifact tarballs
# Usage: julia create_release.jl [version]
# Example: julia create_release.jl v1.0.0
#
# Prerequisites:
# - GitHub CLI (gh) must be installed and authenticated
# - Artifact tarballs must exist in gen/ directory
# - Artifacts.toml must be updated with final URLs

using Pkg
Pkg.activate(dirname(@__DIR__))

using TOML

const SCRIPT_DIR = @__DIR__
const PROJECT_DIR = dirname(SCRIPT_DIR)
const ARTIFACTS_TOML = joinpath(PROJECT_DIR, "Artifacts.toml")
const PROJECT_TOML = joinpath(PROJECT_DIR, "Project.toml")

# Get version from Project.toml
function get_version()
    project = TOML.parsefile(PROJECT_TOML)
    version = project["version"]
    return startswith(version, "v") ? version : "v" * version
end

# Generate release notes
function generate_release_notes(tarballs::Vector{String}, version::String)
    notes = """
    # GeoMakieArtifacts.jl $version
    
    This release contains the following geographic data artifacts:
    
    """
    
    for tarball in sort(tarballs)
        artifact_name = replace(basename(tarball), ".tar.gz" => "")
        notes *= "- `$(artifact_name)`\n"
    end
    
    notes *= """
    
    ## Installation
    
    ```julia
    using Pkg
    Pkg.add("GeoMakieArtifacts")
    ```
    
    ## Usage
    
    ```julia
    using GeoMakieArtifacts
    
    # Get path to an artifact
    path = geomakie_artifact("artifact_name")
    
    # Get attribution information
    attribution = GeoMakieArtifacts.get_attribution("artifact_name")
    ```
    
    ## Attribution
    
    Each artifact includes an `attributions.md` file with complete license and source information.
    Please respect the individual licenses of each dataset.
    """
    
    return notes
end

# Find tarball files
function find_tarballs()
    tarballs = String[]
    for file in readdir(SCRIPT_DIR)
        if endswith(file, ".tar.gz")
            push!(tarballs, joinpath(SCRIPT_DIR, file))
        end
    end
    return tarballs
end


# Get repository info using gh CLI
function get_repo_info()
    try
        repo = strip(read(`gh repo view --json nameWithOwner -q .nameWithOwner`, String))
        return repo
    catch
        println("⚠️  Could not determine repository. Make sure 'gh' is installed and authenticated.")
        print("Enter repository (owner/name): ")
        return readline()
    end
end

# Main function
function create_release()
    version = get_version()
    println("🚀 Creating release: $version")
    
    # Find tarballs
    tarballs = find_tarballs()
    if isempty(tarballs)
        println("❌ No tarball files found in $SCRIPT_DIR")
        println("   Run prepare_artifacts.jl first to create tarballs")
        return
    end
    
    println("📦 Found $(length(tarballs)) tarballs:")
    for tb in tarballs
        println("   - $(basename(tb))")
    end
    
    # Get repository info
    repo = get_repo_info()
    println("📍 Repository: $repo")
    
    # Commit any changes
    println("📝 Committing changes...")
    run(`git add -A`)
    commit_msg = "Prepare release $version"
    try
        run(`git commit -m $commit_msg`)
    catch
        println("   No changes to commit")
    end
    
    # Create and push tag
    println("🏷️  Creating git tag: $version")
    try
        run(`git tag $version`)
    catch
        println("⚠️  Tag $version already exists. Delete it first with:")
        println("   git tag -d $version")
        println("   git push origin --delete $version")
        return
    end
    
    # Push commit and tag
    println("📤 Pushing to remote...")
    run(`git push origin HEAD`)
    run(`git push origin $version`)
    
    # Generate release notes
    notes = generate_release_notes(tarballs, version)
    notes_file = joinpath(tempdir(), "release_notes_$(version).md")
    write(notes_file, notes)
    
    # Check if release already exists
    println("📝 Creating GitHub release...")
    try
        existing = read(`gh release view $version --repo $repo`, String)
        println("⚠️  Release $version already exists. Delete it first with:")
        println("   gh release delete $version --repo $repo --yes")
        return
    catch
        # Release doesn't exist, proceed
    end
    
    # Create the release from the tag
    cmd = `gh release create $version --repo $repo --title "GeoMakieArtifacts.jl $version" --notes-file $notes_file`
    run(cmd)
    
    # Upload tarballs
    println("📤 Uploading artifact tarballs...")
    for tarball in tarballs
        println("   Uploading: $(basename(tarball))")
        run(`gh release upload $version $tarball --repo $repo`)
    end
    
    println("\n✅ Release created successfully!")
    println("🌐 View at: https://github.com/$repo/releases/tag/$version")
    
    println("\n📋 Release complete! The artifacts are now available for download.")
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    create_release()
end