test_that("add_gitignore downloads the template and appends tags", {
  withr::local_dir(withr::local_tempdir())
  local_mocked_bindings(
    download.file = function(url, destfile, ...) {
      writeLines(paste("# template from", url), destfile)
      0L
    },
    .package = "utils"
  )

  suppressMessages(add_gitignore(type = c("r", "python", "r")))

  lines <- readLines(".gitignore")
  expect_match(lines[[1]], "gitignore/api/r,python$")
  expect_identical(lines[[length(lines)]], "tags")
})

test_that("add_gitignore refuses to overwrite an existing file", {
  withr::local_dir(withr::local_tempdir())
  writeLines("existing", ".gitignore")

  expect_error(suppressMessages(add_gitignore()), "not created")
  expect_identical(readLines(".gitignore"), "existing")
})
