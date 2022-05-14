skip("Too slow and buggy")

test_that("setup_lintr can create the `.lintr` file", {
  create_dirs(dirs = NULL)
  setup_lintr(exclude_path = "output")
  expect_true(file.exists(".lintr"))
  unlink(c("data", "output", "R", ".lintr"), recursive = TRUE)

})
