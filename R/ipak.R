#' Install and load multiple R packages
#'
#' @param pkg_list A character vector with the package names
#'
#' @importFrom utils installed.packages install.packages
#'
#' @return None
#'
#' @importFrom utils download.file install.packages installed.packages
#'
#' @export
#'
#' @examples
#' \dontrun{
#' pkg_list <- c("vegan", "ggplot2")
#' ipak(pkg_list)
#' }
ipak <- function(pkg_list) {
  new_pkg <- pkg_list[!(pkg_list %in% utils::installed.packages()[, "Package"])]
  if (length(new_pkg)) {
    utils::install.packages(new_pkg, dependencies = TRUE)
  }
  sapply(X = pkg_list, FUN = require, quietly = TRUE, character.only = TRUE)
}
