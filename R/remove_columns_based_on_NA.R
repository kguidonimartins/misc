#' Remove columns based on NA values
#'
#' @param data A data frame or tibble
#' @param threshold The proportion of NA values allowed in a column (default: 0.5)
#' @return A data frame with columns removed if they have more than the specified threshold of NA values
#' @export
#'
#' @importFrom dplyr select where
#'
#' @examples
#' # Create sample data frame with NA values
#' df <- data.frame(
#'   a = c(1, 2, NA, 4, 5),
#'   b = c(NA, NA, NA, 4, 5),
#'   c = c(1, 2, 3, NA, 5)
#' )
#'
#' # Remove columns with more than 50% NA values
#' remove_columns_based_on_NA(df)
#'
#' # Use stricter threshold of 10% NA values
#' remove_columns_based_on_NA(df, threshold = 0.1)
remove_columns_based_on_NA <- function(data, threshold = 0.5) {
  data %>%
    dplyr::select(dplyr::where(~ sum(is.na(.)) / length(.) <= threshold))
}
