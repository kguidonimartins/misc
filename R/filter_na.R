#' Easily filter NA values from data frames
#'
#' @description
#' `filter_na()` just wrap `{dplyr}` functions in a more
#' convenient way, IMO.
#'
#' @param data a data frame or tibble
#'
#' @param type a character vector indicating which type of NA-filtering must be done. If type = "any",
#' `filter_na()` will filter any NA values present in the data frame. If type = "all", `filter_na` will
#' filter only rows which all columns has NA values.
#'
#' @return a tibble object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' nice_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
#' nice_data %>%
#'   filter_na("all")
#' nice_data %>%
#'   filter_na("any")
#' }
filter_na <- function(data, type = c("any", "all")) {
  if (type == "any") {
    data_filter <-
      data %>%
      dplyr::filter(dplyr::if_any(tidyselect::everything(), ~ is.na(.x)))
  }
  if (type == "all") {
    data_filter <-
      data %>%
      dplyr::filter(dplyr::if_all(tidyselect::everything(), ~ is.na(.x)))
  }

  return(data_filter)

}
