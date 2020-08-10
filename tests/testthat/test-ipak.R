test_that("0 length ipak output installing cran packages", {
  expect_equal(length(ipak("vegan")), 0L)
})

test_that("0 length ipak output installing github packages", {
  expect_equal(length(ipak("jalvesaq/colorout")), 0L)
})

test_that("expands tidyverse packages", {
  expect_equal(length(ipak("tidyverse")), 0L)
})
