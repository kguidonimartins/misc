test_that("add_gitignore download file", {
  add_gitignore()
  expect_true(file.exists(".gitignore"))
  unlink(".gitignore", recursive = TRUE)
})
