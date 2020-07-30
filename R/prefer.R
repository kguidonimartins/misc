#' Defines preferred functions from conflicts between namespaces
#'
#' @param pkg_name a atomic vector with package names
#' @param quiet If warnings should be displayed. Default is TRUE
#'
#' @importFrom conflicted conflict_prefer
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
