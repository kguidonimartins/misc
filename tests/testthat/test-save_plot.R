if (!require("ggplot2")) install.packages("ggplot2")

p <- ggplot(mtcars) +
  aes(mpg, cyl) +
  geom_point()

test_that("save_plot works with default arguments", {
  create_dirs()
  save_plot(p)
  expect_true(file.exists("output/figures/p.png"))
  unlink(c("data", "output", "R"), recursive = TRUE)
})

test_that("save_plot also trim", {
  create_dirs()
  save_plot(p, trim = TRUE)
  expect_true(file.exists("output/figures/trim/p.png"))
  unlink(c("data", "output", "R"), recursive = TRUE)
})


test_that("save_plot fails without misc::create_dirs folders", {
  expect_error(save_plot(p))
})

test_that("save_plot works with custom dir_to_save", {
  create_dirs(dirs = "ma-folder")
  save_plot(p, dir_to_save = "ma-folder")
  expect_true(file.exists("ma-folder/p.png"))
  unlink("ma-folder", recursive = TRUE)
})

test_that("save_plot works can overwhite a previous saved figure", {
  create_dirs()
  file.create("output/figures/p.png")
  save_plot(p, overwrite = TRUE)
  expect_true(file.size("output/figures/p.png") > 0)
  unlink(c("data", "output", "R"), recursive = TRUE)
})
