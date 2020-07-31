#' Create data, output and R directories
#'
#' @param dirs a character vector with the directory names. Default is NULL and create `data/raw`, `data/clean`, `data/temp`, `output/figures`, `output/results`, `output/supp`, and `R`
#'
#' @importFrom fs dir_exists dir_create file_create
#' @importFrom usethis ui_todo ui_done ui_info
#' @importFrom here here
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # create a single directory
#' create_dirs("myfolder")
#' # create the default directories
#' create_dirs()
#' # see the resulting tree
#' fs::dir_tree()
#' }
create_dirs <- function(dirs = NULL) {
  core <- function(vec) {
    for (d in seq_along(dirs)) {
      if (!fs::dir_exists(dirs[d])) {
        usethis::ui_todo("Creating {usethis::ui_field(here::here(dirs[d]))}...")
        fs::dir_create(dirs[d])
        fs::file_create(dirs[d], ".gitkeep")
        usethis::ui_done("{usethis::ui_field(here::here(dirs[d]))} created!")
      } else {
        usethis::ui_info("File {usethis::ui_field(here::here(dirs[d]))} already exists!")
      }
    }
  }
  if (is.null(dirs)) {
    dirs_data <- c("data/raw", "data/clean", "data/temp")
    dirs_output <- c("output/figures", "output/results", "output/supp")
    dir_r <- "R"
    dirs <- c(dirs_data, dirs_output, dir_r)
    core(dirs)
  } else {
    core(dirs)
  }
}
