#' Install and load multiple CRAN and github R packages
#'
#' @description
#' \code{ipak()} checks if the package is installed and then loads
#' it. If the package is not installed, then \code{ipak()} installs it and then
#' loads it. \code{ipak()} is capable of handling CRAN and github packages. In
#' addition, the user can update their packages using the \code{force_*()}
#' arguments.
#'
#' @param pkg_list A character vector with the package names. Github packages needs to be listed as usual: \code{"username/repo"}
#' @param force_cran logical. If force the installation of cran packages
#' @param force_github logical. If force the installation of github packages
#'
#' @importFrom crayon green blue red col_align
#' @importFrom remotes install_github
#' @importFrom usethis ui_todo ui_code ui_done ui_info ui_oops
#' @importFrom utils install.packages installed.packages packageVersion
#'
#' @export
#'
#' @section Acknowledgment:
#' \code{ipak()} was first developed by
#' \href{https://github.com/stevenworthington}{Steven Worthington} and made
#' publicly available
#' \href{https://gist.github.com/stevenworthington/3178163}{here}. I've been
#' using this function for years and now I decided to expand it.
#'
#' @examples
#' \dontrun{
#' pkg_list <- c("vegan", "ggplot2", "trinker/textclean", "jalvesaq/colorout")
#' ipak(pkg_list)
#' }
ipak <- function(pkg_list, force_cran = FALSE, force_github = FALSE) {
  pkg_list <- unique(pkg_list)

  has_tidy <- grepl(pattern = "tidyverse", x = pkg_list)

  if (sum(has_tidy) >= 1) {
    pkg_list <- pkg_list[!pkg_list %in% "tidyverse"]
    pkg_list <- c(pkg_list, c("ggplot2", "tibble", "tidyr", "readr", "purrr", "dplyr", "stringr", "forcats"))
  }

  pkg_list_github <- pkg_list[grep(pattern = "/", x = pkg_list)]
  pkg_list_cran <- pkg_list[!pkg_list %in% pkg_list_github]

  install_gh <- function(new_pkg_github, force = FALSE) {
    usethis::ui_todo("Installing github packages: {usethis::ui_code(new_pkg_github)}")
    cat("\n")
    remotes::install_github(new_pkg_github, dependencies = TRUE, force = force)
    cat("\n")
    usethis::ui_done("{usethis::ui_code(new_pkg_github)} installed!")
    cat("\n")
  }

  install_cran <- function(new_pkg_cran) {
    usethis::ui_todo("Installing cran packages: {usethis::ui_code(new_pkg_cran)}")
    cat("\n")
    utils::install.packages(new_pkg_cran, dependencies = TRUE, repos = "https://cloud.r-project.org")
    cat("\n")
    usethis::ui_done("{usethis::ui_code(new_pkg_cran)} installed!")
    cat("\n")
  }

  if (force_github) {
    install_gh(pkg_list_github, force = TRUE)
  }

  if (force_cran) {
    install_cran(pkg_list_cran)
  }

  new_pkg_github <- basename(pkg_list_github)[!(basename(pkg_list) %in% utils::installed.packages()[, "Package"])]

  if (length(new_pkg_github)) {
    install_gh(new_pkg_github, force = FALSE)
  }

  new_pkg_cran <- pkg_list_cran[!(pkg_list_cran %in% utils::installed.packages()[, "Package"])]

  if (length(new_pkg_cran)) {
    install_cran(new_pkg_cran)
  }

  # load packages
  suppressMessages({
    invisible({
      install_message <- sapply(X = basename(pkg_list), FUN = require, quietly = TRUE, character.only = TRUE, USE.NAMES = TRUE)
    })
  })

  pkg_info <- data.frame(pkg_name = names(install_message), success = install_message, version = NA)

  for (i in seq_along(pkg_info$pkg_name)) {
    pkg_info$version[i] <- as.character(utils::packageVersion(pkg_info$pkg_name[i]))
  }

  success <- pkg_info[pkg_info$success == TRUE, ]
  fail <- pkg_info[pkg_info$success == FALSE, ]

  if (length(success$pkg_name)) {
    usethis::ui_info("Successful loaded:")
    for (i in seq_along(success$pkg_name)) {
      cat(" -", paste0(crayon::col_align(crayon::green(success$pkg_name[i]), max(nchar(success$pkg_name))), " (", crayon::blue(success$version[i]), ")"), "\n")
    }
  }

  if (length(fail$pkg_name)) {
    usethis::ui_oops("Fail to load:")
    for (i in seq_along(fail$pkg_name)) {
      cat(" -", paste0(crayon::col_align(crayon::red(fail$pkg_name[i]), max(nchar(fail$pkg_name))), " (", crayon::blue(fail$version[i]), ")"), "\n")
    }
  }
}
