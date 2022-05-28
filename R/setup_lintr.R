#' Setup a config file for static code analysis
#'
#' @description
#' This function create a config file (`.lintr`) in root of the user's project
#' based on static code analysis performed by the `{lintr}.
#'
#' @details
#' `setup_lint` creates a file (`.lintr`) in the root of the user project,
#' which lists and counts the warnings, syntax errors, and possible semantic
#' issues provided by the static code analysis of the `{lintr}`. In the current
#' form (i.e., right after its creation), the `.lintr` file will block all the
#' problems and hints founded by the static code analysis. Users need to edit
#' the file manually, changing the variable values from NULL to the value used
#' by each type of linter listed. For example, the default value of the
#' `line_length_linter` linter is 80, but users can change it to 120. Please,
#' check the [README](https://github.com/jimhester/lintr/blob/master/README.md)
#' of the `{lintr}` for further information.
#'
#' @param exclude_file character a character vector containing the files that
#' should be excluded from static code analysis.
#' @param exclude_path character a character vector containing the paths that
#' should be excluded from static code analysis.
#'
#' @return none
#'
#' @importFrom dplyr tally group_by
#' @importFrom magrittr %$%
#' @importFrom rlang is_empty
#'
#' @export
#'
#' @examples
#' \dontrun{
#' setup_lintr(exclude_file = "manuscript.Rmd", exclude_path = c("data", "sources"))
#' }
setup_lintr <- function(exclude_file = NULL, exclude_path = NULL) {

  check_require("lintr")

  if (is.null(exclude_file)) {
    exclude_file <- c()
  }

  exclude_path_list <- list()

  for (i in seq_along(exclude_path)) {
    exclude_path_list[[i]] <- list.files(exclude_path[i], recursive = TRUE, full.names = TRUE)    # print(exclude_paths)
  }

  exclude_all <- unique(unlist(c(exclude_file, exclude_path_list)))

  lint_file <- ".lintr"

  # Make sure we start fresh
  if (file.exists(lint_file)) {
    file.remove(lint_file)
  }

  checks <-
    lintr::lint_package() %>%
    as.data.frame %>%
    dplyr::group_by(linter) %>%
    dplyr::tally(sort = TRUE) %$%
    sprintf("linters: linters_with_defaults(\n    %s\n    dummy_linter = NULL\n  )\n",
            paste0(linter, " = NULL, # ", n, collapse = "\n    "))

  sink(".lintr")
  cat(checks)
  sink()

  if (!rlang::is_empty(exclude_all)) {

    excls <-
      sprintf("exclusions: list(\n    %s\n  )\n",
              paste0('"', exclude_all, '"', collapse = ",\n    "))

    sink(".lintr", append = TRUE)
    cat(excls)
    sink()

  }

}
