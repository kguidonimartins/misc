#' Add a gitignore file to the project root
#'
#' @description
#' `add_gitignore()` fetch files using the API from
#' [gitignore.io](https://www.toptal.com/developers/gitignore). Also,
#' `add_gitignore()` include `tags` (created by
#' [ctags](https://github.com/universal-ctags/ctags)) into the gitignore file.
#'
#' @param type a character vector with the language to be ignored
#'
#' @returns No return value, called for side effects (creates `.gitignore`, or
#'   stops with an error if the file already exists).
#'
#' @importFrom fs file_exists
#' @importFrom here here
#' @importFrom usethis ui_info ui_field ui_stop ui_todo ui_done
#' @importFrom utils download.file
#'
#' @export
#'
#' @section Acknowledgment:
#' `add_gitignore()` is inspired by
#' [`gitignore::gi_fetch_templates`](https://github.com/ropensci/gitignore/blob/master/R/gi_fetch_templates.R)
#' and by some examples on the gitignore.io
#' [wiki page](https://github.com/toptal/gitignore.io/wiki/Advanced-Command-Line).
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   # Downloads from gitignore.io (requires network). Use combined `type` on
#'   # first create, e.g. `add_gitignore(type = c("r", "python"))`.
#'   add_gitignore()
#' }
#' }
add_gitignore <- function(type = "r") {
  file_wanted <- ".gitignore"
  URL_base <- "https://www.toptal.com/developers/gitignore/api/"
  type <- paste(unique(type), collapse = ",")
  URL_wanted <- paste0(URL_base, type)
  if (fs::file_exists(file_wanted)) {
    usethis::ui_info("{usethis::ui_field(here::here(file_wanted))} already exists! Check it content below:")
    file_conn <- file(file_wanted, open = "r")
    file_lines <- readLines(file_conn)
    close(file_conn)
    message(paste(file_lines, collapse = "\n"))
    usethis::ui_stop("{usethis::ui_field(here::here(file_wanted))} not created!")
  } else {
    usethis::ui_todo("Creating {usethis::ui_field(here::here(file_wanted))}...")
    utils::download.file(url = URL_wanted, destfile = file_wanted)
    write("tags", file = file_wanted, append = TRUE)
    usethis::ui_done("{usethis::ui_field(here::here(file_wanted))} saved!")
  }
}
