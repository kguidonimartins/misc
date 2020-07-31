xlsx_file <-
  system.file("xlsx-examples", "mtcars_workbook_001.xlsx", package = "misc")

test_that("read_all_sheets_then_save_csv works with NULL entry for dir_to_save", {
  create_dirs(dirs = NULL)
  read_all_sheets_then_save_csv(path_to_xlsx = xlsx_file, dir_to_save = NULL)
  expect_true(
    file.exists(
      "data/temp/extracted_sheets/mtcars_workbook_001/mtcars_workbook_001_mtcars_sheet_001.csv"
    )
  )
  expect_equal(length(fs::dir_ls("data/temp/extracted_sheets/mtcars_workbook_001", recurse = TRUE)), 10)
  unlink(c("data", "output", "R"), recursive = TRUE)
})

test_that("read_all_sheets_then_save_csv works with custom entry for dir_to_save", {
  create_dirs(dirs = "ma-folder")
  read_all_sheets_then_save_csv(path_to_xlsx = xlsx_file, dir_to_save = "ma-folder")
  expect_true(
    file.exists(
      "ma-folder/mtcars_workbook_001/mtcars_workbook_001_mtcars_sheet_001.csv"
    )
  )
  expect_equal(length(fs::dir_ls("ma-folder/mtcars_workbook_001/", recurse = TRUE)), 10)
  unlink("ma-folder", recursive = TRUE)
})

test_that("read_all_sheets_then_save_csv fails with custom entry for dir_to_save which not exists", {
  expect_error(
    read_all_sheets_then_save_csv(
      path_to_xlsx = xlsx_file, dir_to_save = "ma-folder"
    )
  )
})

test_that("read_all_sheets_then_save_csv fails with NULL entry for dir_to_save which not exists", {
  expect_error(
    read_all_sheets_then_save_csv(
      path_to_xlsx = xlsx_file
    )
  )
})
