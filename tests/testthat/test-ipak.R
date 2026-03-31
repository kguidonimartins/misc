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
