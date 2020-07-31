xlsx_dir <- system.file("xlsx-examples", package = "misc")

test_that("read_all_xlsx_then_save_csv works when do 'data/temp' exists", {
  create_dirs(dirs = NULL)
  read_all_xlsx_then_save_csv(path_to_xlsx = xlsx_dir)
  expect_true(
    file.exists(
      "data/temp/extracted_sheets/mtcars_workbook_001/mtcars_workbook_001_mtcars_sheet_001.csv"
    )
  )
  expect_equal(length(fs::dir_ls("data/temp/extracted_sheets/mtcars_workbook_001", recurse = TRUE)), 10)
  expect_equal(length(list.files("data/temp/extracted_sheets", recursive = TRUE)), 100)
  unlink(c("data", "output", "R"), recursive = TRUE)
})

test_that("read_all_xlsx_then_save_csv fails when does not 'data/temp' exists", {
  expect_error(
    read_all_xlsx_then_save_csv(
      path_to_xlsx = xlsx_file
    )
  )
})
