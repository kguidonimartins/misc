#' Vizualize NA frequency in data
#'
#' @param data a data frame
#'
#' @return a ggplot object
#'
#' @importFrom naniar vis_miss
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
