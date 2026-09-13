# serve_html -------------------------------------------------------------------

test_that("slug keeps a random component and sanitizes labels", {
  expect_match(.serve_html_slug(), "^[A-Za-z0-9]+$")
  expect_false(identical(.serve_html_slug(), .serve_html_slug()))

  expect_match(.serve_html_slug("Mapa Final"), "^Mapa-Final-[A-Za-z0-9]+$")
  expect_match(.serve_html_slug("a/b c__d"), "^a-b-c-d-[A-Za-z0-9]+$")
  expect_match(.serve_html_slug("!!!"), "^[A-Za-z0-9]+$")
})

test_that("slug rejects malformed labels", {
  expect_error(.serve_html_slug(""), "single non-empty string")
  expect_error(.serve_html_slug(c("a", "b")), "single non-empty string")
  expect_error(.serve_html_slug(1L), "single non-empty string")
})

test_that("slug does not disturb the random seed", {
  set.seed(42)
  expected <- runif(1)
  set.seed(42)
  invisible(.serve_html_slug("whatever"))
  expect_identical(runif(1), expected)
})

test_that("widget coercion handles htmlwidgets and rejects other inputs", {
  widget <- structure(list(x = 1), class = "htmlwidget")
  expect_identical(.serve_html_as_widget(widget), widget)

  expect_error(.serve_html_as_widget(data.frame(x = 1)), "must be a mapview")
  expect_error(.serve_html_as_widget(1:3), "must be a mapview")
  expect_error(.serve_html_as_widget(NULL), "must be a mapview")
})

test_that("mapview objects are unwrapped to their leaflet slot", {
  skip_if_not_installed("mapview")
  skip_if_not_installed("sf")
  pts <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)
  )
  widget <- .serve_html_as_widget(mapview::mapview(pts))
  expect_s3_class(widget, "htmlwidget")
})

test_that("file mounting validates paths", {
  expect_error(.serve_html_mount_file(""), "single non-empty path")
  expect_error(
    .serve_html_mount_file(tempfile("missing-", fileext = ".html")),
    "does not exist"
  )

  not_html <- withr::local_tempfile(fileext = ".txt")
  writeLines("x", not_html)
  expect_error(.serve_html_mount_file(not_html), "must be a path to an .html")
})

test_that("serve_html validates bind", {
  skip_if_not_installed("httpuv")
  expect_error(serve_html(mtcars, bind = ""), "single non-empty string")
})

test_that("serve_html serves widgets and reuses one server per session", {
  skip_if_not_installed("httpuv")
  skip_if_not_installed("htmlwidgets")
  skip_if_not_installed("leaflet")
  skip_on_cran()

  old_option <- getOption("misc.plots_host")
  on.exit({
    options(misc.plots_host = old_option)
    serve_html_stop(quiet = TRUE)
  }, add = TRUE)
  options(misc.plots_host = "example-host")

  map <- leaflet::leaflet()

  first <- serve_html(map, name = "primeiro", bind = "127.0.0.1", quiet = TRUE)
  expect_match(first, "^http://example-host:[0-9]+/primeiro-[A-Za-z0-9]+\\.html$")

  second <- serve_html(map, name = "segundo", bind = "127.0.0.1", quiet = TRUE)
  expect_match(second, "segundo-")

  # same server, so earlier URLs stay valid
  port_of <- function(u) sub("^http://[^:]+:([0-9]+)/.*$", "\\1", u)
  expect_identical(port_of(first), port_of(second))

  local_url <- sub("example-host", "127.0.0.1", first)
  expect_identical(
    attr(curlGetHeaders(local_url), "status"),
    200L
  )
})

test_that("serve_html mounts an on-disk report with its asset directory", {
  skip_if_not_installed("httpuv")
  skip_on_cran()

  old_option <- getOption("misc.plots_host")
  on.exit({
    options(misc.plots_host = old_option)
    serve_html_stop(quiet = TRUE)
  }, add = TRUE)
  options(misc.plots_host = "example-host")

  dir <- withr::local_tempdir()
  report <- file.path(dir, "report.html")
  writeLines("<h1>report</h1>", report)
  dir.create(file.path(dir, "report_files"))
  writeLines("body{}", file.path(dir, "report_files", "style.css"))

  url <- serve_html(report, bind = "127.0.0.1", quiet = TRUE)
  expect_match(url, "/[A-Za-z0-9]+/report\\.html$")

  local_url <- sub("example-host", "127.0.0.1", url)
  expect_identical(attr(curlGetHeaders(local_url), "status"), 200L)

  asset_url <- sub("report\\.html$", "report_files/style.css", local_url)
  expect_identical(attr(curlGetHeaders(asset_url), "status"), 200L)
})

test_that("directory listing is not exposed", {
  skip_if_not_installed("httpuv")
  skip_if_not_installed("leaflet")
  skip_on_cran()

  on.exit(serve_html_stop(quiet = TRUE), add = TRUE)
  url <- serve_html(leaflet::leaflet(), bind = "127.0.0.1", quiet = TRUE,
                    host = "127.0.0.1")
  root <- sub("/[^/]+$", "/", url)
  expect_false(identical(attr(curlGetHeaders(root), "status"), 200L))
})

test_that("serve_html_stop reports whether a server was running", {
  skip_if_not_installed("httpuv")
  skip_if_not_installed("leaflet")
  skip_on_cran()

  serve_html(leaflet::leaflet(), bind = "127.0.0.1", quiet = TRUE,
             host = "127.0.0.1")
  expect_true(serve_html_stop(quiet = TRUE))
  expect_false(serve_html_stop(quiet = TRUE))
})
