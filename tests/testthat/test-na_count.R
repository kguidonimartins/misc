test_that("na_count works", {
  na_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
  na_res <-
    na_data %>%
    na_count()
  expect_equivalent(na_res$na_count, c(1, 2))
  expect_equivalent(na_res$na_percent, c(50, 100))
})
