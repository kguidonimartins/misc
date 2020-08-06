#' Create directories
#'
#' @description
#' The main purpose of `create_dirs()` is to create default directories used
#' in data science projects. `create_dirs()` can also create custom
#' directories.
#'
#' @param dirs a character vector with the directory names. Default is NULL and
#'   create `data/{raw,clean,temp}`, `output/{figures,results,supp}`,
#'   and `R`
#'
#' @importFrom fs dir_exists dir_create file_create
#' @importFrom usethis ui_todo ui_done ui_info
#' @importFrom here here
#'
#' @section Goal:
#' There is a somewhat subjective discussion about the ideal directory structure
#' for data science projects in general (see
#' [here](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424),
#' [here](https://drivendata.github.io/cookiecutter-data-science/),
#' [here](https://link.springer.com/article/10.1007/s10816-015-9272-9), and
#' [here](https://peerj.com/preprints/3192v1/)). In my humble opinion, the
#' decision should be made by the user/analyst/scientist/team. Here, I
#' suggest a directory structure that has worked for me. In addition, the
#' directory structure created fits perfectly with functions present in this
#' package (for example \code{\link{save_plot}} and \code{\link{save_temp_data}}).
#' Below is the *suggested* directory structure:
#' ```
#' .
#' ├── R           # local functions
#' ├── data
#' │   ├── clean   # stores clean data
#' │   ├── raw     # stores raw data (read-only)
#' │   └── temp    # stores temporary data
#' └── output
#'     ├── figures # stores figures ready for publication/presentation
#'     ├── results # stores text results and others
#'     └── supp    # stores supplementary material for publication/presentation
#' ```
#'
#' @section Acknowledgment:
#' `create_dirs()` takes advantage of the functions available in the excellent
#' [`{fs}`](https://github.com/r-lib/fs) package.
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
