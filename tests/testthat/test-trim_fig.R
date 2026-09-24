skip_if_not_installed("magick")

local_png <- function(path, env = parent.frame()) {
  grDevices::png(path, width = 200, height = 200)
  graphics::plot.new()
  graphics::rect(0.4, 0.4, 0.6, 0.6, col = "black")
  grDevices::dev.off()
  path
}

test_that("trim_fig writes a smaller copy into trim/", {
  withr::local_dir(withr::local_tempdir())
  fig <- local_png("fig.png")

  suppressMessages(trim_fig(fig))

  expect_true(file.exists("trim/fig.png"))
  info <- magick::image_info(magick::image_read("trim/fig.png"))
  expect_lt(info$width, 200)
})

test_that("trim_fig errors when the figure does not exist", {
  withr::local_dir(withr::local_tempdir())
  expect_error(suppressMessages(trim_fig("missing.png")), "does not exists")
})

test_that("trim_fig keeps an existing trimmed file unless overwrite = TRUE", {
  withr::local_dir(withr::local_tempdir())
  fig <- local_png("fig.png")
  dir.create("trim")
  file.create("trim/fig.png")

  suppressMessages(trim_fig(fig))
  expect_equal(file.size("trim/fig.png"), 0)

  suppressMessages(trim_fig(fig, overwrite = TRUE))
  expect_gt(file.size("trim/fig.png"), 0)
})
