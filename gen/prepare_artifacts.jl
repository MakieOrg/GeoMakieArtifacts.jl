#!/usr/bin/env julia

# Script to prepare artifacts from downloaded data folders
# Usage: julia prepare_artifacts.jl
#
# This script expects data to be downloaded into subdirectories of gen/data/

using Pkg
Pkg.activate(dirname(@__DIR__))

using Pkg.Artifacts: bind_artifact!, create_artifact
using TOML
using Tar
using SHA

const SCRIPT_DIR = @__DIR__
const PROJECT_DIR = dirname(SCRIPT_DIR)
const DATA_DIR = joinpath(SCRIPT_DIR, "data")
const TARBALLS_DIR = joinpath(SCRIPT_DIR, "tarballs")
const ARTIFACTS_TOML = joinpath(PROJECT_DIR, "Artifacts.toml")
const PROJECT_TOML = joinpath(PROJECT_DIR, "Project.toml")
const TEMP_DIR = mktempdir()

# Create tarball with data
function create_artifact_tarball(data_dir::String, artifact_name::String)
    # Create temporary directory for this artifact
    artifact_temp = joinpath(TEMP_DIR, artifact_name)
    mkpath(artifact_temp)
    
    # Copy all data files (except .lazy files)
    for (root, dirs, files) in walkdir(data_dir)
        rel_path = relpath(root, data_dir)
        dest_dir = joinpath(artifact_temp, rel_path)
        mkpath(dest_dir)
        
        for file in files
            # Skip .lazy files
            if endswith(file, ".lazy")
                continue
            end
            
            src = joinpath(root, file)
            dst = joinpath(dest_dir, file)
            cp(src, dst)
        end
    end
    
    # Create tarball in tarballs directory
    mkpath(TARBALLS_DIR)
    tarball_path = joinpath(TARBALLS_DIR, "$(artifact_name).tar.gz")
    Tar.create(artifact_temp, tarball_path)
    
    return tarball_path
end

# Calculate SHA256 of file
function calculate_sha256(filepath::String)
    return bytes2hex(sha256(read(filepath)))
end

# Get version from Project.toml
function get_project_version()
    project = TOML.parsefile(PROJECT_TOML)
    return "v" * project["version"]
end

# Get repository from git remote
function get_repo_info()
    try
        repo = strip(read(`git remote get-url origin`, String))
        # Extract owner/repo from git URL
        m = match(r"github\.com[:/](.+?)(?:\.git)?$", repo)
        if m !== nothing
            return m[1]
        end
    catch
    end
    return "OWNER/REPO"  # Fallback
end

# Check if directory contains a .lazy file
function has_lazy_marker(data_dir::String)
    for (root, dirs, files) in walkdir(data_dir)
        for file in files
            if endswith(file, ".lazy")
                return true
            end
        end
    end
    return false
end

# Custom add_artifact! that uses local directory and tarball
function add_local_artifact!(
    artifacts_toml::String,
    name::String,
    data_dir::String,
    tarball_path::String;
    force::Bool = false
)
    sha256 = calculate_sha256(tarball_path)
    
    # Check for .lazy file to determine if artifact should be lazy
    is_lazy = has_lazy_marker(data_dir)
    
    # Create artifact from the original data directory
    git_tree_sha1 = create_artifact() do artifact_dir
        # Copy all files from data directory to artifact directory (except .lazy files)
        for (root, dirs, files) in walkdir(data_dir)
            rel_path = relpath(root, data_dir)
            dest_dir = joinpath(artifact_dir, rel_path)
            mkpath(dest_dir)
            
            for file in files
                # Skip .lazy files
                if endswith(file, ".lazy")
                    continue
                end
                
                src = joinpath(root, file)
                dst = joinpath(dest_dir, file)
                cp(src, dst)
            end
        end
    end
    
    # Get GitHub URL for this artifact
    version = get_project_version()
    repo = get_repo_info()
    github_url = "https://github.com/$(repo)/releases/download/$(version)/$(basename(tarball_path))"
    
    # Bind artifact with GitHub URL
    bind_artifact!(
        artifacts_toml,
        name,
        git_tree_sha1;
        download_info = [(github_url, sha256)],
        lazy = is_lazy,
        force = force
    )
    
    if is_lazy
        println("   Marked as lazy artifact")
    end
    
    return git_tree_sha1
end

# Main processing function
function process_artifacts()
    if !isdir(DATA_DIR)
        println("Creating data directory: $DATA_DIR")
        mkpath(DATA_DIR)
        println("Please download your data into subdirectories of: $DATA_DIR")
        return
    end
    
    # Find all subdirectories in data/
    data_dirs = filter(isdir, readdir(DATA_DIR, join=true))
    
    if isempty(data_dirs)
        println("No data directories found in: $DATA_DIR")
        return
    end
    
    # Process each data directory
    processed = String[]
    
    for data_path in data_dirs
        artifact_name = basename(data_path)
        
        println("📦 Processing artifact: $artifact_name")
        
        # Create tarball
        tarball_path = create_artifact_tarball(data_path, artifact_name)
        println("   Created tarball: $(basename(tarball_path))")
        
        # Add artifact using local directory and tarball
        artifact_id = add_local_artifact!(
            ARTIFACTS_TOML,
            artifact_name,
            data_path,
            tarball_path,
            force=true
        )
        println("   Artifact ID: $artifact_id")
        
        push!(processed, artifact_name)
    end
    
    println("\n✅ Processed $(length(processed)) artifacts:")
    for name in processed
        println("   - $name")
    end
    
    
    println("\n📄 Updated: $ARTIFACTS_TOML")
    println("\n🎯 Next steps:")
    println("   1. Run: julia gen/create_release.jl")
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    process_artifacts()
end