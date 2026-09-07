# remove_geom_holes ------------------------------------------------------------
Sys.setenv(PROJ_NETWORK = "OFF")
skip_if_not_installed("sf")

rgh_ring <- function(xmin, ymin, xmax, ymax) {
  matrix(
    c(xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax, xmin, ymin),
    ncol = 2L,
    byrow = TRUE
  )
}

rgh_polygon <- function(holes = list()) {
  sf::st_polygon(c(list(rgh_ring(0, 0, 10, 10)), holes))
}

rgh_hole <- function(size, offset = 1) {
  rgh_ring(offset, offset, offset + size, offset + size)
}

test_that("removes holes from a POLYGON sfg", {
  x <- rgh_polygon(list(rgh_hole(2)))
  out <- remove_geom_holes(x)
  expect_s3_class(out, "sfg")
  expect_equal(length(out), 1L)
})

test_that("removes holes from every MULTIPOLYGON part", {
  x <- sf::st_multipolygon(list(
    list(rgh_ring(0, 0, 10, 10), rgh_hole(2)),
    list(rgh_ring(20, 20, 30, 30), rgh_hole(1, 21))
  ))
  out <- remove_geom_holes(x)
  expect_s3_class(out, "sfg")
  expect_true(all(vapply(out, length, integer(1)) == 1L))
})

test_that("preserves sfc length and CRS", {
  crs <- sf::st_crs(3857)
  x <- sf::st_sfc(rgh_polygon(list(rgh_hole(2))), rgh_polygon(), crs = crs)
  out <- remove_geom_holes(x)
  expect_s3_class(out, "sfc")
  expect_length(out, 2L)
  expect_identical(sf::st_crs(out), crs)
})

test_that("preserves sf attributes and geometry column name", {
  x <- sf::st_sf(
    id = c("a", "b"), value = c(2L, 3L),
    shape = sf::st_sfc(rgh_polygon(list(rgh_hole(2))), rgh_polygon())
  )
  out <- remove_geom_holes(x)
  expect_identical(names(out), names(x))
  expect_identical(out$id, x$id)
  expect_identical(out$value, x$value)
  expect_identical(attr(out, "sf_column"), "shape")
})

test_that("max_area removes only smaller holes", {
  x <- rgh_polygon(list(rgh_hole(1), rgh_hole(4, 5)))
  out <- remove_geom_holes(x, max_area = 2)
  expect_equal(length(out), 2L)
  expect_equal(
    as.numeric(sf::st_area(sf::st_sfc(out))),
    84
  )
})

test_that("polygons without holes are unchanged", {
  x <- rgh_polygon()
  expect_equal(remove_geom_holes(x), x)
})

test_that("rejects non-polygon geometries", {
  expect_error(
    remove_geom_holes(sf::st_point(c(0, 0))),
    "must be a POLYGON or MULTIPOLYGON"
  )
  expect_error(
    remove_geom_holes(sf::st_linestring(rgh_ring(0, 0, 1, 1))),
    "must be a POLYGON or MULTIPOLYGON"
  )
})

test_that("handles zero-row sf objects", {
  x <- sf::st_sf(
    id = integer(),
    geometry = sf::st_sfc(sf::st_polygon(), crs = sf::st_crs(3857))[FALSE]
  )
  expect_equal(remove_geom_holes(x), x)
})
