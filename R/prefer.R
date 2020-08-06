#' Defines preferred package::functions
#'
#' @description
#' The most common conflict between `{tidyverse}` users is `dplyr::filter()` and
#' `stats::filter()`; among `{raster}` users, the conflict is with
#' `dplyr::select()`. `prefer()` eliminates conflicts between namespaces by
#' forcing the use of all the functions of the chosen package, rather than
#' looking for specific conflicts. Because of that and depending on the number
#' of functions exported by a package, `prefer()` can be slow.
#'
#' @param pkg_name a atomic vector with package names
#' @param quiet If warnings should be displayed. Default is TRUE
#'
#' @importFrom conflicted conflict_prefer
#'
#' @section Acknowledgment:
#' `prefer()` is shamelessly derived from a piece of code in
#' [README.md](https://github.com/elbersb/tidylog/blob/master/README.md#namespace-conflicts)
#' of the [`{tidylog}`](https://github.com/elbersb/tidylog)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # prefer `{dplyr}` functions over `{stats}`
#' prefer("dplyr")
#' }
prefer <- function(pkg_name, quiet = TRUE) {
  for (pkg in seq_along(pkg_name)) {
    for (func in getNamespaceExports(pkg_name[pkg])) {
      conflicted::conflict_prefer(name = func, winner = pkg_name[pkg], quiet = quiet)
    }
  }
}
