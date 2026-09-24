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

misc_extdata <- function(...) {
  system.file("extdata", ..., package = "misc", mustWork = FALSE)
}

misc_extdata_dir <- function() {
  p <- misc_extdata("misc_example.geojson")
  if (!nzchar(p)) {
    return("")
  }
  dirname(p)
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

test_that("read_geo reads bundled inst extdata samples", {
  ext <- misc_extdata_dir()
  skip_if_not(nzchar(ext) && dir.exists(ext), "inst/extdata not in package tree")
  f <- function(...) file.path(ext, ...)

  skip_if_not(file.exists(f("misc_example.zip")), "misc_example.zip not in package tree")
  expect_equal(nrow(read_geo(f("misc_example.zip"))), 1L)
  expect_equal(read_geo(f("misc_example.zip"))$file_type, "shp")

  skip_if_not("KML" %in% sf::st_drivers()$name, "GDAL KML driver not available")
  skip_if_not(file.exists(f("misc_example.kmz")), "misc_example.kmz not in package tree")
  kmz_out <- read_geo(f("misc_example.kmz"))
  expect_equal(nrow(kmz_out), 1L)
  expect_equal(kmz_out$file_type, "kmz")
  expect_equal(kmz_out$layer_name[[1]], "doc")

  skip_if_not(file.exists(f("misc_example.kml")), "misc_example.kml not in package tree")
  kml_out <- read_geo(f("misc_example.kml"))
  expect_equal(nrow(kml_out), 1L)
  expect_equal(kml_out$file_type, "kml")

  skip_if_not(file.exists(f("misc_example.gpkg")), "misc_example.gpkg not in package tree")
  expect_equal(nrow(read_geo(f("misc_example.gpkg"))), 1L)
  expect_equal(read_geo(f("misc_example.gpkg"))$file_type, "gpkg")

  skip_if_not(file.exists(f("misc_example.geojson")), "misc_example.geojson not in package tree")
  expect_equal(nrow(read_geo(f("misc_example.geojson"))), 1L)
  expect_equal(read_geo(f("misc_example.geojson"))$file_type, "geojson")

  skip_if_not(file.exists(f("misc_example.shp")), "misc_example.shp not in package tree")
  expect_equal(nrow(read_geo(f("misc_example.shp"))), 1L)
  expect_equal(read_geo(f("misc_example.shp"))$file_type, "shp")

  gdb <- f("misc_example.gdb")
  skip_if_not(dir.exists(gdb), "misc_example.gdb missing")
  gdb_out <- read_geo(gdb, layer = "OGRGeoJSON")
  expect_equal(nrow(gdb_out), 1L)
  expect_equal(gdb_out$file_type, "gdb")
})

# read_geo by_bbox --------------------------------------------------------
read_geo_bbox_pts <- function(crs = 4326) {
  pts <- sf::st_sf(
    id = 1:3,
    geometry = sf::st_sfc(
      sf::st_point(c(0, 0)), sf::st_point(c(1, 1)), sf::st_point(c(10, 10)),
      crs = 4326
    )
  )
  if (is.na(crs)) sf::st_set_crs(pts, NA) else sf::st_transform(pts, crs)
}

read_geo_bbox <- function(crs = 4326) {
  sf::st_bbox(c(xmin = -0.5, ymin = -0.5, xmax = 1.5, ymax = 1.5), crs = crs)
}

test_that("read_geo by_bbox keeps only features intersecting the bbox", {
  d <- withr::local_tempdir()
  shp <- file.path(d, "pts.shp")
  sf::write_sf(read_geo_bbox_pts(), shp)

  expect_equal(read_geo(shp)$nrows_aka_features, 3L)

  out <- read_geo(shp, by_bbox = read_geo_bbox())
  expect_named(out, read_geo_expected_names())
  expect_equal(out$data[[1]]$id, 1:2)
  expect_equal(out$nrows_aka_features, 2L)
})

test_that("read_geo by_bbox filters every supported format", {
  skip_if_not_installed("zip")
  d <- withr::local_tempdir()
  pts <- read_geo_bbox_pts()
  sf::write_sf(pts, file.path(d, "pts.shp"))
  sf::write_sf(pts, file.path(d, "pts.gpkg"))
  sf::write_sf(pts, file.path(d, "pts.geojson"))
  withr::with_dir(d, zip::zip("pts.zip", paste0("pts.", c("shp", "shx", "dbf", "prj"))))
  paths <- file.path(d, c("pts.shp", "pts.gpkg", "pts.geojson", "pts.zip"))

  if ("KML" %in% sf::st_drivers()$name) {
    sf::write_sf(pts, file.path(d, "doc.kml"), driver = "KML")
    withr::with_dir(d, zip::zip("pts.kmz", "doc.kml"))
    paths <- c(paths, file.path(d, c("doc.kml", "pts.kmz")))
  }

  wrote_gdb <- tryCatch(
    {
      sf::write_sf(pts, file.path(d, "pts.gdb"), driver = "OpenFileGDB")
      TRUE
    },
    error = function(e) FALSE
  )
  if (wrote_gdb) paths <- c(paths, file.path(d, "pts.gdb"))

  for (p in paths) {
    out <- read_geo(p, by_bbox = read_geo_bbox())
    expect_equal(nrow(out$data[[1]]), 2L, info = basename(p))
    expect_equal(out$nrows_aka_features, 2L, info = basename(p))
  }
})

test_that("read_gdb, read_sf_zip and read_kmz accept by_bbox directly", {
  skip_if_not_installed("zip")
  d <- withr::local_tempdir()
  pts <- read_geo_bbox_pts()
  sf::write_sf(pts, file.path(d, "pts.shp"))
  withr::with_dir(d, zip::zip("pts.zip", paste0("pts.", c("shp", "shx", "dbf", "prj"))))
  expect_equal(nrow(read_sf_zip(file.path(d, "pts.zip"), by_bbox = read_geo_bbox())$data[[1]]), 2L)

  skip_if_not("KML" %in% sf::st_drivers()$name, "GDAL KML driver not available")
  sf::write_sf(pts, file.path(d, "doc.kml"), driver = "KML")
  withr::with_dir(d, zip::zip("pts.kmz", "doc.kml"))
  expect_equal(nrow(read_kmz(file.path(d, "pts.kmz"), by_bbox = read_geo_bbox())$data[[1]]), 2L)

  gdb <- file.path(d, "pts.gdb")
  wrote <- tryCatch(
    {
      sf::write_sf(pts, gdb, driver = "OpenFileGDB")
      TRUE
    },
    error = function(e) FALSE
  )
  skip_if_not(wrote, "OpenFileGDB driver cannot write this gdb in this environment")
  expect_equal(nrow(read_gdb(gdb, by_bbox = read_geo_bbox())$data[[1]]), 2L)
})

test_that("read_geo by_bbox reprojects the bbox to the layer CRS", {
  d <- withr::local_tempdir()
  shp <- file.path(d, "pts_3857.shp")
  sf::write_sf(read_geo_bbox_pts(crs = 3857), shp)

  out <- read_geo(shp, by_bbox = read_geo_bbox(crs = 4326))
  expect_equal(out$data[[1]]$id, 1:2)
})

test_that("read_geo by_bbox accepts sf, sfc and named numeric", {
  d <- withr::local_tempdir()
  shp <- file.path(d, "pts.shp")
  sf::write_sf(read_geo_bbox_pts(), shp)
  bb_sfc <- sf::st_as_sfc(read_geo_bbox())

  expect_equal(read_geo(shp, by_bbox = bb_sfc)$data[[1]]$id, 1:2)
  expect_equal(read_geo(shp, by_bbox = sf::st_sf(geometry = bb_sfc))$data[[1]]$id, 1:2)
  expect_equal(
    read_geo(shp, by_bbox = c(xmin = -0.5, ymin = -0.5, xmax = 1.5, ymax = 1.5))$data[[1]]$id,
    1:2
  )
})

test_that("read_geo by_bbox reads layers without geometry in full with a warning", {
  d <- withr::local_tempdir()
  pts <- read_geo_bbox_pts()

  # shapefile written without geometry is a lone .dbf
  sf::write_sf(sf::st_drop_geometry(pts), file.path(d, "tab.shp"))
  dbf <- file.path(d, "tab.dbf")
  expect_true(file.exists(dbf))
  expect_warning(
    out <- read_geo(dbf, by_bbox = read_geo_bbox()),
    "`tab` has no geometry column"
  )
  expect_equal(nrow(out$data[[1]]), 3L)

  gpkg <- file.path(d, "mixed.gpkg")
  sf::write_sf(pts, gpkg, layer = "pts")
  sf::write_sf(sf::st_drop_geometry(pts), gpkg, layer = "tab")
  expect_warning(
    out <- read_geo(gpkg, by_bbox = read_geo_bbox()),
    "`tab` has no geometry column"
  )
  n <- stats::setNames(purrr::map_int(out$data, nrow), out$layer_name)
  expect_equal(n[["pts"]], 2L)
  expect_equal(n[["tab"]], 3L)
})

test_that("read_geo by_bbox uses coordinates as-is when the layer CRS is unusable", {
  d <- withr::local_tempdir()
  # sf writes an undefined LOCAL_CS .prj for a missing CRS
  shp <- file.path(d, "localcs.shp")
  sf::write_sf(read_geo_bbox_pts(crs = NA), shp)
  expect_match(readLines(file.path(d, "localcs.prj"), warn = FALSE), "^LOCAL_CS")
  expect_warning(
    out <- read_geo(shp, by_bbox = read_geo_bbox()),
    "`localcs` has no CRS that `by_bbox` can be reprojected to"
  )
  expect_equal(out$data[[1]]$id, 1:2)

  shp <- file.path(d, "noprj.shp")
  sf::write_sf(read_geo_bbox_pts(), shp)
  file.remove(file.path(d, "noprj.prj"))
  expect_warning(
    out <- read_geo(shp, by_bbox = read_geo_bbox()),
    "`noprj` has no CRS that `by_bbox` can be reprojected to"
  )
  expect_equal(out$data[[1]]$id, 1:2)

  expect_no_warning(
    out <- read_geo(shp, by_bbox = c(xmin = -0.5, ymin = -0.5, xmax = 1.5, ymax = 1.5))
  )
  expect_equal(out$data[[1]]$id, 1:2)
})

test_that("read_geo by_bbox validates its input", {
  d <- withr::local_tempdir()
  shp <- file.path(d, "pts.shp")
  sf::write_sf(read_geo_bbox_pts(), shp)

  expect_error(read_geo(shp, by_bbox = "a"), "`by_bbox` must be")
  expect_error(read_geo(shp, by_bbox = c(1, 2, 3, 4)), "`by_bbox` must be")
  expect_error(read_geo(shp, by_bbox = read_geo_bbox_pts()[0, ]), "`by_bbox` must be")
  expect_error(
    read_geo(shp, by_bbox = read_geo_bbox(), wkt_filter = "POINT (0 0)"),
    "not both"
  )
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
  d <- tempfile("readgeo_plainzip")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  plain <- file.path(d, "hello.txt")
  writeLines("hello", plain)
  z <- tempfile(fileext = ".zip")
  on.exit(unlink(z), add = TRUE)
  owd <- getwd()
  setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(plain))
  expect_error(read_sf_zip(z), "No .shp")
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

test_that("read_sf_zip reads bundled misc_example.zip", {
  skip_if_not_installed("zip")
  z <- misc_extdata("misc_example.zip")
  skip_if_not(nzchar(z) && file.exists(z), "misc_example.zip not in package tree")
  out <- read_sf_zip(z)
  expect_named(out, read_geo_expected_names())
  expect_equal(nrow(out), 1L)
  expect_equal(out$layer_name[[1]], "misc_example")
  expect_true(inherits(out$data[[1]], "sf"))
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
  d <- tempfile("readgeo_plainkmz")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  plain <- file.path(d, "hello.txt")
  writeLines("hello", plain)
  z <- tempfile(fileext = ".kmz")
  on.exit(unlink(z), add = TRUE)
  owd <- getwd()
  setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(plain))
  expect_error(read_kmz(z), "No .kml")
})

test_that("read_kmz reads bundled misc_example.kmz", {
  skip_if_not("KML" %in% sf::st_drivers()$name, "GDAL KML driver not available")
  kmz <- misc_extdata("misc_example.kmz")
  skip_if_not(nzchar(kmz) && file.exists(kmz), "misc_example.kmz not in package tree")
  out <- read_kmz(kmz)
  expect_equal(nrow(out), 1L)
  expect_named(out, read_geo_expected_names())
  expect_equal(out$file_type, "kmz")
  expect_equal(out$layer_name[[1]], "doc")
  expect_true(inherits(out$data[[1]], "sf"))
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
  owd <- getwd()
  setwd(d)
  on.exit(setwd(owd), add = TRUE)
  zip::zip(z, basename(kml_path))
  out <- read_kmz(z)
  expect_equal(nrow(out), 1L)
  expect_named(out, read_geo_expected_names())
  expect_equal(out$file_type, "kmz")
  expect_equal(normalizePath(out$fpath, winslash = "/"), normalizePath(z, winslash = "/"))
  expect_true(inherits(out$data[[1]], "sf"))
})

# read_gdb ----------------------------------------------------------------
test_that("read_gdb reads bundled inst extdata gdb when present", {
  gdb <- system.file("extdata", "misc_example.gdb", package = "misc", mustWork = FALSE)
  skip_if_not(nzchar(gdb) && dir.exists(gdb), "misc_example.gdb not in package tree")

  out <- read_gdb(gdb)
  expect_named(out, read_geo_expected_names())
  expect_equal(out$layer_name[[1]], "OGRGeoJSON")

  one <- read_gdb(gdb, layer = "OGRGeoJSON")
  expect_equal(nrow(one), 1L)
})

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
