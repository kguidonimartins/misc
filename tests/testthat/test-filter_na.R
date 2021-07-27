nice_data <-
  data.frame(
    c1 = c(NA, 4, NA),
    c2 = c(NA, 2, 5),
    c3 = c(NA, "b", NA)
  )

test_that("filter_na(type='any') works", {
  filtered_any <- filter_na(nice_data, "any")
  expect_equal(nrow(filtered_any), 2)
})

test_that("filter_na(type='all') works", {
  filtered_all <- filter_na(nice_data, "all")
  expect_equal(nrow(filtered_all), 1)
})
