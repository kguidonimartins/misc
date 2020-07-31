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
