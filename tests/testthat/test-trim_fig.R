if (!require("ggplot2")) install.packages("ggplot2")

p <- ggplot(mtcars) +
  aes(mpg, cyl) +
  geom_point()

test_that("trim_fig works", {
  create_dirs()
  save_plot(p)
  trim_fig("output/figures/p.png")
  expect_true(file.exists("output/figures/trim/p.png"))
  unlink(c("data", "output", "R"), recursive = TRUE)
})
