test_that("check_require passes silently for installed packages", {
  expect_no_error(check_require("stats"))
})

test_that("check_require errors for missing packages", {
  expect_error(check_require("noSuchPackageAsThis12345"), "needed for this")
  expect_error(
    check_require("someone/noSuchPackageAsThis12345"),
    "someone/noSuchPackageAsThis12345"
  )
})
