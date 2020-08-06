#' Visualize NA frequency in data
#'
#' @description
#' `na_viz()` create a ggplot plot showing the percentage of NA in each column
#'
#' @param data a data frame
#'
#' @return a ggplot object
#'
#' @importFrom naniar vis_miss
#'
#' @section Acknowledgment:
#' `na_viz()` is another name for the excellent `naniar::vis_miss()` function
#'
#' @export
#'
#' @examples
#' \dontrun{
#' na_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
#' na_data %>% na_viz()
#' }
na_viz <- function(data) {
  data %>%
    naniar::vis_miss(x = .)
}
