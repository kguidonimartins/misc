test_that("create_dirs works with NULL entry", {
  create_dirs(dirs = NULL)
  expect_true(file.exists("data/raw/.gitkeep"))
  expect_true(file.exists("data/clean/.gitkeep"))
  expect_true(file.exists("data/temp/.gitkeep"))
  expect_true(file.exists("output/figures/.gitkeep"))
  expect_true(file.exists("output/results/.gitkeep"))
  expect_true(file.exists("output/supp/.gitkeep"))
  unlink(c("data", "output", "R"), recursive = TRUE)
})

test_that("create_dirs works with custom entry", {
  tmp_dir <- file.path(tempdir(), "tchutchu")
  create_dirs(dirs = paste0(tmp_dir, "/ma-folder"))
  expect_true(dir.exists(paste0(tmp_dir, "/ma-folder")))
  unlink(tmp_dir, recursive = TRUE)
})
