.clean_geo_check_path <- function(path) {
  p <- fs::path_expand(path)
  if (!fs::file_exists(p)) {
    stop("Path not found: ", p, call. = FALSE)
  }
  normalizePath(p, winslash = "/", mustWork = TRUE)
}

.clean_geo_supported_exts <- function() {
  c("zip", "shp", "gpkg", "geojson")
}

.clean_geo_check_ext <- function(path, which = c("input", "output")) {
  which <- match.arg(which)
  ext <- tolower(tools::file_ext(path))
  supported <- .clean_geo_supported_exts()
  if (!ext %in% supported) {
    stop(
      sprintf(
        "Unsupported %s extension: '%s'. Supported: %s.",
        which,
        ext,
        paste0(".", supported, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  ext
}

.clean_geo_extract_zip <- function(path, exdir) {
  utils::unzip(path, exdir = exdir, overwrite = TRUE)
  shps <- fs::dir_ls(exdir, regexp = "\\.shp$", recurse = TRUE)
  if (length(shps) == 0L) {
    stop("No .shp file found inside the ZIP archive: ", path, call. = FALSE)
  }
  if (length(shps) > 1L) {
    stop(
      "More than one .shp file found inside the ZIP archive: ",
      path,
      ". clean_geo() requires exactly one shapefile per ZIP.",
      call. = FALSE
    )
  }
  normalizePath(shps[[1L]], winslash = "/", mustWork = TRUE)
}

.clean_geo_replace_non_ascii <- function(sf_obj) {
  sf_obj <- sf::st_zm(sf_obj, drop = TRUE, what = "ZM")
  dplyr::mutate(
    sf_obj,
    dplyr::across(
      -dplyr::any_of(c("geometry", "geom")),
      ~ textclean::replace_non_ascii(.x)
    )
  )
}

.clean_geo_write_shp <- function(sf_obj, output, encoding) {
  fs::dir_create(dirname(output))
  sf::write_sf(
    sf_obj,
    output,
    layer_options = paste0("ENCODING=", encoding),
    delete_dsn = fs::file_exists(output)
  )
}

.clean_geo_write_gpkg <- function(sf_obj, output) {
  fs::dir_create(dirname(output))
  sf::write_sf(sf_obj, output, driver = "GPKG", delete_dsn = fs::file_exists(output))
}

.clean_geo_write_geojson <- function(sf_obj, output) {
  fs::dir_create(dirname(output))
  sf::write_sf(sf_obj, output, driver = "GeoJSON", delete_dsn = fs::file_exists(output))
}

.clean_geo_write_zip <- function(sf_obj, output, encoding) {
  fs::dir_create(dirname(output))
  tmp <- tempfile("clean_geo_zip_")
  fs::dir_create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  layer_name <- tools::file_path_sans_ext(basename(output))
  shp_path <- file.path(tmp, paste0(layer_name, ".shp"))
  sf::write_sf(
    sf_obj,
    shp_path,
    layer_options = paste0("ENCODING=", encoding)
  )

  sidecars <- list.files(tmp, full.names = FALSE)
  if (fs::file_exists(output)) {
    unlink(output)
  }
  zip::zip(
    zipfile = output,
    files = sidecars,
    root = tmp,
    mode = "cherry-pick"
  )
}

.clean_geo_write <- function(sf_obj, output, output_ext, encoding) {
  switch(
    output_ext,
    shp = .clean_geo_write_shp(sf_obj, output, encoding),
    gpkg = .clean_geo_write_gpkg(sf_obj, output),
    geojson = .clean_geo_write_geojson(sf_obj, output),
    zip = .clean_geo_write_zip(sf_obj, output, encoding)
  )
  invisible(output)
}

#' Clean a spatial file and write a normalized copy
#'
#' Reads a spatial file (`.zip` containing a single shapefile, `.shp`, `.gpkg`,
#' or `.geojson`), drops Z/M dimensions, replaces non-ASCII characters in every
#' attribute column, reprojects the geometry to a target CRS and writes the
#' result to a user-provided `output` path. The output format is determined by
#' the extension of `output` and may differ from the input format (for example,
#' a `.shp` can be cleaned and written as `.gpkg`).
#'
#' This function replaces a standalone batch script that cleaned shapefiles
#' from a client geospatial portal. The non-ASCII replacement step relies on
#' [textclean::replace_non_ascii()]; `textclean` lives in `Suggests:`, so the
#' function stops with an informative error if it is not installed.
#'
#' @param path Path to the input spatial file. Must be `.zip` (containing
#'   exactly one shapefile), `.shp`, `.gpkg`, or `.geojson`.
#' @param output Path to the output file. Required. The extension determines
#'   the output format and must also be one of `.zip`, `.shp`, `.gpkg`, or
#'   `.geojson`. Existing files at `output` are overwritten.
#' @param crs Target coordinate reference system passed to
#'   [sf::st_transform()]. Defaults to EPSG:4326 (WGS84).
#' @param encoding Encoding string used when writing shapefile attribute
#'   tables (passed as `layer_options = "ENCODING=<encoding>"`). Applies only
#'   to `.shp` and `.zip` outputs. Defaults to `"ISO-8859-1"`.
#' @param quiet Logical. If `TRUE`, suppress progress messages.
#'
#' @returns Invisibly returns the normalized `output` path (character).
#'
#' @importFrom dplyr across any_of mutate
#' @importFrom fs dir_create dir_ls file_exists path_expand
#' @importFrom sf read_sf st_transform st_zm write_sf
#' @importFrom tools file_ext file_path_sans_ext
#' @importFrom usethis ui_done ui_field ui_todo
#' @importFrom zip zip
#'
#' @family geo-io
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (requireNamespace("textclean", quietly = TRUE)) {
#'   z <- system.file("extdata", "misc_example.zip", package = "misc")
#'   if (nzchar(z) && file.exists(z)) {
#'     out <- tempfile(fileext = ".zip")
#'     clean_geo(z, out)
#'
#'     out_gpkg <- tempfile(fileext = ".gpkg")
#'     clean_geo(z, out_gpkg)
#'   }
#' }
#' }
clean_geo <- function(path,
                      output,
                      crs = 4326,
                      encoding = "ISO-8859-1",
                      quiet = FALSE) {
  if (missing(output) || is.null(output) || !nzchar(output)) {
    stop("`output` is required and must be a non-empty character path.", call. = FALSE)
  }
  if (!is.character(output) || length(output) != 1L) {
    stop("`output` must be a single character string.", call. = FALSE)
  }

  check_require("textclean")

  path <- .clean_geo_check_path(path)
  input_ext <- .clean_geo_check_ext(path, "input")
  output_ext <- .clean_geo_check_ext(output, "output")

  log_todo <- function(msg) {
    if (!isTRUE(quiet)) usethis::ui_todo(msg)
  }
  log_done <- function(msg) {
    if (!isTRUE(quiet)) usethis::ui_done(msg)
  }

  log_todo("Reading {usethis::ui_field(path)}")

  if (input_ext == "zip") {
    exdir <- tempfile("clean_geo_unzip_")
    fs::dir_create(exdir)
    on.exit(unlink(exdir, recursive = TRUE), add = TRUE)
    shp_path <- .clean_geo_extract_zip(path, exdir)
    sf_obj <- sf::read_sf(shp_path)
  } else {
    sf_obj <- sf::read_sf(path)
  }

  log_todo("Replacing non-ASCII characters and reprojecting")
  sf_obj <- .clean_geo_replace_non_ascii(sf_obj)
  sf_obj <- sf::st_transform(sf_obj, crs)

  log_todo("Writing {usethis::ui_field(output)}")
  .clean_geo_write(sf_obj, output, output_ext, encoding)
  log_done("{usethis::ui_field(output)} written!")

  invisible(output)
}
