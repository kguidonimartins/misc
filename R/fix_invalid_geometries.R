#' Fix invalid geometries in an sf object
#'
#' Detects invalid geometries with [sf::st_is_valid()], reports them, and
#' repairs the layer with [sf::st_make_valid()].
#'
#' @param data An [sf::sf] object.
#'
#' @details
#' Rows with invalid geometries are reported via `message()` before
#' [sf::st_make_valid()] is applied to the whole layer. Warnings emitted by
#' the repair itself are suppressed. Geometries that become empty after the
#' repair are kept and flagged with a `warning()` naming the affected rows.
#' When every geometry is already valid, `data` is returned unchanged and no
#' repair is attempted.
#'
#' @return An [sf::sf] object with the same attributes and geometry column
#'   name as `data`, with invalid geometries repaired.
#'
#' @importFrom sf st_is_valid st_make_valid st_is_empty
#'
#' @family geo-tools
#'
#' @export
#'
#' @examples
#' \donttest{
#' crs_pl <- sf::st_crs(3857)
#' bowtie <- matrix(
#'   c(0, 0, 1e5, 0, 0, 1e5, 1e5, 1e5, 0, 0),
#'   ncol = 2L,
#'   byrow = TRUE
#' )
#' x <- sf::st_sf(
#'   id = "bowtie",
#'   geometry = sf::st_sfc(sf::st_polygon(list(bowtie)), crs = crs_pl)
#' )
#' fix_invalid_geometries(x)
#' }
fix_invalid_geometries <- function(data) {
  if (!inherits(data, "sf")) {
    stop("`data` must be an sf object.", call. = FALSE)
  }

  valid <- sf::st_is_valid(data)
  valid[is.na(valid)] <- FALSE

  if (all(valid)) {
    message("[INFO] `{misc}`: All geometries are valid; nothing to fix.")
    return(data)
  }

  invalid_rows <- which(!valid)
  n_invalid <- length(invalid_rows)
  message(
    "[INFO] `{misc}`: ", n_invalid, " invalid geometr",
    if (n_invalid == 1L) "y" else "ies",
    " at row", if (n_invalid == 1L) "" else "s", " ",
    paste(invalid_rows, collapse = ", "),
    ". Applying sf::st_make_valid()..."
  )

  fixed <- suppressWarnings(sf::st_make_valid(data))

  newly_empty <- sf::st_is_empty(fixed) & !sf::st_is_empty(data)
  if (any(newly_empty)) {
    empty_rows <- which(newly_empty)
    warning(
      "[WARNING] `{misc}`: Geometry at row(s) ",
      paste(empty_rows, collapse = ", "),
      " became empty after sf::st_make_valid().",
      call. = FALSE
    )
  }

  fixed
}
