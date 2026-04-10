check_avail <- function(bin) {
  if (.Platform$OS.type == "windows") {
    stop("Windows platform is not supported yet! Sorry :(")
  }

  if (Sys.which(bin) == "") {
    stop(paste0("Make sure you have `", bin, "` installed in your system!"))
  }
}


.check_view_vd_macos <- function() {
  sysname <- tolower(as.character(Sys.info()["sysname"]))
  if (identical(sysname, "darwin")) {
    return(invisible(NULL))
  }
  if (.Platform$OS.type == "windows") {
    stop(
      paste0(
        "[ERROR] `{misc}`: This function is only supported on macOS. ",
        "It does not work on Windows."
      ),
      call. = FALSE
    )
  }
  if (identical(sysname, "linux")) {
    stop(
      paste0(
        "[ERROR] `{misc}`: This function is only supported on macOS. ",
        "It does not work on Linux."
      ),
      call. = FALSE
    )
  }
  stop(
    paste0(
      "[ERROR] `{misc}`: This function is only supported on macOS. ",
      "This operating system is not supported."
    ),
    call. = FALSE
  )
}


.check_visidata_cli <- function() {
  if (!nzchar(Sys.which("vd"))) {
    stop(
      paste0(
        "[ERROR] `{misc}`: VisiData is required but the `vd` command was not found on your PATH. ",
        "Install VisiData (a Python package), for example with: pip install visidata. ",
        "See https://www.visidata.org/ for documentation."
      ),
      call. = FALSE
    )
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
#' \donttest{
#' if (interactive()) {
#'   library(misc)
#'   mtcars %>%
#'     view_in()
#' }
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

check_sf_geometry <- function(data) {

  if (any(class(data) %in% "sf")) {

    message("[INFO] `{misc}`: Removing sf geometry...")

    data_clean <-
      data %>%
      sf::st_drop_geometry()

  } else {

    data_clean <- data

  }

  return(data_clean)

}

check_grouped_data <- function(data) {

  if (dplyr::is_grouped_df(data)) {

    message("[INFO] `{misc}`: Ungrouping data...")

    data_clean <-
      data %>%
      dplyr::ungroup()

  } else {

    data_clean <- data

  }

  return(data_clean)

}

check_list_columns <- function(data) {

  if (any(sapply(data, class) %in% "list")) {

    message("[INFO] `{misc}`: Removing list-columns... You can choose `type = 'json'` to explore list-columns!")

    data_clean <-
      data %>%
      dplyr::select(-dplyr::where(is.list))

  } else {

    data_clean <- data

  }

  return(data_clean)

}


.vd_escape_applescript <- function(s) {
  s <- gsub("\\", "\\\\", s, fixed = TRUE)
  gsub('"', '\\"', s, fixed = TRUE)
}


##' @noRd
.vd_iterm_process_running <- function() {
  for (nm in c("iTerm2", "iTerm")) {
    st <- suppressWarnings(
      system2("pgrep", c("-xq", nm), stdout = FALSE, stderr = FALSE)
    )
    if (isTRUE(st == 0)) {
      return(TRUE)
    }
  }
  FALSE
}


##' @noRd
.vd_parse_terminal_label <- function(raw) {
  if (length(raw) != 1L) {
    return(NULL)
  }
  raw <- as.character(raw)
  if (!nzchar(trimws(raw))) {
    return(NULL)
  }
  val <- tolower(trimws(raw))
  if (val %in% c("iterm2", "iterm")) {
    return("iterm")
  }
  if (val == "terminal") {
    return("terminal")
  }
  warning(
    "`MISC_VIEW_TERM` / `options(misc.view_term)` must be \"terminal\" or \"iterm\" (got: ",
    val, "); ignored.",
    call. = FALSE
  )
  NULL
}


##' Resolve \code{terminal = "auto"}: \env{MISC_VIEW_TERM} then \code{options(misc.view_term)}.
##' If unknown or unset after invalid values, falls back to Terminal.app.
##' @noRd
.vd_resolve_terminal_auto <- function() {
  chosen <- .vd_parse_terminal_label(Sys.getenv("MISC_VIEW_TERM", unset = ""))
  if (!is.null(chosen)) {
    return(chosen)
  }
  opt <- getOption("misc.view_term")
  if (!is.null(opt)) {
    chosen <- .vd_parse_terminal_label(opt)
    if (!is.null(chosen)) {
      return(chosen)
    }
  }
  "terminal"
}


##' Build osascript invocation to run a shell command in Terminal.app or iTerm2 (macOS).
##'
##' @param shell_cmd Command line to run after the terminal starts (e.g. `vd file.csv`).
##' @param terminal `"terminal"`, `"auto"`, or `"iterm"` (see [view_vd()]).
##' @return String passed to [base::system()].
##' @noRd
.vd_macos_osascript <- function(shell_cmd, terminal = c("terminal", "auto", "iterm")) {
  terminal <- match.arg(terminal)
  if (terminal == "auto") {
    terminal <- .vd_resolve_terminal_auto()
  }
  sh <- .vd_escape_applescript(shell_cmd)
  if (terminal == "terminal") {
    glue::glue(
      "osascript -e 'tell application \"Terminal\"
          if not application \"Terminal\" is running then launch
          do script \"<<sh>>\"
          activate
      end tell'
      ",
      sh = sh,
      .open = "<<",
      .close = ">>"
    )
  } else {
    # Cold start: `open` creates one window with one tab. If we always used the
    # "has windows" branch we would add a second tab (empty first tab + vd tab).
    # When iTerm was already running, still add a tab in the current window.
    #
    # If the app is quit, AppleScript cannot compile (count of windows) until
    # iTerm is running — so cold-start calls must prefix with open + sleep.
    iterm_was_running <- .vd_iterm_process_running()
    if (iterm_was_running) {
      glue::glue(
        "osascript -e 'tell application \"iTerm2\"
            activate
            if (count of windows) is 0 then
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text \"<<sh>>\"
                end tell
            else
                tell current window
                    set newTab to (create tab with default profile)
                    tell current session of newTab
                        write text \"<<sh>>\"
                    end tell
                end tell
            end if
        end tell'
        ",
        sh = sh,
        .open = "<<",
        .close = ">>"
      )
    } else {
      glue::glue(
        "open -b com.googlecode.iterm2; sleep 0.4; osascript -e 'tell application \"iTerm2\"
            activate
            if (count of windows) is 0 then
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text \"<<sh>>\"
                end tell
            else
                tell current session of current window
                    write text \"<<sh>>\"
                end tell
            end if
        end tell'
        ",
        sh = sh,
        .open = "<<",
        .close = ">>"
      )
    }
  }
}


#' View data in VisiData
#'
#' @description
#' **macOS only.** Does not work on Windows or Linux. Opens data in VisiData using the
#' built-in Terminal.app by default (\code{terminal = "terminal"}); use \code{terminal = "auto"}
#' with `MISC_VIEW_TERM` / \code{options(misc.view_term)} for a configurable choice, or
#' \code{terminal = "iterm"} for iTerm2. If the input is an sf object, the geometry column
#' will be dropped before viewing.
#'
#' @param data A data.frame, tibble, or sf object to view
#' @param type Either "csv" or "json" format for writing the temporary file. Use "json" for
#'   preserving list-columns.
#' @param terminal Which macOS terminal to use: `"terminal"` (default) is the built-in
#'   Terminal.app; `"iterm"` forces iTerm2 (new tab if a window already exists, otherwise a
#'   new window); `"auto"` reads the choice from the environment variable `MISC_VIEW_TERM`
#'   and then from \code{options(misc.view_term)} — set either to `"terminal"` or `"iterm"`.
#'   If `auto` finds nothing valid, Terminal.app is used.
#'
#' @details
#' **Platform:** Supported only on **macOS** (Darwin). On Windows or Linux, the function
#' stops with an error. It only performs the VisiData launch in **interactive** R sessions;
#' in non-interactive sessions it does not open a terminal but still returns the data.
#'
#' It creates a temporary file and opens it in VisiData in the selected terminal. For
#' \code{terminal = "auto"}, set `MISC_VIEW_TERM` (e.g. in \file{~/.Renviron}) and/or
#' \code{options(misc.view_term = "iterm")} so VisiData opens in iTerm2 when you are inside
#' tmux or other environments where a fixed default is needed.
#' The temporary filename includes a timestamp for identification.
#'
#' The VisiData CLI (`vd`) must be installed and on your `PATH` (VisiData is a Python
#' package; see <https://www.visidata.org/>). If an executable named `vdk` is also on
#' your `PATH`, it is invoked instead as `vdk <project_basename> <file>` (a local helper;
#' not shipped with this package); `vd` is still required.
#'
#' @return Returns the input data invisibly
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#' # View a data frame
#' mtcars %>% view_vd()
#'
#' # View with custom title
#' mtcars %>% view_vd(title = "Car Data")
#'
#' # View with list columns preserved
#' nested_df %>% view_vd(type = "json")
#' }
#' }
view_vd <- function(data, type = "csv", terminal = c("terminal", "auto", "iterm")) {

  terminal <- match.arg(terminal)

  if (!any(class(data) %in% "data.frame")) {

    stop("[ERROR] `{misc}`: Input must be a data.frame", call. = FALSE)

  }

  .check_view_vd_macos()

  if (interactive()) {

    misc_dir <- paste0(Sys.getenv("HOME"), "/.misc")

    if (!dir.exists(here::here(misc_dir))) {
      dir.create(here::here(misc_dir))
    }

    project_name <- basename(here::here())

    construct_file_name <- function(file_extension) {
      return(paste0(misc_dir, "/", format(Sys.time(), "%Y%m%d.%s"), "_", project_name, extfile))
    }

    if (type == "csv") {

      data_clean <-
        data %>%
        check_sf_geometry() %>%
        check_grouped_data() %>%
        check_list_columns()

      extfile <- ".csv"
      tmp <- construct_file_name(extfile)
      num_threads <- parallel::detectCores()
      data.table::setDTthreads(num_threads)
      data.table::fwrite(x = data_clean, file = tmp, nThread = num_threads, na = NA)

    }

    if (type == "json") {

      data_clean <- data

      extfile <- ".json"
      tmp <- construct_file_name(extfile)
      jsonlite::write_json(data_clean, tmp)

    }

    ## NOTE 2024-10-15: Use jsonlite::write_json to get list-columns
    ## see: https://github.com/paulklemm/rvisidata/issues/5
    .check_visidata_cli()
    shell_cmd <- if (nzchar(Sys.which("vdk"))) {
      glue::glue("vdk {project_name} {tmp}")
    } else {
      glue::glue("vd --default-width=500 {tmp}")
    }
    system(.vd_macos_osascript(shell_cmd, terminal = terminal))

  }

  message("[INFO] `{misc}`: Your original data:")
  return(data)

}

#' View data frame in VisiData (non-interactive version)
#'
#' **macOS only.** Does not work on Windows or Linux (see [view_vd()]).
#' Opens a data frame in VisiData terminal viewer, saving to a fixed location in Downloads.
#' Similar to view_vd() but without interactive mode check. Uses `vdk` when on `PATH`,
#' otherwise `vd` (see Details of [view_vd()]).
#'
#' @param data A data frame or sf object to view
#' @param title Optional title for the viewer window (default: "misc::view_vd")
#' @param terminal Which macOS terminal to use; see [view_vd()].
#'
#' @details
#' **Platform:** Supported only on **macOS**. On Windows or Linux, stops with an error;
#' see [view_vd()] for VisiData and terminal requirements.
#'
#' @return Returns the input data frame unchanged
#' @export
view_vd_nonint <- function(data, title = NULL, terminal = c("terminal", "auto", "iterm")) {

  terminal <- match.arg(terminal)
  .check_view_vd_macos()

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
    project_name <- basename(here::here())
    .check_visidata_cli()
    shell_cmd <- if (nzchar(Sys.which("vdk"))) {
      glue::glue("vdk {project_name} {tmp}")
    } else {
      glue::glue("vd --default-width=500 {tmp}")
    }
    system(.vd_macos_osascript(shell_cmd, terminal = terminal))
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
#' **macOS only:** tabular viewing uses [view_vd_nonint()], which is not supported on Windows or Linux;
#' on those systems the function stops with an error.
#'
#' @param path Path to the spatial data file (.shp or .gpkg)
#' @param preview Logical. If TRUE, opens an interactive map preview in the browser. Default is FALSE.
#'
#' @details
#' Requires **macOS** because the workflow always opens the attribute table with VisiData
#' via [view_vd_nonint()]. The function performs the following steps:
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

  .check_view_vd_macos()

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
