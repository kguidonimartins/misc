#' Serve R plots over HTTP for a remote browser
#'
#' Starts an [httpgd::hgd()] graphics device bound to all interfaces and
#' returns a URL that is reachable from another device, such as an iPad
#' running a terminal over SSH or mosh.
#'
#' @param host Hostname to advertise in the URL. If `NULL`, resolved from
#'   configuration and from the Tailscale node name (see Details).
#' @param port Port to bind. The default `0` lets the operating system pick a
#'   free port, which avoids clashing with other local servers.
#' @param bind Address to bind the server to. Defaults to `"0.0.0.0"` so the
#'   device answers on every interface; use `"127.0.0.1"` to keep it local.
#' @param token Access token, passed to [httpgd::hgd()]. `TRUE` (default)
#'   generates one and embeds it in the returned URL.
#' @param quiet If `TRUE`, do not message the URL.
#' @param ... Further arguments passed to [httpgd::hgd()], such as `width`,
#'   `height`, `zoom`, or `bg`.
#'
#' @return The plot URL, invisibly, as a character scalar.
#'
#' @importFrom jsonlite fromJSON
#'
#' @details
#' `httpgd` advertises its server under the local mDNS name (for example
#' `machine.local`). That name only resolves through multicast on the same
#' physical network, so it is useless from a tablet connected over a VPN and
#' is the usual reason a pasted URL loads nothing. `serve_plots()` replaces
#' that hostname with one the remote device can actually resolve.
#'
#' The advertised hostname is resolved in this order:
#'
#' 1. the `host` argument;
#' 2. the `MISC_PLOTS_HOST` environment variable;
#' 3. `options(misc.plots_host = "...")`;
#' 4. the Tailscale MagicDNS name of this machine, read from
#'    `tailscale status --json`;
#' 5. the `httpgd` default, with a warning that it may not resolve remotely.
#'
#' The device lives as long as the R session. Call [grDevices::dev.off()] to
#' stop it, or [serve_plots_url()] to recover the URL of a running device.
#'
#' Binding to `0.0.0.0` exposes the device to every machine that can reach
#' this host on that port. Keep `token = TRUE` unless the network is trusted.
#'
#' @family data-viewers
#' @seealso [serve_plots_url()]
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   serve_plots()
#'   plot(1:10)
#'
#'   # pin the hostname when Tailscale is not in use
#'   serve_plots(host = "192.168.0.10")
#' }
#' }
serve_plots <- function(host = NULL, port = 0, bind = "0.0.0.0",
                        token = TRUE, quiet = FALSE, ...) {
  check_require("httpgd")

  if (!is.numeric(port) || length(port) != 1L || is.na(port) || port < 0) {
    stop(
      "[ERROR] `{misc}`: `port` must be a single non-negative number.",
      call. = FALSE
    )
  }
  if (!is.character(bind) || length(bind) != 1L || !nzchar(bind)) {
    stop(
      "[ERROR] `{misc}`: `bind` must be a single non-empty string.",
      call. = FALSE
    )
  }

  httpgd::hgd(host = bind, port = port, token = token, silent = TRUE, ...)

  url <- .serve_plots_build_url(host)

  if (!quiet) {
    message("[INFO] `{misc}`: Plots served at ", url)
  }

  invisible(url)
}

#' Recover the URL of a running plot server
#'
#' Rebuilds the remote-reachable URL of the `httpgd` device started by
#' [serve_plots()], for when the URL scrolled out of the terminal.
#'
#' @inheritParams serve_plots
#'
#' @return The plot URL, invisibly, as a character scalar.
#'
#' @family data-viewers
#' @seealso [serve_plots()]
#' @export
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   serve_plots()
#'   serve_plots_url()
#' }
#' }
serve_plots_url <- function(host = NULL, quiet = FALSE) {
  check_require("httpgd")

  url <- .serve_plots_build_url(host)

  if (!quiet) {
    message("[INFO] `{misc}`: Plots served at ", url)
  }

  invisible(url)
}

.serve_plots_build_url <- function(host = NULL) {
  details <- tryCatch(
    httpgd::hgd_details(),
    error = function(e) NULL
  )
  if (is.null(details)) {
    stop(
      paste0(
        "[ERROR] `{misc}`: No httpgd device is active. Start one with ",
        "serve_plots()."
      ),
      call. = FALSE
    )
  }

  host <- .serve_plots_host(host)

  if (is.null(host)) {
    warning(
      paste0(
        "[WARNING] `{misc}`: Could not resolve a remote-reachable hostname; ",
        "falling back to the local httpgd name, which may not resolve from ",
        "another device. Set it with MISC_PLOTS_HOST or ",
        "options(misc.plots_host = \"...\")."
      ),
      call. = FALSE
    )
    return(httpgd::hgd_url())
  }

  httpgd::hgd_url(host = host)
}

.serve_plots_host <- function(host = NULL) {
  if (!is.null(host)) {
    if (!is.character(host) || length(host) != 1L || !nzchar(host)) {
      stop(
        "[ERROR] `{misc}`: `host` must be a single non-empty string.",
        call. = FALSE
      )
    }
    return(host)
  }

  env_host <- Sys.getenv("MISC_PLOTS_HOST")
  if (nzchar(env_host)) {
    return(env_host)
  }

  option_host <- getOption("misc.plots_host")
  if (!is.null(option_host) && length(option_host) == 1L && nzchar(option_host)) {
    return(option_host)
  }

  .tailscale_dns_name()
}

.tailscale_cli <- function(candidates = c(
                             "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
                             "/usr/bin/tailscale",
                             "/usr/local/bin/tailscale"
                           )) {
  on_path <- Sys.which("tailscale")
  if (nzchar(on_path)) {
    return(unname(on_path))
  }
  found <- candidates[file.exists(candidates)]
  if (length(found) > 0L) {
    return(found[[1L]])
  }
  NULL
}

.tailscale_dns_name <- function(cli = .tailscale_cli()) {
  if (is.null(cli)) {
    return(NULL)
  }
  json <- tryCatch(
    suppressWarnings(
      system2(cli, c("status", "--json"), stdout = TRUE, stderr = FALSE)
    ),
    error = function(e) NULL
  )
  if (is.null(json) || length(json) == 0L) {
    return(NULL)
  }
  .tailscale_dns_from_json(paste(json, collapse = "\n"))
}

.tailscale_dns_from_json <- function(json) {
  parsed <- tryCatch(
    jsonlite::fromJSON(json, simplifyVector = TRUE),
    error = function(e) NULL
  )
  if (is.null(parsed)) {
    return(NULL)
  }
  if (!identical(parsed[["BackendState"]], "Running")) {
    return(NULL)
  }
  dns <- parsed[["Self"]][["DNSName"]]
  if (is.null(dns) || length(dns) != 1L || !nzchar(dns)) {
    return(NULL)
  }
  dns <- sub("\\.$", "", dns)
  if (!nzchar(dns)) {
    return(NULL)
  }
  dns
}
