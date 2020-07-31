#' Count NA frequency in data
#'
#' @param data a data frame
#'
#' @return a tibble
#'
#' @importFrom dplyr summarise_all n full_join
#' @importFrom purrr map_df
#' @importFrom tidyr pivot_longer everything
#'
#' @export
#'
#' @examples
#' \dontrun{
#' na_data <- data.frame(c1 = c(1, NA), c2 = c(NA, NA))
#' na_data %>% na_count()
#' }
na_count <- function(data) {
  na_count_data <-
    data %>%
    purrr::map_df(~ sum(is.na(.))) %>%
    tidyr::pivot_longer(
      cols = tidyr::everything(),
      names_to = "variables",
      values_to = "na_count"
    )
  na_percent_data <-
    data %>%
    dplyr::summarise_all(~ round(sum(is.na(.)) / dplyr::n(), digits = 3)) %>%
    tidyr::pivot_longer(
      cols = tidyr::everything(),
      names_to = "variables",
      values_to = "na_percent"
    )

  full_check <- dplyr::full_join(x = na_count_data, y = na_percent_data, by = "variables")

  return(full_check)
}
