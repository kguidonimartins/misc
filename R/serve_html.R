.misc_serve <- new.env(parent = emptyenv())

#' Serve HTML widgets and reports to a remote browser
#'
#' Writes an HTML widget to disk and serves it over HTTP so it can be opened
#' in a browser on another device, such as an iPad running a terminal over
#' SSH or mosh. Handles `mapview` maps, any `htmlwidget` (`leaflet`,
#' `plotly`, `DT`, `gt`), and HTML files that are already on disk, such as a
#' rendered R Markdown or Quarto report.
#'
#' @param x A `mapview` object, an `htmlwidget`, an `sf` object (rendered
#'   with [mapview::mapview()]), or a path to an existing `.html` file.
#' @param host Hostname to advertise in the URL. If `NULL`, resolved the same
#'   way as in [serve_plots()].
#' @param name Optional label used in the file name, to tell several served
#'   pages apart. Non-alphanumeric characters are replaced with `-`.
#' @param port Port to bind. If `NULL`, a running session server is reused,
#'   otherwise a random free port is chosen.
#' @param bind Address to bind the server to. Defaults to `"0.0.0.0"` so the
#'   server answers on every interface; use `"127.0.0.1"` to keep it local.
#' @param quiet If `TRUE`, do not message the URL.
#'
#' @return The page URL, invisibly, as a character scalar.
#'
#' @importFrom methods slot
#'
#' @details
#' One static server is started per R session and reused by later calls, so
#' every URL handed out stays valid and several pages can be compared in
#' different browser tabs. Files are served from a session directory below
#' [tempdir()] and are removed when R exits. Call [serve_html_stop()] to shut
#' the server down earlier.
#'
#' Pages are served on a background thread, so they stay reachable while R is
#' busy computing.
#'
#' Unlike [serve_plots()], a static server has no access token. Page names
#' carry a random component instead, and directory listing is disabled, so a
#' URL cannot be guessed from the port alone. Binding to `0.0.0.0` still
#' exposes the server to every machine that can reach this host, so prefer
#' `bind = "127.0.0.1"` on untrusted networks.
#'
#' Interactive maps load their base tiles from the internet, so the remote
#' device needs network access beyond the tunnel to this machine.
#'
#' @family data-viewers
#' @seealso [serve_map()], [serve_html_stop()], [serve_plots()]
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   # a rendered report
#'   serve_html("output/report.html")
#'
#'   # any htmlwidget (leaflet, plotly, DT, gt, ...)
#'   serve_html(leaflet::leaflet())
#' }
#' }
serve_html <- function(x, host = NULL, name = NULL, port = NULL,
                       bind = "0.0.0.0", quiet = FALSE) {
  check_require("httpuv")

  if (!is.character(bind) || length(bind) != 1L || !nzchar(bind)) {
    stop(
      "[ERROR] `{misc}`: `bind` must be a single non-empty string.",
      call. = FALSE
    )
  }

  server <- .serve_html_server(bind = bind, port = port)
  rel <- .serve_html_publish(x, name = name, server = server)
  url <- .serve_html_url(rel, host = host, server = server)

  if (!quiet) {
    message("[INFO] `{misc}`: Page served at ", url)
  }

  invisible(url)
}

#' Serve an interactive map to a remote browser
#'
#' Thin wrapper around [serve_html()] that renders `x` with
#' [mapview::mapview()] first, so mapview arguments such as `zcol` or
#' `map.types` can be passed straight through.
#'
#' @param x An `sf` object, or anything else [mapview::mapview()] accepts. A
#'   `mapview` object is served as is.
#' @param ... Further arguments passed to [mapview::mapview()], such as
#'   `zcol` or `map.types`.
#' @inheritParams serve_html
#'
#' @return The page URL, invisibly, as a character scalar.
#'
#' @family data-viewers
#' @seealso [serve_html()], [serve_html_stop()]
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   pts <- sf::st_sf(
#'     id = 1:2,
#'     geometry = sf::st_sfc(
#'       sf::st_point(c(-49.25, -16.68)),
#'       sf::st_point(c(-49.30, -16.70)),
#'       crs = 4326
#'     )
#'   )
#'   serve_map(pts, zcol = "id")
#' }
#' }
serve_map <- function(x, ..., host = NULL, name = NULL, quiet = FALSE) {
  check_require("mapview")

  if (!inherits(x, "mapview")) {
    x <- mapview::mapview(x, ...)
  }

  serve_html(x, host = host, name = name, quiet = quiet)
}

#' Stop the session HTML server
#'
#' Shuts down the static server started by [serve_html()]. Served URLs stop
#' working; the next [serve_html()] call starts a fresh server.
#'
#' @param quiet If `TRUE`, do not message the outcome.
#'
#' @return `TRUE` if a server was stopped, `FALSE` otherwise, invisibly.
#'
#' @family data-viewers
#' @seealso [serve_html()]
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   serve_html_stop()
#' }
#' }
serve_html_stop <- function(quiet = FALSE) {
  server <- .misc_serve$server
  running <- !is.null(server) && isTRUE(server$isRunning())

  if (running) {
    server$stop()
  }
  .misc_serve$server <- NULL
  .misc_serve$root <- NULL

  if (!quiet) {
    if (running) {
      message("[INFO] `{misc}`: HTML server stopped.")
    } else {
      message("[INFO] `{misc}`: No HTML server was running.")
    }
  }

  invisible(running)
}

.serve_html_root <- function() {
  root <- .misc_serve$root
  if (is.null(root) || !dir.exists(root)) {
    root <- file.path(tempdir(), paste0("misc-serve-", basename(tempfile(""))))
    dir.create(root, recursive = TRUE, showWarnings = FALSE)
    .misc_serve$root <- root
  }
  root
}

.serve_html_server <- function(bind = "0.0.0.0", port = NULL) {
  server <- .misc_serve$server
  running <- !is.null(server) && isTRUE(server$isRunning())

  if (running) {
    keep <- is.null(port) ||
      (isTRUE(as.integer(port) == server$getPort()) && bind == server$getHost())
    if (keep) {
      return(server)
    }
    server$stop()
    .misc_serve$server <- NULL
  }

  root <- .serve_html_root()
  if (is.null(port)) {
    port <- httpuv::randomPort(host = bind)
  }

  server <- httpuv::startServer(
    host = bind,
    port = as.integer(port),
    app = list(staticPaths = list("/" = root))
  )
  .misc_serve$server <- server
  server
}

.serve_html_slug <- function(name = NULL) {
  token <- basename(tempfile(""))
  if (is.null(name)) {
    return(token)
  }
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop(
      "[ERROR] `{misc}`: `name` must be a single non-empty string.",
      call. = FALSE
    )
  }
  slug <- gsub("[^A-Za-z0-9]+", "-", name)
  slug <- gsub("(^-|-$)", "", slug)
  if (!nzchar(slug)) {
    return(token)
  }
  paste0(slug, "-", token)
}

.serve_html_publish <- function(x, name = NULL, server = NULL) {
  if (is.character(x)) {
    return(.serve_html_mount_file(x, server = server))
  }

  widget <- .serve_html_as_widget(x)
  check_require("htmlwidgets")

  root <- .serve_html_root()
  file <- paste0(.serve_html_slug(name), ".html")
  htmlwidgets::saveWidget(widget, file.path(root, file), selfcontained = FALSE)
  file
}

.serve_html_as_widget <- function(x) {
  if (inherits(x, "mapview")) {
    return(methods::slot(x, "map"))
  }
  if (inherits(x, "htmlwidget")) {
    return(x)
  }
  if (inherits(x, "sf")) {
    check_require("mapview")
    return(methods::slot(mapview::mapview(x), "map"))
  }
  stop(
    paste0(
      "[ERROR] `{misc}`: `x` must be a mapview object, an htmlwidget, an sf ",
      "object, or a path to an .html file."
    ),
    call. = FALSE
  )
}

.serve_html_mount_file <- function(path, server = NULL) {
  if (length(path) != 1L || !nzchar(path)) {
    stop(
      "[ERROR] `{misc}`: `x` must be a single non-empty path.",
      call. = FALSE
    )
  }
  if (!fs::file_exists(path)) {
    stop(
      paste0("[ERROR] `{misc}`: ", path, " does not exist."),
      call. = FALSE
    )
  }
  if (!tolower(tools::file_ext(path)) %in% c("html", "htm")) {
    stop(
      "[ERROR] `{misc}`: `x` must be a path to an .html file.",
      call. = FALSE
    )
  }

  # Mount the containing directory so sibling assets (a Quarto `_files/`
  # directory, for instance) are served without copying them.
  path <- fs::path_abs(path)
  mount <- basename(tempfile(""))
  mount_spec <- list(dirname(path))
  names(mount_spec) <- paste0("/", mount)
  server$setStaticPath(.list = mount_spec)
  paste0(mount, "/", basename(path))
}

.serve_html_url <- function(rel, host = NULL, server = NULL) {
  host <- .serve_plots_host(host)

  if (is.null(host)) {
    warning(
      paste0(
        "[WARNING] `{misc}`: Could not resolve a remote-reachable hostname; ",
        "falling back to 127.0.0.1, which will not resolve from another ",
        "device. Set it with MISC_PLOTS_HOST or ",
        "options(misc.plots_host = \"...\")."
      ),
      call. = FALSE
    )
    host <- "127.0.0.1"
  }

  paste0("http://", host, ":", server$getPort(), "/", rel)
}
