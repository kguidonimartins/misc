# helpers -----------------------------------------------------------------
read_geo_test_sf <- function() {
  pt <- sf::st_sfc(sf::st_point(c(1, 2)), crs = 4326)
  sf::st_sf(id = 1L, geometry = pt)
}

read_geo_expected_names <- function() {
  c(
    "fpath", "file_type", "layer_name", "geometry_type",
    "nrows_aka_features", "ncols_aka_fields", "crs_name", "data"
  )
}

# read_geo ----------------------------------------------------------------
test_that("read_geo dispatches zip like read_sf_zip", {
  skip_if_not_installed("zip")
  d <- tempfile("readgeo_meta_zip")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  sf::write_sf(read_geo_test_sf(), file.path(d, "one.shp"))
  z <- tempfile(fileext = ".zip")
  on.exit(unlink(z), add = TRUE)
  owd <- getwd()
  setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(list.files(d)))
  expect_equal(read_geo(z), read_sf_zip(z))
})

test_that("read_geo reads .shp via default GDAL branch", {
  shp <- system.file("shape/nc.shp", package = "sf")
  skip_if_not(file.exists(shp), "nc.shp not available")
  out <- read_geo(shp)
  expect_true("data" %in% names(out))
  expect_equal(out$file_type, "shp")
})

# read_sf_zip -------------------------------------------------------------
test_that("read_sf_zip errors when path is missing", {
  expect_error(
    read_sf_zip(file.path(tempdir(), "nonexistent-archive.zip")),
    "Path not found"
  )
})

test_that("read_sf_zip errors when zip has no shapefile", {
  skip_if_not_installed("zip")
  plain <- tempfile(fileext = ".txt")
  writeLines("hello", plain)
  z <- tempfile(fileext = ".zip")
  zip::zip(z, plain)
  expect_error(read_sf_zip(z), "No .shp")
  unlink(c(plain, z))
})

test_that("read_sf_zip reads one shapefile from zip", {
  skip_if_not_installed("zip")
  d <- tempfile("readgeo_shp")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  shp_base <- file.path(d, "one")
  sf::write_sf(read_geo_test_sf(), paste0(shp_base, ".shp"))
  z <- tempfile(fileext = ".zip")
  on.exit(unlink(z), add = TRUE)
  owd <- getwd()
  setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(list.files(d)))
  out <- read_sf_zip(z)
  expect_s3_class(out, "tbl_df")
  expect_named(out, read_geo_expected_names())
  expect_equal(nrow(out), 1L)
  expect_true(all(purrr::map_lgl(out$data, inherits, "sf")))
  expect_equal(out$file_type, "shp")
  expect_true(out$nrows_aka_features >= 1L)
  expect_match(out$fpath, "^/vsizip/")
})

test_that("read_sf_zip reads multiple shapefiles from zip", {
  skip_if_not_installed("zip")
  d <- tempfile("readgeo_shp2")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  sf::write_sf(read_geo_test_sf(), file.path(d, "a.shp"))
  sf::write_sf(read_geo_test_sf(), file.path(d, "b.shp"))
  z <- tempfile(fileext = ".zip")
  on.exit(unlink(z), add = TRUE)
  owd <- getwd()
  setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(list.files(d)))
  out <- read_sf_zip(z)
  expect_equal(nrow(out), 2L)
  expect_setequal(out$layer_name, c("a", "b"))
  expect_true(all(purrr::map_lgl(out$data, inherits, "sf")))
})

# read_kmz ----------------------------------------------------------------
test_that("read_kmz errors when path is missing", {
  expect_error(
    read_kmz(file.path(tempdir(), "missing.kmz")),
    "Path not found"
  )
})

test_that("read_kmz errors when archive has no kml", {
  skip_if_not_installed("zip")
  plain <- tempfile(fileext = ".txt")
  writeLines("hello", plain)
  z <- tempfile(fileext = ".kmz")
  zip::zip(z, plain)
  expect_error(read_kmz(z), "No .kml")
  unlink(c(plain, z))
})

test_that("read_kmz reads kmz built from a single kml layer", {
  skip_if_not_installed("zip")
  skip_if_not("KML" %in% sf::st_drivers()$name, "GDAL KML driver not available")
  d <- tempfile("readgeo_kml")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  kml_path <- file.path(d, "doc.kml")
  sf::write_sf(read_geo_test_sf(), kml_path, driver = "KML")
  z <- tempfile(fileext = ".kmz")
  on.exit(unlink(z), add = TRUE)
  zip::zip(z, kml_path)
  out <- read_kmz(z)
  expect_equal(nrow(out), 1L)
  expect_named(out, read_geo_expected_names())
  expect_equal(out$file_type, "kmz")
  expect_equal(normalizePath(out$fpath, winslash = "/"), normalizePath(z, winslash = "/"))
  expect_true(inherits(out$data[[1]], "sf"))
})

# read_gdb ----------------------------------------------------------------
test_that("read_gdb errors when path is missing", {
  expect_error(
    read_gdb(file.path(tempdir(), "missing.gdb")),
    "Path not found"
  )
})

test_that("read_gdb reads gdb when OpenFileGDB write works", {
  skip_on_cran()
  d <- tempfile("readgeo_gdb")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  gdb <- file.path(d, "test.gdb")
  wrote <- tryCatch(
    {
      sf::write_sf(read_geo_test_sf(), gdb, driver = "OpenFileGDB")
      TRUE
    },
    error = function(e) FALSE
  )
  skip_if_not(wrote, "OpenFileGDB driver cannot write this gdb in this environment")

  out <- read_gdb(gdb)
  expect_named(out, read_geo_expected_names())
  expect_true(nrow(out) >= 1L)
  expect_true(all(purrr::map_lgl(out$data, inherits, "sf")))

  lyr <- out$layer_name[[1]]
  one <- read_gdb(gdb, layer = lyr)
  expect_equal(nrow(one), 1L)
  expect_equal(one$layer_name[[1]], lyr)
})

test_that("read_gdb errors on unknown layer", {
  skip_on_cran()
  d <- tempfile("readgeo_gdb2")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  gdb <- file.path(d, "test2.gdb")
  wrote <- tryCatch(
    {
      sf::write_sf(read_geo_test_sf(), gdb, driver = "OpenFileGDB")
      TRUE
    },
    error = function(e) FALSE
  )
  skip_if_not(wrote, "OpenFileGDB driver cannot write this gdb in this environment")

  expect_error(read_gdb(gdb, layer = "nonexistent_layer_xyz"), "not found")
})
