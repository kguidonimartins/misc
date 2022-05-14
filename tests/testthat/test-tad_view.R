test_that("tad_view throw an error when data argument is not a data.frame", {
  expect_error(tad_view(c(1:2)))
})
