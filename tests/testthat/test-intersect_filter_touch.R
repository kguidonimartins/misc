# intersect_filter_touch ------------------------------------------------------
# Evita lookups de redes do PROJ (podem travar em CI/offline).
Sys.setenv(PROJ_NETWORK = "OFF")

skip_if_not_installed("sf")
suppressPackageStartupMessages(library(dplyr))

ift_metric_crs <- function() sf::st_crs(3857)

ift_rect_sf <- function(xmin, ymin, xmax, ymax, crs = ift_metric_crs()) {
  ring <- matrix(
    c(xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax, xmin, ymin),
    ncol = 2L,
    byrow = TRUE
  )
  sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = crs))
}

test_that("intersect_filter_touch rejeita x ou y não-sf", {
  y <- ift_rect_sf(0, 0, 1e6, 1e6)
  expect_error(intersect_filter_touch(1L, y), "`x` and `y` must be sf objects")
  expect_error(intersect_filter_touch(y, "not sf"), "`x` and `y` must be sf objects")
})

test_that("intersect_filter_touch mantém apenas features que tocam y", {
  crs <- ift_metric_crs()
  y <- ift_rect_sf(0, 0, 1e6, 1e6)
  inside <- dplyr::transmute(ift_rect_sf(1e5, 1e5, 9e5, 9e5), id = "in")
  outside <- dplyr::transmute(ift_rect_sf(2e6, 2e6, 3e6, 3e6), id = "out")
  x <- dplyr::bind_rows(inside, outside)

  out <- intersect_filter_touch(x, y, repair = FALSE)
  expect_equal(nrow(out), 1L)
  expect_equal(out$id, "in")
})

test_that("intersect_filter_touch devolve sf vazio quando nada toca", {
  crs <- ift_metric_crs()
  y <- ift_rect_sf(0, 0, 1e5, 1e5)
  x <- ift_rect_sf(2e5, 2e5, 3e5, 3e5)
  out <- intersect_filter_touch(x, y, repair = FALSE)
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 0L)
})

test_that("intersect_filter_touch preserva geometria e atributos de x", {
  crs <- ift_metric_crs()
  y <- ift_rect_sf(0, 0, 1e6, 1e6)
  x <- dplyr::transmute(
    ift_rect_sf(1e5, 1e5, 9e5, 9e5),
    id = "feat_1",
    val = 42L
  )
  out <- intersect_filter_touch(x, y, repair = FALSE)
  expect_equal(out$id, "feat_1")
  expect_equal(out$val, 42L)
  expect_equal(
    sf::st_area(sf::st_geometry(out)),
    sf::st_area(sf::st_geometry(x)),
    tolerance = 1e-6
  )
})

test_that("intersect_filter_touch aceita pontos e linhas (não exige polígonos)", {
  crs <- ift_metric_crs()
  y <- ift_rect_sf(0, 0, 1e6, 1e6)
  pt_in <- sf::st_sf(
    id = "pt_in",
    geometry = sf::st_sfc(sf::st_point(c(5e5, 5e5)), crs = crs)
  )
  pt_out <- sf::st_sf(
    id = "pt_out",
    geometry = sf::st_sfc(sf::st_point(c(2e6, 2e6)), crs = crs)
  )
  x <- dplyr::bind_rows(pt_in, pt_out)
  out <- intersect_filter_touch(x, y, repair = FALSE)
  expect_equal(out$id, "pt_in")
})

test_that("intersect_filter_touch funciona com y multi-feature", {
  crs <- ift_metric_crs()
  y1 <- dplyr::transmute(ift_rect_sf(0, 0, 1e5, 1e5), g = "a")
  y2 <- dplyr::transmute(ift_rect_sf(2e6, 2e6, 2.1e6, 2.1e6), g = "b")
  y <- dplyr::bind_rows(y1, y2)
  x_in_a <- dplyr::transmute(ift_rect_sf(1e4, 1e4, 2e4, 2e4), id = "near_a")
  x_in_b <- dplyr::transmute(ift_rect_sf(2.05e6, 2.05e6, 2.06e6, 2.06e6), id = "near_b")
  x_far <- dplyr::transmute(ift_rect_sf(5e6, 5e6, 5.1e6, 5.1e6), id = "far")
  x <- dplyr::bind_rows(x_in_a, x_in_b, x_far)

  out <- intersect_filter_touch(x, y, repair = FALSE)
  expect_setequal(out$id, c("near_a", "near_b"))
})

test_that("intersect_filter_touch com repair = TRUE aplica st_make_valid", {
  crs <- ift_metric_crs()
  y <- ift_rect_sf(0, 0, 1e6, 1e6)
  x <- ift_rect_sf(1e5, 1e5, 9e5, 9e5)
  out <- intersect_filter_touch(x, y, repair = TRUE)
  expect_equal(nrow(out), 1L)
})

test_that("intersect_filter_touch espelha filtro manual st_intersects/lengths", {
  crs <- ift_metric_crs()
  y <- ift_rect_sf(0, 0, 1e6, 1e6)
  x <- dplyr::bind_rows(
    dplyr::transmute(ift_rect_sf(1e5, 1e5, 9e5, 9e5), id = "in"),
    dplyr::transmute(ift_rect_sf(2e6, 2e6, 3e6, 3e6), id = "out"),
    dplyr::transmute(ift_rect_sf(-1e5, 5e5, 5e5, 6e5), id = "edge")
  )
  manual <- x[which(lengths(sf::st_intersects(x, y)) > 0L), ]
  out <- intersect_filter_touch(x, y, repair = FALSE)
  expect_equal(out$id, manual$id)
})