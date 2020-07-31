#' Read a excel sheet and save into a csv file
#'
#' @param excel_sheet a character vector with the name of the excel sheet
#' @param path_to_xlsx a character vector with the path of the excel file
#' @param dir_to_save a character vector with the path to save the csv file. Default is NULL and save the csv in the "data/temp" if it exists.
#'
#' @export
#' @importFrom fs dir_exists dir_create file_exists
#' @importFrom here here
#' @importFrom janitor make_clean_names clean_names
#' @importFrom readr write_csv
#' @importFrom readxl read_excel
#' @importFrom stringr str_replace_all str_to_lower
#' @importFrom textclean replace_non_ascii
#' @importFrom tools file_path_sans_ext
#' @importFrom usethis ui_stop ui_field ui_todo ui_done ui_info
#'
#' @examples
#' \dontrun{
#' # read and into a csv
#' misc::create_dirs("ma-box")
#' xlsx_file <- system.file("xlsx-examples", "mtcars_workbook_001.xlsx", package = "misc")
#' read_sheet_then_save_csv(
#'   excel_sheet = "mtcars_sheet_001",
#'   path_to_xlsx = xlsx_file,
#'   dir_to_save = "ma-box"
#' )
#' }
read_sheet_then_save_csv <- function(excel_sheet, path_to_xlsx, dir_to_save = NULL) {
  if (is.null(dir_to_save)) {
    dir_to_save <- "data/temp"
    if (!fs::dir_exists(dir_to_save)) {
      usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs()`")
    }
  }
  if (!fs::dir_exists(dir_to_save)) {
    usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs('{ui_field(dir_to_save)}')` before.")
  }

  pathbase <- path_to_xlsx %>%
    basename() %>%
    tools::file_path_sans_ext(.) %>%
    stringr::str_replace_all(., " ", "_") %>%
    textclean::replace_non_ascii(.) %>%
    stringr::str_to_lower(.) %>%
    janitor::make_clean_names(.)

  subdir_store <- paste(dir_to_save, pathbase, sep = "/")

  if (!fs::dir_exists(subdir_store)) {
    usethis::ui_todo("Creating {usethis::ui_field(here::here(subdir_store))}...")
    fs::dir_create(subdir_store)
    usethis::ui_done("{usethis::ui_field(here::here(subdir_store))} created!")
  } else {
    usethis::ui_info("Directory {usethis::ui_field(here::here(subdir_store))} already exists!")
  }

  sheet_name <-
    excel_sheet %>%
    textclean::replace_non_ascii(.) %>%
    stringr::str_to_lower(.) %>%
    janitor::make_clean_names(.)

  filename_to_save <-
    paste0(subdir_store, "/", pathbase, "_", sheet_name, ".csv")

  if (!fs::file_exists(filename_to_save)) {
    usethis::ui_todo("Saving {usethis::ui_field(here::here(filename_to_save))}...")
    path_to_xlsx %>%
      readxl::read_excel(path = ., sheet = excel_sheet) %>%
      janitor::clean_names(dat = ., case = "snake") %>%
      readr::write_csv(x = ., path = filename_to_save)
    usethis::ui_done("{usethis::ui_field(here::here(filename_to_save))} saved!")
  } else {
    usethis::ui_info("File {usethis::ui_field(here::here(filename_to_save))} already exists!")
  }
}
