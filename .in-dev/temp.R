


read_all_xlsx_then_save_csv <- function(path_to_xlsx) {
  path_to_xlsx %>%
    fs::dir_ls(regexp = "\\.xls*") %>%
    purrr::map(~ read_all_sheets_then_save_csv(.x))
}


read_sheet_then_save_csv(
  excel_sheet = "Procedimentos",
  path_to_xlsx = "data/raw/Históricos clinícos 02_12_2019 20_05.xlsx",
  dir_to_save = "data/temp"
)

read_all_sheets_then_save_csv(path_to_xlsx = "data/raw/Históricos clinícos 02_12_2019 20_05.xlsx")

read_all_xlsx_then_save_csv(path_to_xlsx = "data/raw")
