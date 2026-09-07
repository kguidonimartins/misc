#' Open an sf object in QGIS
#'
#' Writes `data` to a temporary geospatial file and opens it in QGIS.
#'
#' @param data An object of class `sf`.
#' @param format File format, either `"gpkg"` (default) or `"geojson"`.
#' @param layer Layer name for GeoPackage output. If `NULL`, inferred from the
#'   input expression or project name. Ignored for GeoJSON output.
#' @param app QGIS application name or path. If `NULL`, resolved from
#'   configuration and standard macOS application directories.
#' @return `data`, invisibly.
#'
#' @details
#' This viewer is supported only on macOS. In a non-interactive session the
#' input is validated and returned invisibly without writing a file or opening
#' QGIS. Interactive files are written below `~/.misc` and are not removed
#' automatically. QGIS can be configured with `MISC_QGIS_APP` or
#' `options(misc.qgis_app = "QGIS-LTR")`.
#'
#' @importFrom fs dir_create dir_ls
#' @importFrom here here
#' @importFrom sf write_sf
#' @family data-viewers
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   sf::st_sf(
#'     id = 1,
#'     geometry = sf::st_sfc(sf::st_point(c(0, 0)))
#'   ) %>% view_qgis()
#' }
#' }
view_qgis <- function(data, format = c("gpkg", "geojson"), layer = NULL,
                      app = NULL) {
  format <- match.arg(format)

  if (!inherits(data, "sf")) {
    stop("[ERROR] `{misc}`: Input must be an sf object.", call. = FALSE)
  }

  .check_view_vd_macos()

  if (!interactive()) {
    warning(
      "[WARNING] `{misc}`: Non-interactive session; QGIS was not opened.",
      call. = FALSE
    )
    return(invisible(data))
  }

  misc_dir <- fs::path_expand("~/.misc")
  fs::dir_create(misc_dir)
  project_name <- basename(here::here())
  ext <- if (format == "gpkg") "gpkg" else "geojson"
  tmp <- .view_qgis_tmp_path(project_name, ext, misc_dir)

  if (format == "gpkg") {
    if (is.null(layer)) {
      layer <- deparse(substitute(data))
      if (length(layer) != 1L || !grepl("^[A-Za-z][A-Za-z0-9_.-]*$", layer)) {
        layer <- project_name
      }
    }
    sf::write_sf(data, tmp, layer = layer)
  } else {
    sf::write_sf(data, tmp, driver = "GeoJSON")
  }

  qgis_app <- .qgis_app(app)
  message(
    "[INFO] `{misc}`: Opening ", basename(tmp), " in QGIS..."
  )
  system2("open", c("-a", shQuote(qgis_app), shQuote(tmp)), wait = FALSE)
  invisible(data)
}

.view_qgis_tmp_path <- function(project_name, ext, dir = fs::path_expand("~/.misc")) {
  file.path(dir, paste0(format(Sys.time(), "%Y%m%d.%s"), "_", project_name, ".", ext))
}

.qgis_app <- function(app = NULL, dirs = c("/Applications", "~/Applications")) {
  if (!is.null(app)) {
    return(app)
  }
  env_app <- Sys.getenv("MISC_QGIS_APP")
  if (nzchar(env_app)) {
    return(env_app)
  }
  option_app <- getOption("misc.qgis_app")
  if (!is.null(option_app) && length(option_app) == 1L && nzchar(option_app)) {
    return(option_app)
  }

  candidates <- unlist(lapply(dirs, function(dir) {
    dir <- fs::path_expand(dir)
    if (dir.exists(dir)) {
      fs::dir_ls(dir, type = "directory", regexp = "^QGIS.*\\.app$")
    }
  }), use.names = FALSE)
  if (length(candidates) > 0L) {
    candidates <- candidates[order(basename(candidates), decreasing = TRUE)]
    chosen <- candidates[[1L]]
    if (length(candidates) > 1L) {
      message("[INFO] `{misc}`: Multiple QGIS applications found; using ", chosen)
    }
    return(chosen)
  }

  stop(
    paste0(
      "[ERROR] `{misc}`: QGIS was not found in /Applications. Install QGIS ",
      "(https://qgis.org) or set the app name with MISC_QGIS_APP / ",
      "options(misc.qgis_app = \"QGIS-LTR\")."
    ),
    call. = FALSE
  )
}
