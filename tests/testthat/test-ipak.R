test_that("no prefer message", {
  expect_equal(length(ipak(c("vegan", "tidyverse"))), 0L)
})
