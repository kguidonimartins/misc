# helpers -----------------------------------------------------------------
clean_geo_test_sf <- function(crs = 4326) {
  pt <- sf::st_sfc(sf::st_point(c(1, 2)), crs = crs)
  sf::st_sf(id = 1L, name = "ascii", geometry = pt)
}

clean_geo_test_sf_nonascii <- function() {
  pt <- sf::st_sfc(sf::st_point(c(1, 2)), crs = 4326)
  sf::st_sf(id = 1L, name = "caf\u00e9", geometry = pt)
}

clean_geo_test_sf_xyz <- function() {
  pt <- sf::st_sfc(sf::st_point(c(1, 2, 3), dim = "XYZ"), crs = 4326)
  sf::st_sf(id = 1L, geometry = pt)
}

clean_geo_make_zip <- function(sf_obj, layer = "in_layer") {
  d <- tempfile("clean_geo_in_zip_")
  dir.create(d)
  sf::write_sf(sf_obj, file.path(d, paste0(layer, ".shp")))
  z <- tempfile(fileext = ".zip")
  owd <- setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(list.files(d)))
  list(zip = z, dir = d)
}

misc_extdata <- function(...) {
  system.file("extdata", ..., package = "misc", mustWork = FALSE)
}

# validation --------------------------------------------------------------
test_that("clean_geo errors when output is missing or empty", {
  z <- tempfile(fileext = ".zip")
  expect_error(clean_geo(z), "output.*required")
  expect_error(clean_geo(z, ""), "output.*required")
  expect_error(clean_geo(z, NULL), "output.*required")
})

test_that("clean_geo errors when path is missing", {
  expect_error(
    clean_geo(file.path(tempdir(), "does-not-exist.zip"), tempfile(fileext = ".zip")),
    "Path not found"
  )
})

test_that("clean_geo errors on unsupported input extension", {
  skip_if_not_installed("textclean")
  bad <- tempfile(fileext = ".txt")
  writeLines("hi", bad)
  on.exit(unlink(bad), add = TRUE)
  expect_error(clean_geo(bad, tempfile(fileext = ".zip")), "Unsupported input")
})

test_that("clean_geo errors on unsupported output extension", {
  skip_if_not_installed("textclean")
  z <- misc_extdata("misc_example.zip")
  skip_if_not(nzchar(z) && file.exists(z), "misc_example.zip not in package tree")
  expect_error(clean_geo(z, tempfile(fileext = ".txt")), "Unsupported output")
})

# by input format ---------------------------------------------------------
test_that("clean_geo reads .zip input and writes .zip output", {
  skip_if_not_installed("textclean")
  skip_if_not_installed("zip")
  z <- misc_extdata("misc_example.zip")
  skip_if_not(nzchar(z) && file.exists(z), "misc_example.zip not in package tree")

  out <- tempfile(fileext = ".zip")
  on.exit(unlink(out), add = TRUE)
  res <- clean_geo(z, out, quiet = TRUE)
  expect_equal(normalizePath(res, winslash = "/"), normalizePath(out, winslash = "/"))
  expect_true(file.exists(out))

  re <- read_sf_zip(out)
  expect_equal(nrow(re), 1L)
  expect_equal(re$file_type, "shp")
  expect_equal(re$nrows_aka_features, 1L)
})

test_that("clean_geo reads .shp input and writes .shp output", {
  skip_if_not_installed("textclean")
  shp <- misc_extdata("misc_example.shp")
  skip_if_not(nzchar(shp) && file.exists(shp), "misc_example.shp not in package tree")

  out_dir <- tempfile("clean_geo_shp_out_")
  dir.create(out_dir)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
  out <- file.path(out_dir, "out.shp")
  clean_geo(shp, out, quiet = TRUE)
  expect_true(file.exists(out))
  expect_true(file.exists(file.path(out_dir, "out.dbf")))
  expect_true(file.exists(file.path(out_dir, "out.shx")))

  re <- sf::read_sf(out)
  expect_equal(nrow(re), 1L)
})

test_that("clean_geo reads .gpkg input and writes .gpkg output", {
  skip_if_not_installed("textclean")
  gpkg <- misc_extdata("misc_example.gpkg")
  skip_if_not(nzchar(gpkg) && file.exists(gpkg), "misc_example.gpkg not in package tree")

  out <- tempfile(fileext = ".gpkg")
  on.exit(unlink(out), add = TRUE)
  clean_geo(gpkg, out, quiet = TRUE)
  expect_true(file.exists(out))

  re <- sf::read_sf(out)
  expect_equal(nrow(re), 1L)
})

test_that("clean_geo reads .geojson input and writes .geojson output", {
  skip_if_not_installed("textclean")
  gj <- misc_extdata("misc_example.geojson")
  skip_if_not(nzchar(gj) && file.exists(gj), "misc_example.geojson not in package tree")

  out <- tempfile(fileext = ".geojson")
  on.exit(unlink(out), add = TRUE)
  clean_geo(gj, out, quiet = TRUE)
  expect_true(file.exists(out))

  re <- sf::read_sf(out)
  expect_equal(nrow(re), 1L)
})

# format conversion -------------------------------------------------------
test_that("clean_geo converts between formats", {
  skip_if_not_installed("textclean")
  shp <- misc_extdata("misc_example.shp")
  skip_if_not(nzchar(shp) && file.exists(shp), "misc_example.shp not in package tree")

  out_gpkg <- tempfile(fileext = ".gpkg")
  on.exit(unlink(out_gpkg), add = TRUE)
  clean_geo(shp, out_gpkg, quiet = TRUE)
  expect_true(file.exists(out_gpkg))
  expect_equal(tolower(tools::file_ext(out_gpkg)), "gpkg")
  expect_equal(nrow(sf::read_sf(out_gpkg)), 1L)

  out_gj <- tempfile(fileext = ".geojson")
  on.exit(unlink(out_gj), add = TRUE)
  clean_geo(shp, out_gj, quiet = TRUE)
  expect_true(file.exists(out_gj))
  expect_equal(tolower(tools::file_ext(out_gj)), "geojson")
  expect_equal(nrow(sf::read_sf(out_gj)), 1L)
})

# invariants --------------------------------------------------------------
test_that("clean_geo drops Z/M dimensions", {
  skip_if_not_installed("textclean")
  in_gpkg <- tempfile(fileext = ".gpkg")
  on.exit(unlink(in_gpkg), add = TRUE)
  sf::write_sf(clean_geo_test_sf_xyz(), in_gpkg, driver = "GPKG")

  out <- tempfile(fileext = ".gpkg")
  on.exit(unlink(out), add = TRUE)
  clean_geo(in_gpkg, out, quiet = TRUE)
  re <- sf::read_sf(out)
  cls <- class(sf::st_geometry(re))
  expect_false(any(grepl("XYZ|XYM|XYZM", cls)))
})

test_that("clean_geo replaces non-ASCII characters in attribute columns", {
  skip_if_not_installed("textclean")
  in_gpkg <- tempfile(fileext = ".gpkg")
  on.exit(unlink(in_gpkg), add = TRUE)
  sf::write_sf(clean_geo_test_sf_nonascii(), in_gpkg, driver = "GPKG")

  out <- tempfile(fileext = ".gpkg")
  on.exit(unlink(out), add = TRUE)
  clean_geo(in_gpkg, out, quiet = TRUE)
  re <- sf::read_sf(out)
  expect_false(grepl("[^[:ascii:]]", re$name, perl = TRUE))
  expect_match(re$name, "^[Cc]afe$")
})

test_that("clean_geo reprojects to the target CRS", {
  skip_if_not_installed("textclean")
  utm <- clean_geo_test_sf()
  utm <- sf::st_transform(utm, 31983)

  in_gpkg <- tempfile(fileext = ".gpkg")
  on.exit(unlink(in_gpkg), add = TRUE)
  sf::write_sf(utm, in_gpkg, driver = "GPKG")

  out <- tempfile(fileext = ".gpkg")
  on.exit(unlink(out), add = TRUE)
  clean_geo(in_gpkg, out, crs = 4326, quiet = TRUE)
  re <- sf::read_sf(out)
  expect_equal(sf::st_crs(re)$epsg, 4326L)
})

# zip edge cases ----------------------------------------------------------
test_that("clean_geo errors when input zip has no shapefile", {
  skip_if_not_installed("textclean")
  skip_if_not_installed("zip")
  d <- tempfile("clean_geo_noshp_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  txt <- file.path(d, "hello.txt")
  writeLines("hello", txt)
  z <- tempfile(fileext = ".zip")
  on.exit(unlink(z), add = TRUE)
  owd <- setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(txt))

  expect_error(
    clean_geo(z, tempfile(fileext = ".zip"), quiet = TRUE),
    "No .shp file"
  )
})

test_that("clean_geo errors when input zip has more than one shapefile", {
  skip_if_not_installed("textclean")
  skip_if_not_installed("zip")
  d <- tempfile("clean_geo_multi_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  sf::write_sf(clean_geo_test_sf(), file.path(d, "a.shp"))
  sf::write_sf(clean_geo_test_sf(), file.path(d, "b.shp"))
  z <- tempfile(fileext = ".zip")
  on.exit(unlink(z), add = TRUE)
  owd <- setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(list.files(d)))

  expect_error(
    clean_geo(z, tempfile(fileext = ".zip"), quiet = TRUE),
    "More than one .shp"
  )
})

test_that("clean_geo .zip output is a single shapefile readable by read_sf_zip", {
  skip_if_not_installed("textclean")
  skip_if_not_installed("zip")
  z_in <- misc_extdata("misc_example.zip")
  skip_if_not(nzchar(z_in) && file.exists(z_in), "misc_example.zip not in package tree")

  out <- tempfile(fileext = ".zip")
  on.exit(unlink(out), add = TRUE)
  clean_geo(z_in, out, quiet = TRUE)

  re <- read_sf_zip(out)
  expect_equal(nrow(re), 1L)
  expect_equal(re$file_type, "shp")
})
