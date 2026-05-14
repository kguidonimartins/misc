# intersect_mask_filter_area -------------------------------------------------
# Evita lookups de redes do PROJ (podem travar em CI/offline).
Sys.setenv(PROJ_NETWORK = "OFF")

skip_if_not_installed("sf")
skip_if_not_installed("dplyr")
suppressPackageStartupMessages(library(dplyr))

imfa_metric_crs <- function() sf::st_crs(3857)

imfa_rect_sf <- function(xmin, ymin, xmax, ymax, crs = imfa_metric_crs()) {
  ring <- matrix(
    c(xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax, xmin, ymin),
    ncol = 2L,
    byrow = TRUE
  )
  sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = crs))
}

test_that("intersect_mask_filter_area rejeita x ou y não-sf", {
  y <- imfa_rect_sf(0, 0, 1e6, 1e6)
  crs <- imfa_metric_crs()
  expect_error(intersect_mask_filter_area(1L, y, crs = crs), "`x` and `y` must be sf objects")
  expect_error(intersect_mask_filter_area(y, "not sf", crs = crs), "`x` and `y` must be sf objects")
})

test_that("intersect_mask_filter_area rejects non-polygon geometries", {
  crs <- imfa_metric_crs()
  y <- imfa_rect_sf(0, 0, 1e6, 1e6)
  pt <- sf::st_sf(geometry = sf::st_sfc(sf::st_point(c(5e5, 5e5)), crs = crs))
  expect_error(
    intersect_mask_filter_area(pt, y, crs = crs),
    "must contain only POLYGON or MULTIPOLYGON",
    fixed = FALSE
  )
  ln <- sf::st_sf(geometry = sf::st_sfc(sf::st_linestring(matrix(c(0, 0, 1e6, 1e6), 2, 2)), crs = crs))
  expect_error(
    intersect_mask_filter_area(ln, y, crs = crs),
    "must contain only POLYGON or MULTIPOLYGON",
    fixed = FALSE
  )
})

test_that("intersect_mask_filter_area exige CRS definido em x e y", {
  crs <- imfa_metric_crs()
  x_ok <- imfa_rect_sf(0, 0, 1e3, 1e3)
  y_ok <- imfa_rect_sf(0, 0, 1e6, 1e6)
  x_na <- sf::st_set_crs(x_ok, sf::NA_crs_)
  y_na <- sf::st_set_crs(y_ok, sf::NA_crs_)
  expect_error(intersect_mask_filter_area(x_na, y_ok, crs = crs), "must have a CRS defined")
  expect_error(intersect_mask_filter_area(x_ok, y_na, crs = crs), "must have a CRS defined")
})

test_that("intersect_mask_filter_area erro se x_id não existe em x", {
  crs <- imfa_metric_crs()
  x <- imfa_rect_sf(1e5, 1e5, 3e5, 3e5)
  y <- imfa_rect_sf(0, 0, 1e6, 1e6)
  expect_error(
    intersect_mask_filter_area(x, y, x_id = "fid", crs = crs),
    "`x_id` must be a column name in `x`.",
    fixed = TRUE
  )
})

test_that("sem contato geométrico devolve clipped vazio e summary vazia", {
  crs <- imfa_metric_crs()
  y <- imfa_rect_sf(0, 0, 1e5, 1e5)
  x <- imfa_rect_sf(2e5, 2e5, 3e5, 3e5)
  out <- intersect_mask_filter_area(x, y, crs = crs, min_area_ratio = 0.5)
  expect_equal(nrow(out$clipped), 0L)
  expect_equal(nrow(out$summary), 0L)
  expect_true(all(c(".row_id", "area_clip", "area_full", "area_ratio", "keep") %in%
    names(out$summary)))
})

test_that("polígono inteiro dentro da máscara tem area_ratio ~ 1 e keep TRUE", {
  crs <- imfa_metric_crs()
  y <- imfa_rect_sf(0, 0, 1e6, 1e6)
  x <- imfa_rect_sf(1e5, 1e5, 3e5, 4e5)
  out <- intersect_mask_filter_area(x, y, crs = crs, min_area_ratio = 0.01, repair = FALSE)
  expect_equal(nrow(out$summary), 1L)
  expect_true(out$summary$keep[[1]])
  expect_equal(out$summary$area_full[[1]], out$summary$area_clip[[1]], tolerance = 1e-3)
  expect_equal(out$summary$area_ratio[[1]], 1, tolerance = 1e-6)
})

test_that("entrechoque mínimo cai quando min_area_ratio é alto", {
  crs <- imfa_metric_crs()
  y <- imfa_rect_sf(0, 0, 500, 500)
  x_wide <- imfa_rect_sf(-99500, 498, 498, 502)
  loose <- intersect_mask_filter_area(x_wide, y, crs = crs, min_area_ratio = 1e-4, repair = FALSE)
  strict <- intersect_mask_filter_area(x_wide, y, crs = crs, min_area_ratio = 0.5, repair = FALSE)
  expect_false(strict$summary$keep[[1]])
  expect_true(loose$summary$keep[[1]])
  expect_equal(loose$summary$area_ratio[[1]], strict$summary$area_ratio[[1]], tolerance = 1e-6)
})

test_that("x_id preserva agrupamento e filtra clipped por linha mantida", {
  crs <- imfa_metric_crs()
  y <- imfa_rect_sf(0, 0, 1e6, 1e6)
  x_a <- dplyr::transmute(imfa_rect_sf(1e5, 1e5, 9e5, 9e5), mun = "A")
  x_b <- dplyr::transmute(
    imfa_rect_sf(-99400, 998000, 2000, 998400),
    mun = "B"
  )
  x <- dplyr::bind_rows(x_a, x_b)
  loose <- intersect_mask_filter_area(x, y, x_id = "mun", crs = crs, min_area_ratio = 0.01)
  strict <- intersect_mask_filter_area(x, y, x_id = "mun", crs = crs, min_area_ratio = 0.99)

  expect_setequal(loose$summary$mun, c("A", "B"))
  expect_equal(sort(unique(loose$clipped$mun)), sort(c("A", "B")))
  expect_equal(sort(strict$summary$mun[strict$summary$keep]), "A")
})

test_that("intersect_mask_filter_area works on geobr municipalities x Caatinga (CE/RN)", {
  skip_if_not_installed("geobr")
  skip_on_cran()

  municipios_geom <- tryCatch(
    suppressMessages(
      geobr::read_municipality(showProgress = FALSE)
    ) |>
      sf::st_make_valid(),
    error = function(e) skip(paste0("geobr::read_municipality: ", conditionMessage(e)))
  )
  caatinga_geom <- tryCatch(
    suppressMessages(
      geobr::read_biomes(showProgress = FALSE)
    ) |>
      dplyr::filter(.data$name_biome == "Caatinga") |>
      sf::st_make_valid(),
    error = function(e) skip(paste0("geobr::read_biomes: ", conditionMessage(e)))
  )

  expect_true(nrow(caatinga_geom) >= 1L)

  munis_ne <- dplyr::filter(municipios_geom, .data$abbrev_state %in% c("CE", "RN"))
  munis_touch <- dplyr::slice(
    munis_ne,
    which(lengths(sf::st_intersects(munis_ne, caatinga_geom)) > 0L)
  )
  expect_gt(nrow(munis_touch), 0L)

  # Stable subset bounding runtime (still real geoms from geobr)
  munis_touch <- dplyr::arrange(munis_touch, !!rlang::sym("code_muni"))
  munis_demo <- dplyr::slice(munis_touch, seq_len(min(35L, nrow(munis_touch))))

  out_loose <- intersect_mask_filter_area(
    munis_demo,
    caatinga_geom,
    x_id = "code_muni",
    crs = NULL,
    min_area_ratio = 0.01,
    repair = FALSE
  )
  out_strict <- intersect_mask_filter_area(
    munis_demo,
    caatinga_geom,
    x_id = "code_muni",
    crs = NULL,
    min_area_ratio = 0.99,
    repair = FALSE
  )

  expect_true(all(c("code_muni", "area_clip", "area_full", "area_ratio", "keep") %in%
    names(out_loose$summary)))
  expect_equal(nrow(out_loose$summary), nrow(munis_demo))
  expect_equal(nrow(out_strict$summary), nrow(munis_demo))

  ar <- stats::na.omit(out_loose$summary$area_ratio)
  expect_true(all(ar >= 0 & ar <= 1 + .Machine$double.eps^(1 / 5)))

  expect_true(any(out_loose$summary$keep))

  loose_n <- sum(out_loose$summary$keep)
  strict_n <- sum(out_strict$summary$keep)
  expect_true(strict_n <= loose_n)

  uni_clip <- sort(unique(as.character(out_strict$clipped$code_muni)))
  ids_keep_strict <- sort(unique(as.character(
    dplyr::pull(dplyr::filter(out_strict$summary, .data$keep), "code_muni")
  )))
  expect_identical(ids_keep_strict, uni_clip)

  uniq_lo <- sort(unique(as.character(out_loose$clipped$code_muni)))
  ids_keep_lo <- sort(unique(as.character(
    dplyr::pull(dplyr::filter(out_loose$summary, .data$keep), "code_muni")
  )))
  expect_identical(ids_keep_lo, uniq_lo)
})
