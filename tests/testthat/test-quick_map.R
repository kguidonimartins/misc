skip("Depends on rnaturalearth data")

test_that("quick_map generate ggplot object", {
  expect_equal(class(quick_map())[2], "ggplot")
})
