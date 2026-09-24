test_that("ipak returns a data frame with expected columns", {
  out <- suppressMessages(ipak(c("utils", "stats")))
  expect_s3_class(out, "data.frame")
  expect_true(all(c("pkg_name", "success", "version") %in% names(out)))
  expect_true(all(out$success))
  expect_type(out$version, "character")
})

test_that("ipak records failure for a non-installed package", {
  nm <- "noSuchPackageAsThis12345"
  out <- suppressMessages(suppressWarnings(ipak(nm)))
  expect_s3_class(out, "data.frame")
  expect_false(out$success[out$pkg_name == nm])
})

test_that("ipak suggests remotes::install_github for missing GitHub packages", {
  expect_message(
    utils::capture.output(ipak("someone/noSuchPackageAsThis12345")),
    "remotes::install_github\\(\"someone/noSuchPackageAsThis12345\"\\)"
  )
})

test_that("ipak expands tidyverse into its core packages", {
  core <- c(
    "ggplot2", "tibble", "tidyr", "readr", "purrr", "dplyr", "stringr",
    "forcats"
  )
  for (pkg in core) skip_if_not_installed(pkg)

  attached <- search()
  withr::defer({
    for (env in setdiff(search(), attached)) {
      detach(env, character.only = TRUE)
    }
  })

  utils::capture.output(out <- suppressMessages(ipak("tidyverse")))
  expect_setequal(out$pkg_name, core)
  expect_true(all(out$success))
})
