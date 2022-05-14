skip("Depends on rnaturalearth data")

p <- quick_map()

test_that("trim_fig works", {
  create_dirs()
  save_plot(p)
  trim_fig("output/figures/p.png")
  expect_true(file.exists("output/figures/trim/p.png"))
  unlink(c("data", "output", "R"), recursive = TRUE)
})
