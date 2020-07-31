#' Read and save into csv files all the sheets in a excel file
#'
#' @param path_to_xlsx a character vector with path to the excel file
#' @param dir_to_save a character vector with the path to save the csv files. Default is NULL and save the csv files in the "data/temp/extracted_sheets" if it exists.
#'
#' @importFrom fs dir_exists dir_create
#' @importFrom here here
#' @importFrom purrr map set_names
#' @importFrom readxl excel_sheets
#' @importFrom usethis ui_stop ui_field
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # read and into a csv
#' misc::create_dirs("ma-box")
#' xlsx_file <- system.file("xlsx-examples", "mtcars_workbook_001.xlsx", package = "misc")
#' read_all_sheet_then_save_csv(
#'   path_to_xlsx = xlsx_file,
#'   dir_to_save = "ma-box"
#' )
#' }
#'
read_all_sheets_then_save_csv <- function(path_to_xlsx, dir_to_save = NULL) {
  if (is.null(dir_to_save)) {
    dir_to_save <- "data/temp"
    if (fs::dir_exists(dir_to_save)) {
      fs::dir_create("data/temp/extracted_sheets")
      dir_to_save <- "data/temp/extracted_sheets"
    } else {
      usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs()`")
    }
  }
  if (!fs::dir_exists(dir_to_save)) {
    usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs('{ui_field(dir_to_save)}')` before.")
  }

  path_to_xlsx %>%
    readxl::excel_sheets(path = .) %>%
    purrr::set_names() %>%
    purrr::map(read_sheet_then_save_csv, path_to_xlsx = path_to_xlsx, dir_to_save = dir_to_save)
}
