#' Keep features that touch a mask layer
#'
#' @description
#' Returns the rows of `x` whose geometries intersect (touch) any geometry in
#' `y`, using [sf::st_intersects()]. No clipping is performed: geometries are
#' returned unchanged. Useful for selecting features inside or crossing a
#' boundary without computing actual geometric intersections.
#'
#' @details
#' A feature is kept when `lengths(st_intersects(x, y))` is greater than zero,
#' i.e. when it shares at least one point with any feature in `y`. This is the
#' lightest-touch selection strategy: it does not reproject, clip, or measure
#' overlap area. Both layers must share the same CRS (or have CRS that
#' [sf::st_intersects()] can reconcile); transform them beforehand if needed.
#'
#' @param x An [sf::sf] object.
#' @param y An [sf::sf] mask layer.
#' @param repair If `TRUE`, apply [sf::st_make_valid()] to `x` and `y` first
#'   (warnings are suppressed per call). Default `TRUE`.
#'
#' @return An [sf::sf] subset of `x` containing only features that touch `y`,
#'   preserving the original geometry and attributes of `x`.
#'
#' @importFrom sf st_intersects st_make_valid
#'
#' @family geo-tools
#'
#' @export
#'
#' @examples
#' \donttest{
#' crs_pl <- sf::st_crs(3857)
#' ring <- matrix(
#'   c(0, 0, 1e6, 0, 1e6, 1e6, 0, 1e6, 0, 0),
#'   ncol = 2L,
#'   byrow = TRUE
#' )
#' y <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = crs_pl))
#' inner <- matrix(
#'   c(1e5, 1e5, 9e5, 1e5, 9e5, 9e5, 1e5, 9e5, 1e5, 1e5),
#'   ncol = 2L,
#'   byrow = TRUE
#' )
#' outside <- matrix(
#'   c(2e6, 2e6, 3e6, 2e6, 3e6, 3e6, 2e6, 3e6, 2e6, 2e6),
#'   ncol = 2L,
#'   byrow = TRUE
#' )
#' x <- sf::st_sf(
#'   id = c("in", "out"),
#'   geometry = sf::st_sfc(
#'     sf::st_polygon(list(inner)),
#'     sf::st_polygon(list(outside)),
#'     crs = crs_pl
#'   )
#' )
#' intersect_filter_touch(x, y)
#' }
intersect_filter_touch <- function(x, y, repair = TRUE) {
  if (!inherits(x, "sf") || !inherits(y, "sf")) {
    stop("`x` and `y` must be sf objects.", call. = FALSE)
  }
  if (repair) {
    x <- suppressWarnings(sf::st_make_valid(x))
    y <- suppressWarnings(sf::st_make_valid(y))
  }
  hits <- lengths(sf::st_intersects(x, y)) > 0L
  x[hits, , drop = FALSE]
}
