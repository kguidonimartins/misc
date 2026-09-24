skip_if_not_installed("rnaturalearth")
skip_if_not_installed("rnaturalearthdata")
skip_if_not_installed("stringr")

test_that("quick_map plots the whole world by default", {
  expect_s3_class(quick_map(), "ggplot")
})

test_that("quick_map filters countries with type = 'sf'", {
  p <- quick_map(region = "Brazil", type = "sf")
  expect_s3_class(p, "ggplot")
  expect_identical(unique(p$data$admin), "Brazil")
})

test_that("quick_map defaults to type = 'sf' when only region is given", {
  p <- quick_map(region = "Brazil")
  expect_s3_class(p, "ggplot")
  expect_identical(unique(p$data$admin), "Brazil")
})

test_that("quick_map rejects unknown map types", {
  expect_error(quick_map(type = "leaflet"), "should be one of")
})

test_that("quick_map draws borders with type = 'ggplot'", {
  skip_if_not_installed("maps")
  expect_no_warning(
    p <- quick_map(region = "United States of America", type = "ggplot")
  )
  expect_s3_class(p, "ggplot")
  expect_identical(ggplot2::get_labs(p)$x, "Longitude (decimals)")
})
