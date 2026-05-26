# Internal: SIRGAS 2000 Albers equal-area parameters commonly used for Brazil
# (metre units; suitable for area and intersection).
.misc_albers_brazil_wkt <-
  'PROJCS["Conica_Equivalente_de_Albers_Brasil",
    GEOGCS["GCS_SIRGAS2000",
        DATUM["D_SIRGAS2000",
            SPHEROID["Geodetic_Reference_System_of_1980",6378137,298.2572221009113]],
        PRIMEM["Greenwich",0],
        UNIT["Degree",0.017453292519943295]],
    PROJECTION["Albers"],
    PARAMETER["standard_parallel_1",-2],
    PARAMETER["standard_parallel_2",-22],
    PARAMETER["latitude_of_origin",-12],
    PARAMETER["central_meridian",-54],
    PARAMETER["false_easting",5000000],
    PARAMETER["false_northing",10000000],
    UNIT["Meter",1]]'

.misc_check_polygon_sf <- function(obj, label) {
  types <- unique(as.character(sf::st_geometry_type(sf::st_geometry(obj))))
  if (!length(types)) {
    return(invisible(NULL))
  }
  bad <- types[!types %in% c("POLYGON", "MULTIPOLYGON")]
  if (length(bad)) {
    stop(
      sprintf(
        "`%s` must contain only POLYGON or MULTIPOLYGON geometries (found %s).",
        label,
        paste(sort(bad), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(NULL)
}

#' Clip features to a mask and drop border slivers by area ratio
#'
#' @description
#' Transforms both layers to a projected CRS, keeps features in `x` that touch
#' the mask `y`, computes [sf::st_intersection()], aggregates clipped area per
#' identifier, and drops features whose clipped fraction of their original area is
#' below `min_area_ratio`.
#'
#' @details
#' For each feature in `x`, `area_full` is its area before clipping and
#' `area_clip` is the sum of areas from intersecting `x` with `y`. The ratio
#' `summary$area_ratio` is `area_clip / area_full`: the fraction of **each**
#' `x` feature that falls inside `y` (not the fraction of `y` covered by `x`).
#' Only **polygon** geometries are supported for `x` and `y`: points and lines
#' are not meaningful for an area ratio. For example, `min_area_ratio = 0.5`
#' retains a feature only when at least
#' half of its area overlaps the mask; the default `0.01` drops only very small
#' edge overlaps.
#'
#' @param x An [sf::sf] object with `POLYGON` or `MULTIPOLYGON` geometries.
#' @param y An [sf::sf] mask layer with polygon geometries.
#' @param x_id Name of the column in `x` with unique identifiers. If `NULL`
#'   (default), a column `.row_id` is added (row order after reprojection).
#' @param crs Target projected CRS for area and intersection, from [sf::st_crs()].
#'   If `NULL` (default), a SIRGAS 2000 Albers (Brazil) definition in metre
#'   units is used. Pass another projected CRS with meaningful area units when
#'   working outside Brazil.
#' @param min_area_ratio Numeric in `(0, 1]`: keep a feature when
#'   `area_clip / area_full` is greater than or equal to this value. Default
#'   `0.01` (about 1% of the feature area inside the mask).
#' @param repair If `TRUE`, apply [sf::st_make_valid()] to `x` and `y` after
#'   transforming (warnings are suppressed per call).
#'
#' @return A list with `clipped`, an [sf::sf] object with intersection
#'   geometries that passed the threshold, and `summary`, a [dplyr::tibble()]
#'   with the ID column, `area_full`, `area_clip`, `area_ratio`, and logical
#'   `keep`.
#'
#' @importFrom dplyr filter group_by if_else mutate semi_join slice summarise first tibble
#' @importFrom rlang .data
#' @importFrom sf st_area st_crs st_drop_geometry st_geometry st_geometry_type st_intersection st_intersects st_make_valid st_transform
#'
#' @export
#'
#' @examples
#' \donttest{
#' ring <- matrix(
#'   c(0, 0, 1e6, 0, 1e6, 1e6, 0, 1e6, 0, 0),
#'   ncol = 2L,
#'   byrow = TRUE
#' )
#' crs_pl <- sf::st_crs(3857)
#' y <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = crs_pl))
#' inner <- matrix(
#'   c(1e5, 1e5, 9e5, 1e5, 9e5, 9e5, 1e5, 9e5, 1e5, 1e5),
#'   ncol = 2L,
#'   byrow = TRUE
#' )
#' x <- sf::st_sf(
#'   id = "feat_1",
#'   geometry = sf::st_sfc(sf::st_polygon(list(inner)), crs = crs_pl)
#' )
#' out <- intersect_mask_filter_area(x, y, x_id = "id", crs = crs_pl, repair = FALSE)
#' nrow(out$summary)
#' }
intersect_mask_filter_area <- function(
    x,
    y,
    x_id = NULL,
    crs = NULL,
    min_area_ratio = 0.01,
    repair = TRUE) {
  if (!inherits(x, "sf") || !inherits(y, "sf")) {
    stop("`x` and `y` must be sf objects.", call. = FALSE)
  }
  if (is.na(sf::st_crs(x)) || is.na(sf::st_crs(y))) {
    stop("`x` and `y` must have a CRS defined.", call. = FALSE)
  }
  if (is.null(crs)) {
    crs <- sf::st_crs(.misc_albers_brazil_wkt)
  }

  xm <- sf::st_transform(x, crs)
  ym <- sf::st_transform(y, crs)
  if (repair) {
    xm <- suppressWarnings(sf::st_make_valid(xm))
    ym <- suppressWarnings(sf::st_make_valid(ym))
  }

  .misc_check_polygon_sf(xm, "x")
  .misc_check_polygon_sf(ym, "y")

  key <- if (is.null(x_id)) ".row_id" else x_id
  if (is.null(x_id)) {
    xm <- dplyr::mutate(xm, .row_id = seq_len(nrow(xm)), .before = 1L)
  } else if (!x_id %in% names(xm)) {
    stop("`x_id` must be a column name in `x`.", call. = FALSE)
  }

  cand <- dplyr::slice(xm, which(lengths(sf::st_intersects(xm, ym)) > 0L))
  if (!nrow(cand)) {
    empty_sum <- dplyr::tibble(
      area_full = numeric(0),
      area_clip = numeric(0),
      area_ratio = numeric(0),
      keep = logical(0)
    )
    empty_sum[[key]] <- cand[[key]]
    return(list(clipped = cand[FALSE, ], summary = empty_sum))
  }
  cand <- dplyr::mutate(
    cand,
    area_full = as.numeric(sf::st_area(sf::st_geometry(cand)))
  )
  inter <- suppressWarnings(sf::st_intersection(cand, ym))
  inter <- dplyr::mutate(
    inter,
    area_clip_part = as.numeric(sf::st_area(sf::st_geometry(inter)))
  )

  summary <- inter |>
    sf::st_drop_geometry() |>
    dplyr::group_by(.data[[key]]) |>
    dplyr::summarise(
      area_clip = sum(.data$area_clip_part),
      area_full = dplyr::first(.data$area_full),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      area_ratio = dplyr::if_else(
        .data$area_full > 0,
        .data$area_clip / .data$area_full,
        NA_real_
      ),
      keep = !is.na(.data$area_ratio) & .data$area_ratio >= min_area_ratio
    )

  clipped <- dplyr::semi_join(
    inter,
    dplyr::filter(summary, .data$keep),
    by = key
  )

  list(clipped = clipped, summary = summary)
}
