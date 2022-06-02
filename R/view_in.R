check_avail <- function(bin) {
  if (.Platform$OS.type == "windows") {
    stop("Windows platform is not supported yet! Sorry :(")
  }

  if (Sys.which(bin) == "") {
    stop(paste0("Make sure you have `", bin, "` installed in your system!"))
  }
}

#' Alternative data.frame viewer
#'
#' @description
#' `view_in()` is an alternative to `View()` function when not using
#' RStudio. To date, it works with gnumeric, libreoffice and tad.
#' @param data a data.frame/tibble data format.
#' @param viewer character app to open the csv file.
#' @importFrom readr write_csv
#' @return None
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#' mtcars %>%
#'   view_in()
#' }
view_in <- function(data, viewer = c("libreoffice", "gnumeric", "tad")) {
  viewer <- match.arg(viewer)
  check_avail(viewer)
  tmp <- paste0(tempfile(), ".csv")
  readr::write_csv(data, tmp)
  system(paste0(viewer, " ", tmp, " > /dev/null 2>&1 &"))
}
