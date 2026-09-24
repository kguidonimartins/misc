na_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))

test_that("na_count works", {
  na_res <-
    na_data %>%
    na_count(sort = FALSE)
  expect_equal(na_res$na_count, c(1, 2), ignore_attr = TRUE)
  expect_equal(na_res$na_percent, c(50, 100), ignore_attr = TRUE)
})

test_that("na_count sorts by NA percentage by default", {
  na_res <- na_count(na_data)
  expect_equal(na_res$variables, c("c2", "c1"))
  expect_equal(na_res$na_percent, c(100, 50), ignore_attr = TRUE)
})
