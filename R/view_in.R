check_avail <- function(bin) {
  if (.Platform$OS.type == "windows") {
    stop("Windows platform is not supported yet! Sorry :(")
  }

  if (Sys.which(bin) == "") {
    stop(paste0("Make sure you have `", bin, "` installed in your system!"))
  }
}

#' Alternative data.frame viewer
#'
#' @description
#' `view_in()` is an alternative to `View()` function when not using
#' RStudio. To date, it works with gnumeric, libreoffice and tad.
#' @param data a data.frame/tibble data format.
#' @param viewer character app to open the csv file.
#' @importFrom readr write_csv
#' @importFrom jsonlite write_json
#' @importFrom sf read_sf
#' @importFrom mapview mapview mapshot
#' @importFrom fs file_exists dir_create
#' @return None
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#' mtcars %>%
#'   view_in()
#' }
view_in <- function(data, viewer = c("libreoffice", "gnumeric", "tad")) {
  viewer <- match.arg(viewer)
  check_avail(viewer)
  tmp <- paste0(tempfile(), ".csv")
  readr::write_csv(data, tmp)
  system(paste0(viewer, " ", tmp, " > /dev/null 2>&1 &"))
}

## #' @export
## view_vd <- function(data, title = NULL) {
##   if (interactive()) {
##     bin <- Sys.which("st")
##     if (is.null(title)) {
##       title <- "misc::view_vd"
##     }
##     if (bin == "") {
##       message("INFO: `st` is not available; using the built-in `View()`.")
##       data |> View()
##     } else {
##       tmp <- paste0(tempfile(), ".csv")
##       readr::write_csv(data, tmp)
##       system(glue::glue("st -g '200x65+320+50' -T '{title}' -e sh -c 'vd --default-width=500 {tmp}' > /dev/null 2>&1 &"))
##     }
##   }
##   return(data)
## }

#' View data in VisiData
#'
#' @description
#' Opens data in VisiData through the Terminal application on macOS. If the input is
#' an sf object, the geometry column will be dropped before viewing.
#'
#' @param data A data.frame, tibble, or sf object to view
#' @param title Character string for the Terminal window title. Defaults to "misc::view_vd"
#' @param type Either "csv" or "json" format for writing the temporary file. Use "json" for
#'   preserving list-columns.
#'
#' @details
#' This function only works in interactive sessions on macOS. It creates a temporary file
#' and opens it in VisiData through the Terminal application. The temporary filename includes
#' a timestamp for identification.
#'
#' @return Returns the input data invisibly
#' @export
#'
#' @examples
#' \dontrun{
#' # View a data frame
#' mtcars %>% view_vd()
#'
#' # View with custom title
#' mtcars %>% view_vd(title = "Car Data")
#'
#' # View with list columns preserved
#' nested_df %>% view_vd(type = "json")
#' }
view_vd <- function(data, title = NULL, type = "csv") {
  # Check if input is a valid data type
  valid_classes <- c("data.frame", "tbl_df", "sf")
  if (!any(class(data) %in% valid_classes)) {
    stop("Input must be a data.frame, tibble, or sf object")
  }

  if (interactive()) {

    misc_dir <- paste0(Sys.getenv("HOME"), "/.misc")

    if (!dir.exists(here::here(misc_dir))) {
      dir.create(here::here(misc_dir))
    }

    project_name <- basename(here::here())

    construct_file_name <- function(file_extension) {
      return(paste0(misc_dir, "/", format(Sys.time(), "D%Y%m%dT%H%M%OS5"), "_", project_name, extfile))
    }

    if (is.null(title)) {
      title <- "misc::view_vd"
    }

    if (class(data)[1] == "sf") {
      message("[INFO] `{misc}`: Removing sf geometry...")
      data_clean <-
        sf::st_drop_geometry(data)
    } else {
      data_clean <- data
    }

    ## remove list-columns
    if (dplyr::is_grouped_df(data_clean)) {
      message("[INFO] `{misc}`: Ungrouping data...")
      message("[INFO] `{misc}`: Removing list-columns...")
      data_clean <-
        data_clean %>%
        dplyr::ungroup() %>%
        dplyr::select(-dplyr::where(is.list))
    } else {
      message("[INFO] `{misc}`: Removing list-columns...")
      data_clean <-
        data_clean %>%
        dplyr::ungroup() %>%
        dplyr::select(-dplyr::where(is.list))
    }

    if (type == "csv") {
      extfile <- ".csv"
      tmp <- construct_file_name(extfile)
      num_threads <- parallel::detectCores()
      data.table::setDTthreads(num_threads)
      data.table::fwrite(x = data_clean, file = tmp, nThread = num_threads)
    }

    if (type == "json") {
      extfile <- "json"
      tmp <- paste0(tempfile(), "___", format(Sys.time(), "D%Y%m%dT%H%M%S"), "___misc___visidata", extfile)
      jsonlite::write_json(data_clean, tmp)
    }

    ## NOTE 2024-10-15: Use jsonlite::write_json to get list-columns
    ## see: https://github.com/paulklemm/rvisidata/issues/5
    system(
      ## glue::glue("osascript -e 'tell app \"Terminal\" to do script \"vd --default-width=500 {tmp}\"' -e 'tell app \"Terminal\" to activate'")
      glue::glue(
      "osascript -e 'tell application \"Terminal\"
          if not application \"Terminal\" is running then launch
          do script \"vd --default-width=500 {tmp}\"
          activate
      end tell'
      "
      )
    )

  }
  return(dplyr::glimpse(data))
}

#' View data frame in VisiData (non-interactive version)
#'
#' Opens a data frame in VisiData terminal viewer, saving to a fixed location in Downloads.
#' Similar to view_vd() but without interactive mode check.
#'
#' @param data A data frame or sf object to view
#' @param title Optional title for the viewer window (default: "misc::view_vd")
#' @return Returns the input data frame unchanged
#' @export
view_vd_nonint <- function(data, title = NULL) {
    ## bin <- Sys.which("st")

    if (is.null(title)) {
      title <- "misc::view_vd"
    }

    if (class(data)[1] == "sf") {
      message("Removing sf geometry...")
      data_clean <-
        sf::st_drop_geometry(data)
    } else {
      data_clean <- data
    }

    tmp <- paste0("/Users/karloguidoni/Downloads/", "___", format(Sys.time(), "D%Y%m%dT%H%M%S"), "___misc___visidata.csv")
    readr::write_csv(data_clean, tmp)
    system(
      ## glue::glue("osascript -e 'tell app \"Terminal\" to do script \"vd --default-width=500 {tmp}\"' -e 'tell app \"Terminal\" to activate'")
      glue::glue(
      "osascript -e 'tell application \"Terminal\"
          if not application \"Terminal\" is running then launch
          do script \"vd --default-width=500 {tmp}\"
          activate
      end tell'
      "
      )
    )
  return(data)
}


#' View data frame in Excel or other spreadsheet viewer
#'
#' Opens a data frame in Microsoft Excel or another spreadsheet viewer. Also copies the data
#' to the system clipboard.
#'
#' @param data A data frame to view
#' @param viewer The spreadsheet viewer to use. One of "libreoffice", "gnumeric", "tad", or "excel" (default)
#' @return Returns nothing
#' @export
view_excel <- function(data, viewer = c("libreoffice", "gnumeric", "tad", "excel")) {
  viewer <- match.arg(viewer)
  ## check_avail(viewer)
  tmp <- paste0(tempfile(), ".xlsx")
  clipr::write_clip(data)
  message("Data is also on system clipboard!")
  writexl::write_xlsx(data, tmp)
  system(paste0("open -a 'Microsoft Excel'", " tmp "))
}

#' View spatial data from file path with optional map preview
#'
#' Reads a spatial data file (.shp or .gpkg) and optionally displays it in an interactive map preview.
#' The data is also opened in VisiData for tabular viewing.
#'
#' @param path Path to the spatial data file (.shp or .gpkg)
#' @param preview Logical. If TRUE, opens an interactive map preview in the browser. Default is FALSE.
#'
#' @details
#' The function performs the following steps:
#' 1. Validates that the input file exists and has the correct extension (.shp or .gpkg)
#' 2. Creates a temporary HTML file for the map preview in ~/.local/share/mapview/
#' 3. Reads the spatial data using sf::read_sf()
#' 4. If preview=TRUE, creates an interactive map using mapview and opens it in the browser
#' 5. Opens the attribute data in VisiData
#'
#' @return Returns nothing, called for side effects
#' @export
view_mapview_from_path <- function(path, preview = FALSE) {

  stopifnot(fs::file_exists(path))

  stopifnot(tolower(tools::file_ext(path)) == "shp" | tolower(tools::file_ext(path)) == "gpkg")

  path_string <- deparse(substitute(path))

  basename_filename <- tools::file_path_sans_ext(basename(path))

  userhome <- Sys.getenv("HOME")

  userlocal <- paste0(userhome, "/.local/share/mapview/")

  fs::dir_create(userlocal)

  tempmapfile <-
    paste0(userlocal, basename_filename, "___", format(Sys.time(), "D%Y%m%dT%H%M%S"), "__mapview.html")

  df <-
    path |>
    sf::read_sf()

  if (preview) {

    dinamic_map <-
      mapview::mapview(df, map.types = c("OpenStreetMap"))

    mapview::mapshot(
      dinamic_map,
      url = tempmapfile,
      remove_controls = NULL,
      title = basename_filename
    )

    system(paste0("open ", tempmapfile))

  }

  misc::view_vd_nonint(df)

}
