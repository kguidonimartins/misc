#' Load multiple CRAN and GitHub R packages
#'
#' @description
#' Attaches packages that are already installed. Names that are not found on
#' the library search path are reported with suggested
#' `install.packages()` or `remotes::install_github()` calls to run yourself;
#' this function does not install packages (CRAN policy).
#'
#' @param pkg_list A character vector of package names. GitHub sources use
#'   `"user/repo"`; the installed package name is the repository name (see
#'   [basename()]).
#' @param force_cran Logical. Ignored (retained for backwards compatibility;
#'   this function does not install or update packages).
#' @param force_github Logical. Ignored (retained for backwards compatibility).
#'
#' @returns A `data.frame` with columns `pkg_name` (character), `success`
#'   (logical: whether [require()] attached the package), and `version`
#'   (character, `NA` when not loaded). Returned invisibly; summaries are
#'   printed via [print()] on subsets when rows exist.
#'
#' @importFrom usethis ui_info ui_oops
#' @importFrom utils packageVersion
#'
#' @export
#'
#' @section Acknowledgment:
#' `ipak()` was first developed by
#' \href{https://github.com/stevenworthington}{Steven Worthington} and made
#' publicly available
#' \href{https://gist.github.com/stevenworthington/3178163}{here}. This version
#' only loads packages and suggests install commands for missing ones.
#'
#' @examples
#' \donttest{
#' pkg_list <- c("utils", "stats") # base packages — usually present
#' ipak(pkg_list)
#' }
ipak <- function(pkg_list, force_cran = FALSE, force_github = FALSE) {
  force_cran
  force_github

  pkg_list <- unique(pkg_list)

  has_tidy <- grepl(pattern = "tidyverse", x = pkg_list)
  if (sum(has_tidy) >= 1) {
    pkg_list <- pkg_list[!pkg_list %in% "tidyverse"]
    pkg_list <- c(
      pkg_list,
      c("ggplot2", "tibble", "tidyr", "readr", "purrr", "dplyr", "stringr", "forcats")
    )
  }

  pkg_installed <- function(nm) {
    nzchar(system.file(package = nm))
  }

  resolve_row <- function(entry) {
    is_gh <- grepl("/", entry, fixed = TRUE)
    pkg_name <- basename(entry)
    if (!pkg_installed(pkg_name)) {
      if (is_gh) {
        message(
          "Package '", pkg_name, "' is not installed. Install the GitHub repo with:\n",
          "  remotes::install_github(\"", entry, "\")"
        )
      } else {
        message(
          "Package '", pkg_name, "' is not installed. Install from CRAN with:\n",
          "  install.packages(\"", pkg_name, "\", repos = \"https://cloud.r-project.org\")"
        )
      }
      return(data.frame(pkg_name = pkg_name, success = FALSE, version = NA_character_))
    }
    ok <- suppressPackageStartupMessages(
      require(pkg_name, quietly = TRUE, character.only = TRUE)
    )
    ver <- if (ok) {
      tryCatch(
        as.character(packageVersion(pkg_name)),
        error = function(e) NA_character_
      )
    } else {
      NA_character_
    }
    data.frame(pkg_name = pkg_name, success = ok, version = ver)
  }

  pkg_info <- do.call(rbind, lapply(pkg_list, resolve_row))
  rownames(pkg_info) <- NULL

  success <- pkg_info[pkg_info$success == TRUE, , drop = FALSE]
  fail <- pkg_info[pkg_info$success == FALSE, , drop = FALSE]

  if (nrow(success) > 0) {
    usethis::ui_info("Successfully loaded:")
    print(success[, c("pkg_name", "version"), drop = FALSE], row.names = FALSE)
  }

  if (nrow(fail) > 0) {
    usethis::ui_oops("Failed to load:")
    print(fail[, c("pkg_name", "version"), drop = FALSE], row.names = FALSE)
  }

  invisible(pkg_info)
}
