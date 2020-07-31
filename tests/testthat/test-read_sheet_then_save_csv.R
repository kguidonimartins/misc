xlsx_file <-
  system.file("xlsx-examples", "mtcars_workbook_001.xlsx", package = "misc")

# read_sheet_then_save_csv <- function(excel_sheet, path_to_xlsx, dir_to_save = NULL)

test_that("read_sheet_then_save_csv works with NULL entry for dir_to_save", {
  create_dirs(dirs = NULL)
  read_sheet_then_save_csv(
    excel_sheet = "mtcars_sheet_001",
    path_to_xlsx = xlsx_file,
    dir_to_save = NULL
  )
  expect_true(
    file.exists(
      "data/temp/mtcars_workbook_001/mtcars_workbook_001_mtcars_sheet_001.csv"
    )
  )
  unlink(c("data", "output", "R"), recursive = TRUE)
})

test_that("read_sheet_then_save_csv works with custom entry for dir_to_save", {
  create_dirs(dirs = "ma-folder")
  read_sheet_then_save_csv(
    excel_sheet = "mtcars_sheet_001",
    path_to_xlsx = xlsx_file,
    dir_to_save = "ma-folder"
  )
  expect_true(
    file.exists(
      "ma-folder/mtcars_workbook_001/mtcars_workbook_001_mtcars_sheet_001.csv"
    )
  )
  unlink("ma-folder", recursive = TRUE)
})

test_that("read_sheet_then_save_csv fails with custom entry for dir_to_save which not exists", {
  expect_error(
    read_sheet_then_save_csv(
      excel_sheet = "mtcars_sheet_001",
      path_to_xlsx = xlsx_file,
      dir_to_save = "ma-folder"
    )
  )
})

test_that("read_sheet_then_save_csv fails with NULL entry for dir_to_save which not exists", {
  expect_error(
    read_sheet_then_save_csv(
      excel_sheet = "mtcars_sheet_001",
      path_to_xlsx = xlsx_file,
      dir_to_save = NULL
    )
  )
})
