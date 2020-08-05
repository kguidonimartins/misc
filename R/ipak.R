#' Install and load multiple CRAN and github R packages
#'
#' @param pkg_list A character vector with the package names. Github packages needs to be listed as usual: "username/repo"
#' @param force_cran logical. If force the installation of cran packages
#' @param force_github logical. If force the installation of github packages
#'
#' @importFrom crayon green blue red
#' @importFrom remotes install_github
#' @importFrom usethis ui_todo ui_code ui_done ui_info ui_oops
#' @importFrom utils install.packages installed.packages packageVersion
#'
#' @return None
#'
#' @export
#'
#' @examples
#' \dontrun{
#' pkg_list <- c("vegan", "ggplot2", "trinker/textclean", "jalvesaq/colorout")
#' ipak(pkg_list)
#' }
ipak <- function(pkg_list, force_cran = FALSE, force_github = FALSE) {
  pkg_list <- unique(pkg_list)

  pkg_list_github <- pkg_list[grep(pattern = "/", x = pkg_list)]
  pkg_list_cran <- pkg_list[!pkg_list %in% pkg_list_github]

  install_gh <- function(new_pkg_github, force = FALSE) {
    usethis::ui_todo("Installing github packages {usethis::ui_code(new_pkg_github)}")
    remotes::install_github(new_pkg_github, dependencies = TRUE, force = force)
    usethis::ui_done("{usethis::ui_code(new_pkg_github)} installed!")
  }

  install_cran <- function(new_pkg_cran) {
    usethis::ui_todo("Installing cran packages {usethis::ui_code(new_pkg_cran)}")
    utils::install.packages(new_pkg_cran, dependencies = TRUE, repos = "https://cloud.r-project.org")
    usethis::ui_done("{usethis::ui_code(new_pkg_cran)} installed!")
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
      cat(" -", paste0(crayon::green(success$pkg_name[i]), " (", crayon::blue(success$version[i]), ")"), "\n")
    }
  }

  if (length(fail$pkg_name)) {
    usethis::ui_oops("Fail to load:")
    for (i in seq_along(fail$pkg_name)) {
      cat(" -", paste0(crayon::red(fail$pkg_name[i]), " (", crayon::blue(fail$version[i]), ")"), "\n")
    }
  }
}
