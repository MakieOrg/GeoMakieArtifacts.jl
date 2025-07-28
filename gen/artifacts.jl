using Downloads
using HTTP # for retries etc
using ProgressMeter # slow downloads

function datadir(args...)
    return joinpath(@__DIR__, "data", args...)
end

function http_download(url, filepath)
    resp = HTTP.get(url)
    write(filepath, resp.body)
    resp
end

#=
## Natural Earth vector data
Bundles a bunch of useful Natural Earth vector data.
These are (in all resolutions, 110, 50, 10m as available:)
- coastlines
- countries
- populated places
- land

Uses NaturalEarth.jl to download the data.
=#
files = String[]
append!(files, ["ne_$(res)m_coastline" for res in [110, 50, 10]])
append!(files, ["ne_$(res)m_admin_0_countries" for res in [110, 50, 10]])
append!(files, ["ne_$(res)m_populated_places" for res in [110, 50, 10]])
append!(files, ["ne_$(res)m_land" for res in [110, 50, 10]])
using NaturalEarth
NaturalEarth.naturalearth.(files; version = v"5.1.2")
filepaths = joinpath.((NaturalEarth.naturalearth_cache[],), ("v5.1.2",), files .* ".geojson")
filter!(filepaths) do filepath
    f = isfile(filepath) 
    f || @warn("File $filepath does not exist")
    f
end

for filepath in filepaths
    name = splitext(basename(filepath))[1]
    dir = datadir(name)
    mkpath(dir)
    cp(filepath, joinpath(dir, basename(filepath)); force = true)
    write(joinpath(dir, "ATTRIBUTION.md"), """
    Public domain.
    Source: Free vector and raster map data @ naturalearthdata.com.

    Natural Earth
    """)
end

touch(joinpath(datadir("ne_10m_populated_places", ".lazy")))


#=
## NASA Blue Marble
This is NASA blue marble next generation data from MODIS.  Downloads are PNGs.
=#

months = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]

topo_bathy_urls = [
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73580/world.topo.bathy.200401.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73605/world.topo.bathy.200402.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73630/world.topo.bathy.200403.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73655/world.topo.bathy.200404.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73701/world.topo.bathy.200405.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73726/world.topo.bathy.200406.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73751/world.topo.bathy.200407.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73776/world.topo.bathy.200408.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73801/world.topo.bathy.200409.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73826/world.topo.bathy.200410.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73884/world.topo.bathy.200411.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73909/world.topo.bathy.200412.3x5400x2700.png",
]
regular_urls = [
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73938/world.200401.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73967/world.200402.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73992/world.200403.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74017/world.200404.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74042/world.200405.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/76000/76487/world.200406.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74092/world.200407.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74142/world.200409.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74167/world.200410.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74192/world.200411.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74218/world.200412.3x5400x2700.png",
]
topo_urls = [
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74243/world.topo.200401.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74268/world.topo.200402.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74293/world.topo.200403.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74318/world.topo.200404.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74343/world.topo.200405.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74368/world.topo.200406.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74393/world.topo.200407.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74418/world.topo.200408.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74443/world.topo.200409.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74468/world.topo.200410.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74493/world.topo.200411.3x5400x2700.png",
    "https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74518/world.topo.200412.3x5400x2700.png",
]

NASA_ATTRIBUTION = """
Public domain.
Credit: NASA/Visible Earth.
Only the NASA credit is required.

NASA/Visible Earth
"""

@showprogress for (month_idx, month_name) in enumerate(months)
    topo_dir = datadir("blue_marble_topo_$(month_name)")
    topo_bathy_dir = datadir("blue_marble_topo_bathy_$(month_name)")
    regular_dir = datadir("blue_marble_regular_$(month_name)")
    mkpath(topo_dir)
    mkpath(topo_bathy_dir)
    mkpath(regular_dir)

    topo_url = topo_urls[month_idx]
    topo_bathy_url = topo_bathy_urls[month_idx]
    regular_url = regular_urls[month_idx]

    resp = HTTP.get(topo_url)
    write(joinpath(topo_dir, "image" * ".png"), resp.body)
    sleep(0.3)
    resp = HTTP.get(topo_bathy_url)
    write(joinpath(topo_bathy_dir, "image" * ".png"), resp.body)
    sleep(0.3)
    resp = HTTP.get(regular_url)
    write(joinpath(regular_dir, "image" * ".png"), resp.body)

    touch(joinpath(topo_dir, ".lazy"))
    touch(joinpath(topo_bathy_dir, ".lazy"))
    touch(joinpath(regular_dir, ".lazy"))

    write(joinpath(topo_dir, "ATTRIBUTION.md"), NASA_ATTRIBUTION)
    write(joinpath(topo_bathy_dir, "ATTRIBUTION.md"), NASA_ATTRIBUTION)
    write(joinpath(regular_dir, "ATTRIBUTION.md"), NASA_ATTRIBUTION)
    
end

#=
## Full-sky image
This is a full-sky image composite from the European Space Observatory.  It's pretty high resolution
so can fill a good skymap.
=#
skydir = datadir("skymap")
mkpath(skydir)

skymap_url = "https://cdn.eso.org/images/original/eso0932a.tif"
http_download(skymap_url, joinpath(skydir, basename(skydir) * ".png"))
touch(joinpath(skydir, ".lazy"))
write(joinpath(skydir, "ATTRIBUTION.md"), """
Creative Commons Attribution 4.0 International License.
Copyright: ESO/S. Brunier

Per the terms of the license, please include attribution that is clearly visible 
whenever this image is used.
The string is:

ESO/S. Brunier
""")

#=
## ESA METOP data
This is some data that's used for our satellite imagery demos.

The data is in the public domain and freely usable.  But the way you do this is a little complicated.

=#