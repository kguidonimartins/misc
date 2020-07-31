test_that("describe_data returns a skimr object", {
  nice_data <- data.frame(c1 = c(1, NA, 3), c2 = c(NA, NA, 5), c3 = c("a", "b", NA))
  nice_data_desc <- nice_data %>% describe_data()
  expect_equal(class(nice_data_desc)[1], "skim_df")
})
