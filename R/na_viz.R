#' Visualize NA frequency in data
#'
#' @description
#' `na_viz()` create a ggplot plot showing the percentage of NA in each column
#'
#' @param data a data frame
#'
#' @return a ggplot object
#'
#' @section Acknowledgment:
#' `na_viz()` is another name for the excellent `vis_miss()` of
#' [`{naniar}`](https://github.com/njtierney/naniar)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' na_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
#' na_data %>% na_viz()
#' }
na_viz <- function(data) {
  check_require("naniar")
  data %>%
    naniar::vis_miss(x = .)
}
