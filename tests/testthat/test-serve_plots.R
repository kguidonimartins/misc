# serve_plots ------------------------------------------------------------------

ts_json <- function(dns = "exuh.tail04f3ab.ts.net.", state = "Running") {
  jsonlite::toJSON(
    list(BackendState = state, Self = list(DNSName = dns)),
    auto_unbox = TRUE
  )
}

test_that("tailscale DNS name is parsed and the trailing dot dropped", {
  expect_identical(
    .tailscale_dns_from_json(ts_json()),
    "exuh.tail04f3ab.ts.net"
  )
  expect_identical(
    .tailscale_dns_from_json(ts_json(dns = "exuh.tail04f3ab.ts.net")),
    "exuh.tail04f3ab.ts.net"
  )
})

test_that("tailscale DNS name is NULL when the backend is not running", {
  expect_null(.tailscale_dns_from_json(ts_json(state = "Stopped")))
  expect_null(.tailscale_dns_from_json(ts_json(state = "NeedsLogin")))
})

test_that("tailscale DNS name is NULL for unusable payloads", {
  expect_null(.tailscale_dns_from_json("not json at all"))
  expect_null(.tailscale_dns_from_json(ts_json(dns = "")))
  expect_null(
    .tailscale_dns_from_json(
      jsonlite::toJSON(list(BackendState = "Running"), auto_unbox = TRUE)
    )
  )
})

test_that("tailscale CLI lookup falls back to known install paths", {
  missing <- tempfile("misc-ts-missing-")
  expect_null(.tailscale_cli(candidates = missing))

  present <- tempfile("misc-ts-present-")
  file.create(present)
  on.exit(unlink(present), add = TRUE)
  expect_identical(.tailscale_cli(candidates = c(missing, present)), present)
})

test_that("host resolution honors argument, environment, and options", {
  old_env <- Sys.getenv("MISC_PLOTS_HOST", unset = NA_character_)
  old_option <- getOption("misc.plots_host")
  on.exit({
    if (is.na(old_env)) {
      Sys.unsetenv("MISC_PLOTS_HOST")
    } else {
      Sys.setenv(MISC_PLOTS_HOST = old_env)
    }
    options(misc.plots_host = old_option)
  }, add = TRUE)

  Sys.setenv(MISC_PLOTS_HOST = "host-env")
  options(misc.plots_host = "host-option")
  expect_identical(.serve_plots_host("host-arg"), "host-arg")
  expect_identical(.serve_plots_host(), "host-env")

  Sys.setenv(MISC_PLOTS_HOST = "")
  expect_identical(.serve_plots_host(), "host-option")
})

test_that("host resolution rejects malformed hosts", {
  expect_error(.serve_plots_host(""), "single non-empty string")
  expect_error(.serve_plots_host(c("a", "b")), "single non-empty string")
  expect_error(.serve_plots_host(1L), "single non-empty string")
})

test_that("serve_plots validates port and bind before starting a device", {
  skip_if_not_installed("httpgd")
  expect_error(serve_plots(port = -1), "non-negative")
  expect_error(serve_plots(port = "8000"), "non-negative")
  expect_error(serve_plots(bind = ""), "single non-empty string")
})

test_that("serve_plots_url errors when no httpgd device is active", {
  skip_if_not_installed("httpgd")
  expect_error(serve_plots_url(), "No httpgd device is active")
})

test_that("serve_plots advertises the configured host and a free port", {
  skip_if_not_installed("httpgd")
  skip_on_cran()

  old_option <- getOption("misc.plots_host")
  on.exit({
    options(misc.plots_host = old_option)
    while (grDevices::dev.cur() > 1L) grDevices::dev.off()
  }, add = TRUE)
  options(misc.plots_host = "example-host")

  url <- serve_plots(quiet = TRUE)

  expect_type(url, "character")
  expect_match(url, "^http://example-host:[0-9]+/live")
  expect_match(url, "token=")
  expect_identical(serve_plots_url(quiet = TRUE), url)

  port <- httpgd::hgd_details()$port
  expect_gt(port, 0L)
})

test_that("URL status is NA when the host cannot be reached", {
  expect_true(is.na(.serve_url_status("http://misc-nao-existe.invalid:1/live")))
})

test_that("an unreachable URL is announced without a warning", {
  url <- "http://misc-nao-existe.invalid:1/live?token=abc"
  expect_no_warning(.serve_announce(url, quiet = TRUE))
  expect_identical(.serve_announce(url, quiet = TRUE), url)
})

test_that("the announced URL sits on a line of its own", {
  url <- "http://misc-nao-existe.invalid:1/live?token=abc"
  expect_message(
    .serve_announce(url, label = "Plots served at"),
    paste0("Plots served at\n", url),
    fixed = TRUE
  )
})

test_that("a served URL answers, and a clipped one does not", {
  skip_if_not_installed("httpgd")
  skip_on_cran()
  skip_if_not(isTRUE(capabilities("libcurl")), "libcurl not available")

  on.exit({
    while (grDevices::dev.cur() > 1L) grDevices::dev.off()
  }, add = TRUE)

  url <- serve_plots(host = "127.0.0.1", bind = "127.0.0.1", quiet = TRUE)

  expect_identical(.serve_url_status(url), 200L)
  # The shapes a truncated or hand-typed URL takes on the way to a browser.
  expect_identical(.serve_url_status(sub("/live.*$", "/", url)), 404L)
  expect_identical(.serve_url_status(sub("\\?.*$", "/", url)), 404L)
  expect_identical(.serve_url_status(sub("\\?.*$", "", url)), 401L)
  expect_warning(.serve_warn_bad_status(sub("/live.*$", "/", url)), "HTTP 404")
})
