#' Describe data
#'
#' @param data a data frame
#'
#' @return a skimr object
#'
#' @importFrom skimr skim
#'
#' @export
#'
#' @examples
#' \dontrun{
#' nice_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
#' nice_data %>%
#'   describe_data()
#' }
describe_data <- function(data) {
  data %>%
    skimr::skim()
}
