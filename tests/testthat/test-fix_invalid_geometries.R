# fix_invalid_geometries -------------------------------------------------------
# Evita lookups de redes do PROJ (podem travar em CI/offline).
Sys.setenv(PROJ_NETWORK = "OFF")

skip_if_not_installed("sf")

fig_crs <- function() sf::st_crs(3857)

fig_bowtie <- function() {
  ring <- matrix(
    c(0, 0, 1e5, 0, 0, 1e5, 1e5, 1e5, 0, 0),
    ncol = 2L,
    byrow = TRUE
  )
  sf::st_polygon(list(ring))
}

fig_square <- function(xmin = 0, ymin = 0, xmax = 1e5, ymax = 1e5) {
  ring <- matrix(
    c(xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax, xmin, ymin),
    ncol = 2L,
    byrow = TRUE
  )
  sf::st_polygon(list(ring))
}

test_that("fix_invalid_geometries rejeita entrada não-sf", {
  expect_error(fix_invalid_geometries(data.frame(x = 1)), "must be an sf object")
  expect_error(fix_invalid_geometries(sf::st_sfc(fig_bowtie())), "must be an sf object")
  expect_error(fix_invalid_geometries(NULL), "must be an sf object")
})

test_that("fix_invalid_geometries devolve sf válido sem alterações quando tudo é válido", {
  x <- sf::st_sf(
    id = c("a", "b"),
    shape = sf::st_sfc(fig_square(), fig_square(2e5, 2e5), crs = fig_crs())
  )
  expect_message(
    out <- fix_invalid_geometries(x),
    "All geometries are valid"
  )
  expect_identical(out, x)
})

test_that("fix_invalid_geometries repara geometria inválida e reporta a linha", {
  x <- sf::st_sf(
    id = "bowtie",
    shape = sf::st_sfc(fig_bowtie(), crs = fig_crs())
  )
  expect_false(all(sf::st_is_valid(x)))
  expect_message(
    out <- fix_invalid_geometries(x),
    "1 invalid geometry at row 1"
  )
  expect_s3_class(out, "sf")
  expect_true(all(sf::st_is_valid(out)))
})

test_that("fix_invalid_geometries preserva atributos, nrow e coluna de geometria", {
  x <- sf::st_sf(
    id = c("bad", "good"),
    value = c(1L, 2L),
    shape = sf::st_sfc(fig_bowtie(), fig_square(), crs = fig_crs())
  )
  out <- fix_invalid_geometries(x)
  expect_equal(nrow(out), 2L)
  expect_identical(out$id, x$id)
  expect_identical(out$value, x$value)
  expect_identical(names(out), names(x))
  expect_identical(attr(out, "sf_column"), "shape")
})

test_that("fix_invalid_geometries repara apenas as linhas inválidas de uma camada mista", {
  x <- sf::st_sf(
    id = c("good1", "bad", "good2"),
    shape = sf::st_sfc(
      fig_square(),
      fig_bowtie(),
      fig_square(2e5, 2e5),
      crs = fig_crs()
    )
  )
  expect_message(
    out <- fix_invalid_geometries(x),
    "1 invalid geometry at row 2"
  )
  expect_true(all(sf::st_is_valid(out)))
  expect_equal(nrow(out), 3L)
})

test_that("fix_invalid_geometries não dá erro com sf de zero linhas", {
  x <- sf::st_sf(
    id = character(),
    geometry = sf::st_sfc(sf::st_polygon(), crs = fig_crs())[FALSE]
  )
  expect_message(
    out <- fix_invalid_geometries(x),
    "All geometries are valid"
  )
  expect_equal(out, x)
})

test_that("fix_invalid_geometries avisa quando uma geometria fica vazia", {
  x <- sf::st_sf(
    id = "bowtie",
    shape = sf::st_sfc(fig_bowtie(), crs = fig_crs())
  )
  local_mocked_bindings(
    st_make_valid = function(x, ...) {
      sf::st_geometry(x) <- sf::st_sfc(sf::st_polygon(), crs = sf::st_crs(x))
      x
    },
    .package = "sf"
  )
  expect_warning(
    suppressMessages(fix_invalid_geometries(x)),
    "row\\(s\\) 1 became empty"
  )
})
