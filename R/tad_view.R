#' Alternative data.frame viewer using tad
#'
#' @description
#' `tad_view()` is an alternative to `View()` function when not using
#' RStudio. Please, make sure you have
#' [tad](https://github.com/antonycourtney/tad) installed in your
#' system.
#' @param data a data.frame/tibble data format.
#' @importFrom readr write_csv
#' @return None
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#' mtcars %>%
#'   tad_view()
#' }
tad_view <- function(data) {
  if (Sys.which("tad") == "") {
    stop("Make sure you have tad <https://github.com/antonycourtney/tad> installed!")
  }

  if (!is.data.frame(data)) {
    stop("`tad_view()` only works with data.frame/tibble objects.")
  }

  tmp <- paste0(tempfile(), ".csv")
  readr::write_csv(data, tmp)
  system(paste0("tad ", tmp, " > /dev/null 2>&1 &"))
}
