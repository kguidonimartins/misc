#' Read an excel sheet and save it to a CSV file
#'
#' @param excel_sheet a character vector with the name of the excel sheet
#' @param path_to_xlsx a character vector with the path of the excel file
#' @param dir_to_save a character vector with the path to save the csv file.
#'   Default is NULL and save the csv in the "data/temp" if it exists.
#' @param range A cell range to read from. Includes typical Excel ranges like
#'   "B3:D87".
#' @param col_types Either NULL to guess all from the spreadsheet or a character
#'   vector containing one entry per column from these options: "skip", "guess",
#'   "logical", "numeric", "date", "text" or "list". If exactly one col_type is
#'   specified, it will be recycled.
#' @param col_names TRUE to use the first row as column names
#' @param na Character vector of strings to interpret as missing values. By
#'   default, treats blank cells as missing data.
#' @param trim_ws Should leading and trailing whitespace be trimmed?
#' @param skip Minimum number of rows to skip before reading anything, be it
#'   column names or data.
#' @param n_max Maximum number of data rows to read.
#' @param guess_max Maximum number of data rows to use for guessing column
#'   types.
#' @param .name_repair Handling of column names
#'
#' @export
#'
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
#' xlsx_file <-
#'   system.file("xlsx-examples", "mtcars_workbook_001.xlsx", package = "misc")
#' read_sheet_then_save_csv(
#'   excel_sheet = "mtcars_sheet_001",
#'   path_to_xlsx = xlsx_file,
#'   dir_to_save = "ma-box"
#' )
#' }
read_sheet_then_save_csv <-
  function(
           excel_sheet,
           path_to_xlsx,
           dir_to_save = NULL,
           range = NULL,
           col_types = NULL,
           col_names = TRUE,
           na = "",
           trim_ws = TRUE,
           skip = 0,
           n_max = Inf,
           guess_max = min(1000, n_max),
           .name_repair = "unique") {
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
        readxl::read_excel(
          path = .,
          sheet = excel_sheet,
          range = range,
          col_types = col_types,
          col_names = col_names,
          na = na,
          trim_ws = trim_ws,
          skip = skip,
          n_max = n_max,
          guess_max = guess_max,
          .name_repair = .name_repair
        ) %>%
        janitor::clean_names(dat = ., case = "snake") %>%
        readr::write_csv(x = ., path = filename_to_save)
      usethis::ui_done("{usethis::ui_field(here::here(filename_to_save))} saved!")
    } else {
      usethis::ui_info("File {usethis::ui_field(here::here(filename_to_save))} already exists!")
    }
  }


#' Read and save into csv files all the sheets in a excel file
#'
#' @param path_to_xlsx a character vector with path to the excel file
#' @param dir_to_save a character vector with the path to save the csv files.
#'   Default is NULL and save the csv files in the "data/temp/extracted_sheets"
#'   if it exists.
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


#' Read all sheets from all excel files and save into csv files
#'
#' @param path_to_xlsx a character vector with the path to excel file
#'
#' @importFrom fs dir_ls
#' @importFrom purrr map
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # read and into a csv
#' xlsx_dir <- system.file("xlsx-examples", package = "misc")
#' read_all_xlsx_then_save_csv(
#'   path_to_xlsx = xlsx_dir
#' )
#' }
#'
read_all_xlsx_then_save_csv <- function(path_to_xlsx) {
  path_to_xlsx %>%
    fs::dir_ls(regexp = "\\.xls*") %>%
    purrr::map(~ read_all_sheets_then_save_csv(.x))
}
