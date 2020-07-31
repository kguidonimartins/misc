#' Save objects as a RDS file
#'
#' @param object R object
#' @param dir_to_save a character vector with the directory name. Default is NULL and save object in the "data/temp" if it exists.
#'
#' @importFrom fs dir_exists file_exists
#' @importFrom here here
#' @importFrom usethis ui_stop ui_field ui_todo ui_done ui_info
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # create and save a R object
#' awesome <- "not to much!"
#' misc::create_dirs("ma-box")
#' save_temp_data(object = awesome, dir_to_save = "ma-box")
#' # using default directories from `misc::create_dirs()`
#' create_dirs()
#' so_good <- "Yep!"
#' save_temp_data(object = so_good)
#' }
save_temp_data <- function(object, dir_to_save = NULL) {
  obj_name <- deparse(substitute(object))
  if (is.null(dir_to_save)) {
    dir_to_save <- "data/temp"
    if (!fs::dir_exists(dir_to_save)) {
      usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs()`")
    }
  }
  if (!fs::dir_exists(dir_to_save)) {
    usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs('{ui_field(dir_to_save)}')` before.")
  }
  name_to_save <- paste0(dir_to_save, "/", obj_name, ".rds")
  if (!fs::file_exists(name_to_save)) {
    usethis::ui_todo("Saving {usethis::ui_field(here::here(name_to_save))}...")
    saveRDS(object = object, file = name_to_save)
    usethis::ui_done("{usethis::ui_field(here::here(name_to_save))} saved!")
  } else {
    usethis::ui_info("File {usethis::ui_field(here::here(name_to_save))} already exists!")
  }
}
