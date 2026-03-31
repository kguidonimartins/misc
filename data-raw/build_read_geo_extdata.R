# Run from the package root: Rscript data-raw/build_read_geo_extdata.R
# Requires sf, zip (same as tests). Regenerates flat spatial samples in inst/extdata
# (GeoJSON, GPKG, shapefile-in-ZIP, KML, KMZ). For misc_example.gdb use
# data-raw/build_misc_example_gdb.sh

local({
  if (!file.exists("DESCRIPTION")) {
    stop("Run from package root (directory containing DESCRIPTION).", call. = FALSE)
  }
  suppressPackageStartupMessages({
    library(sf)
    library(zip)
  })

  ext <- file.path("inst", "extdata")
  dir.create(ext, FALSE, TRUE)

  pt <- sf::st_sfc(sf::st_point(c(1, 2)), crs = 4326)
  obj <- sf::st_sf(id = 1L, geometry = pt)

  write_geojson <- function() {
    f <- file.path(ext, "misc_example.geojson")
    if (file.exists(f)) {
      unlink(f)
    }
    sf::write_sf(obj, f, layer = "misc_example")
  }

  write_gpkg <- function() {
    f <- file.path(ext, "misc_example.gpkg")
    if (file.exists(f)) {
      unlink(f)
    }
    sf::write_sf(obj, f, driver = "GPKG", layer = "misc_example")
  }

  loose_shp <- function() {
    shp_base <- file.path(ext, "misc_example")
    for (suf in c("shp", "shx", "dbf", "prj", "cpg")) {
      f <- paste0(shp_base, ".", suf)
      if (file.exists(f)) {
        unlink(f)
      }
    }
    sf::write_sf(obj, paste0(shp_base, ".shp"))
  }

  shp_zip <- function() {
    d <- tempfile("extdata_shp")
    dir.create(d)
    on.exit(unlink(d, recursive = TRUE), add = TRUE)
    shp_base <- file.path(d, "misc_example")
    sf::write_sf(obj, paste0(shp_base, ".shp"))
    z <- file.path(ext, "misc_example.zip")
    if (file.exists(z)) {
      unlink(z)
    }
    owd <- getwd()
    on.exit(setwd(owd), add = TRUE)
    setwd(d)
    zip::zip(z, basename(list.files(d)))
  }

  write_kml_file <- function() {
    f <- file.path(ext, "misc_example.kml")
    if (file.exists(f)) {
      unlink(f)
    }
    sf::write_sf(obj, f, driver = "KML")
  }

  write_kmz_file <- function() {
    d <- tempfile("extdata_kmz")
    dir.create(d)
    on.exit(unlink(d, recursive = TRUE), add = TRUE)
    kml <- file.path(d, "doc.kml")
    sf::write_sf(obj, kml, driver = "KML")
    z <- file.path(ext, "misc_example.kmz")
    if (file.exists(z)) {
      unlink(z)
    }
    owd <- getwd()
    on.exit(setwd(owd), add = TRUE)
    setwd(d)
    zip::zip(z, "doc.kml")
  }

  write_geojson()
  write_gpkg()
  loose_shp()
  shp_zip()
  write_kml_file()
  write_kmz_file()

  message("Wrote GeoJSON, GPKG, shapefile, ZIP (shapefile), KML, KMZ under inst/extdata/")
  invisible(NULL)
})
