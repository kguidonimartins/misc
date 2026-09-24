p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, cyl)) +
  ggplot2::geom_point()

test_that("save_plot saves to output/figures named after the object", {
  withr::local_dir(withr::local_tempdir())
  suppressMessages(create_dirs())

  suppressMessages(save_plot(p, width = 5, height = 5))
  expect_true(file.exists("output/figures/p.png"))
})

test_that("save_plot fails without the default output folder", {
  withr::local_dir(withr::local_tempdir())
  expect_error(suppressMessages(save_plot(p)), "does not exists")
})

test_that("save_plot fails when a custom dir_to_save is missing", {
  withr::local_dir(withr::local_tempdir())
  expect_error(
    suppressMessages(save_plot(p, dir_to_save = "nope")),
    "does not exists"
  )
})

test_that("save_plot honors filename, format, units, and dpi", {
  withr::local_dir(withr::local_tempdir())
  dir.create("figs")

  suppressMessages(
    save_plot(
      p,
      filename = "custom", dir_to_save = "figs", format = "pdf",
      units = "in", dpi = 72, width = 3, height = 3
    )
  )
  expect_true(file.exists("figs/custom.pdf"))
})

test_that("save_plot keeps an existing file unless overwrite = TRUE", {
  withr::local_dir(withr::local_tempdir())
  suppressMessages(create_dirs())
  file.create("output/figures/p.png")

  suppressMessages(save_plot(p, width = 5, height = 5))
  expect_equal(file.size("output/figures/p.png"), 0)

  suppressMessages(save_plot(p, width = 5, height = 5, overwrite = TRUE))
  expect_gt(file.size("output/figures/p.png"), 0)
})

test_that("save_plot also trims when trim = TRUE", {
  skip_if_not_installed("magick")
  withr::local_dir(withr::local_tempdir())
  suppressMessages(create_dirs())

  suppressMessages(save_plot(p, width = 5, height = 5, trim = TRUE))
  expect_true(file.exists("output/figures/trim/p.png"))
})
