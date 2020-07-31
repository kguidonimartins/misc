test_that("na_viz returns a ggplot object", {
  na_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
  na_plot <- na_data %>% na_viz()
  expect_equal(class(na_plot)[2], "ggplot")
})
