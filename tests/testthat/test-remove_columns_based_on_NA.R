df <- data.frame(
  a = c(1, 2, NA, 4, 5),
  b = c(NA, NA, NA, 4, 5),
  c = c(1, 2, 3, NA, 5)
)

test_that("remove_columns_based_on_NA drops columns above the threshold", {
  expect_named(remove_columns_based_on_NA(df), c("a", "c"))
  expect_named(remove_columns_based_on_NA(df, threshold = 0.1), character())
  expect_named(remove_columns_based_on_NA(df, threshold = 0.6), c("a", "b", "c"))
})
