test_that("save_temp_data works with NULL entry for dir_to_save", {
  create_dirs(dirs = NULL)
  awesome <- "not to much!"
  save_temp_data(awesome)
  expect_true(file.exists("data/temp/awesome.rds"))
  unlink(c("data", "output", "R"), recursive = TRUE)
})

test_that("save_temp_data works with custom entry for dir_to_save", {
  create_dirs(dirs = "ma-folder")
  awesome <- "not to much!"
  save_temp_data(awesome, "ma-folder")
  expect_true(file.exists("ma-folder/awesome.rds"))
  unlink("ma-folder", recursive = TRUE)
})

test_that("save_temp_data fails with custom entry for dir_to_save which not exists", {
  awesome <- "not to much!"
  expect_error(save_temp_data(awesome, "ma-folder"))
})

test_that("save_temp_data fails with NULL entry for dir_to_save which not exists", {
  awesome <- "not to much!"
  expect_error(save_temp_data(awesome))
})
