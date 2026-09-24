test_that("deduplicate_by keeps the first row of each group", {
  df <- data.frame(g = c("a", "a", "b", "b"), h = c(1, 2, 1, 1), v = 1:4)

  out <- deduplicate_by(df, g)
  expect_equal(out$v, c(1L, 3L))

  out <- deduplicate_by(df, g, h)
  expect_equal(out$v, c(1L, 2L, 3L))
})

test_that("deduplicate_by returns an ungrouped result", {
  out <- deduplicate_by(mtcars, cyl)
  expect_false(dplyr::is_grouped_df(out))
  expect_equal(nrow(out), 3)
})
