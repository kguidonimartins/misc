# view_qgis --------------------------------------------------------------------
skip_if_not_installed("sf")
skip_on_os("windows")

vq_point <- function() {
  sf::st_sf(id = 1L, geometry = sf::st_sfc(sf::st_point(c(0, 0))))
}

test_that("view_qgis rejects non-sf inputs before platform checks", {
  tbl <- structure(data.frame(x = 1), class = c("tbl_df", "tbl", "data.frame"))
  expect_error(view_qgis(data.frame(x = 1)), "Input must be an sf object")
  expect_error(view_qgis(tbl), "Input must be an sf object")
  expect_error(view_qgis(matrix(1)), "Input must be an sf object")
  expect_error(view_qgis(NULL), "Input must be an sf object")
})

test_that("view_qgis returns sf input in non-interactive sessions", {
  skip_if_not(tolower(as.character(Sys.info()[["sysname"]])) == "darwin")
  x <- vq_point()
  expect_warning(
    out <- view_qgis(x),
    "Non-interactive session"
  )
  expect_identical(out, x)
})

test_that("qgis app resolution honors environment and options", {
  old_env <- Sys.getenv("MISC_QGIS_APP", unset = NA_character_)
  old_option <- getOption("misc.qgis_app")
  on.exit({
    if (is.na(old_env)) {
      Sys.unsetenv("MISC_QGIS_APP")
    } else {
      Sys.setenv(MISC_QGIS_APP = old_env)
    }
    options(misc.qgis_app = old_option)
  }, add = TRUE)
  Sys.setenv(MISC_QGIS_APP = "QGIS-env")
  options(misc.qgis_app = "QGIS-option")
  expect_identical(.qgis_app(dirs = character()), "QGIS-env")

  Sys.setenv(MISC_QGIS_APP = "")
  expect_identical(.qgis_app(dirs = character()), "QGIS-option")
})

test_that("qgis app resolution reports missing applications", {
  empty_dir <- tempfile("misc-qgis-empty-")
  dir.create(empty_dir)
  on.exit(unlink(empty_dir, recursive = TRUE), add = TRUE)
  old_env <- Sys.getenv("MISC_QGIS_APP", unset = NA_character_)
  old_option <- getOption("misc.qgis_app")
  on.exit({
    if (is.na(old_env)) {
      Sys.unsetenv("MISC_QGIS_APP")
    } else {
      Sys.setenv(MISC_QGIS_APP = old_env)
    }
    options(misc.qgis_app = old_option)
  }, add = TRUE)
  Sys.setenv(MISC_QGIS_APP = "")
  options(misc.qgis_app = NULL)
  expect_error(
    .qgis_app(dirs = empty_dir),
    "QGIS was not found.*Install QGIS"
  )
})
