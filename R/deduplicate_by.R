#' Remove duplicate rows based on specified grouping variables
#'
#' @description
#' This function removes duplicate rows from a data frame while keeping the first
#' occurrence of each unique combination of the specified grouping variables.
#'
#' @param .data A data frame or tibble
#' @param ... One or more unquoted variable names to group by
#'
#' @return A data frame with duplicate rows removed, keeping only the first
#'         occurrence for each unique combination of grouping variables
#'
#' @examples
#' \donttest{
#' # Remove duplicates based on a single column
#' mtcars %>% deduplicate_by(carb)
#'
#' # Remove duplicates based on multiple columns
#' mtcars %>% deduplicate_by(carb, mpg)
#' }
#'
#' @importFrom rlang enquos
#' @importFrom dplyr group_by filter row_number ungroup
#' @export
deduplicate_by <- function(.data, ...) {
  group_vars <- rlang::enquos(...)
  .data %>%
    dplyr::group_by(!!! group_vars) %>%
    dplyr::filter(dplyr::row_number() == 1) %>%
    dplyr::ungroup()
}
