# Origin: adapted from nngeo::st_remove_holes(), MIT License, copyright
# 2023 Michael Dorman. See https://github.com/michaeldorman/nngeo.

#' Remove holes from polygon geometries
#'
#' Removes polygon holes from an `sf`, `sfc`, or `sfg` object. With a positive
#' `max_area`, only holes smaller than the threshold are removed.
#'
#' @param x An `sf`, `sfc`, or `sfg` object of type `POLYGON` or
#'   `MULTIPOLYGON`.
#' @param max_area Maximum area of holes to remove, in the units of `x` (or
#'   square metres for geographic coordinates). Default `0` removes all holes.
#' @return An object of the same class as `x`, with selected holes removed.
#' @references Adapted from the StackOverflow answer by user `lbusett`:
#'   <https://stackoverflow.com/questions/52654701/removing-holes-from-polygons-in-r-sf>.
#' @note For a faster alternative when `max_area` is unnecessary, see
#'   `sfheaders::sf_remove_holes()`:
#'   <https://github.com/dcooley/sfheaders>.
#' @section Acknowledgment:
#' This implementation is adapted from
#' [`nngeo::st_remove_holes()`](https://github.com/michaeldorman/nngeo),
#' written by Michael Dorman and distributed under the MIT License.
#' @importFrom sf st_area st_cast st_combine st_crs st_geometry st_is
#' @importFrom sf st_multipolygon st_polygon st_sfc st_sf st_set_geometry
#' @family geo-tools
#' @export
remove_geom_holes <- function(x, max_area = 0) {
  is_polygon <- tryCatch(
    all(sf::st_is(x, "POLYGON") | sf::st_is(x, "MULTIPOLYGON")),
    error = function(e) FALSE
  )
  if (!is_polygon) {
    stop(
      "`x` must be a POLYGON or MULTIPOLYGON sf/sfc/sfg object.",
      call. = FALSE
    )
  }
  if (!is.numeric(max_area) || length(max_area) != 1L || is.na(max_area) ||
    max_area < 0) {
    stop("`max_area` must be a non-negative numeric scalar.", call. = FALSE)
  }

  geometry_is_polygon <- all(sf::st_is(x, "POLYGON"))
  type_is_sfg <- inherits(x, "sfg")
  type_is_sf <- inherits(x, "sf")
  geom <- sf::st_geometry(x)
  if (type_is_sfg) {
    has_holes <- if (sf::st_is(x, "POLYGON")) {
      length(x) > 1L
    } else {
      any(vapply(x, function(part) length(part) > 1L, logical(1)))
    }
    if (!has_holes) {
      return(x)
    }
  }
  if (type_is_sf) {
    dat <- sf::st_set_geometry(x, NULL)
  }

  for (i in seq_len(length(geom))) {
    if (sf::st_is(geom[i], "POLYGON")) {
      rings <- geom[i][[1L]]
      if (length(rings) > 1L) {
        if (max_area > 0) {
          holes <- lapply(rings[-1L], function(ring) sf::st_polygon(list(ring)))
          holes <- lapply(holes, function(hole) {
            sf::st_sfc(hole, crs = sf::st_crs(x))
          })
          areas <- c(Inf, vapply(holes, function(hole) {
            as.numeric(sf::st_area(hole))
          }, numeric(1)))
          geom[i] <- sf::st_polygon(rings[which(areas > max_area)])
        } else {
          geom[i] <- sf::st_polygon(rings[1L])
        }
      }
    }
    if (sf::st_is(geom[i], "MULTIPOLYGON")) {
      parts <- geom[i][[1L]]
      parts <- lapply(parts, function(rings) {
        if (length(rings) <= 1L) {
          return(rings)
        }
        if (max_area > 0) {
          holes <- lapply(rings[-1L], function(ring) sf::st_polygon(list(ring)))
          holes <- lapply(holes, function(hole) {
            sf::st_sfc(hole, crs = sf::st_crs(x))
          })
          areas <- c(Inf, vapply(holes, function(hole) {
            as.numeric(sf::st_area(hole))
          }, numeric(1)))
          rings[which(areas > max_area)]
        } else {
          rings[1L]
        }
      })
      geom[i] <- sf::st_multipolygon(parts)
    }
  }

  if (geometry_is_polygon && !type_is_sfg) {
    geom <- sf::st_cast(geom, "POLYGON")
  }
  if (type_is_sfg) {
    geom <- geom[[1L]]
  }
  if (type_is_sf) {
    geom <- sf::st_set_geometry(dat, geom)
    sf_column <- attr(x, "sf_column")
    names(geom)[names(geom) == "geometry"] <- sf_column
    attr(geom, "sf_column") <- sf_column
  }
  geom
}
