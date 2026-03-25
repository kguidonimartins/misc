# Nesse arquivo vamos trabalhar em funções para a leitura de arquivos
# geoespaciais. Especificamente, arquivos `shp`, `gpkg`, `kmz`, `kml`,
# `zip` e `gdb`. Exceto os arquivos `zip` e `kmz`, todos os outros
# tipos podem ser lidos pelo pacote `sf`. Um detalhe que deve ser
# levado em consideração é que os arquivos `zip`, `kmz` e `gdb` podem
# ter mais uma camada (layer). Quando utilizamos o sf para ler um
# arquivo `gdb`, por exemplo, as funções `sf::st_read` ou
# `sf::read_sf` sempre selecionam a primeira camada da lista. O
# arquivo `zip` depende de uma adaptação para a leitura (via
# `/vsizip/`). No entanto, um `zip` também pode conter mais de um
# arquivo geoespacial (shapefile). Isso precisa ser verificado antes
# usando a função `zip::zip_list()`. Já os arquivos `kmz` são um caso
# especial. Eles são arquivos compactados que o pacote `sf` não
# consegue ler. Porém o `sf` é capaz de ler suas versões
# descompactadas em `kml`. O pacote keyholeio tem funções para lidar
# com isso (ver https://github.com/kissmygritts/keyholeio). No
# entanto, um arquivo `kmz` pode conter mais de uma camada, mesmo após
# sua extração para `kml`. O pacote `keyholeio` não faz essa distinção
# e acaba mesclando o conteúdo das camadas (via `rbind`).
#
# Em um fluxo ideal, ao ler arquivos compactados como `zip`, `kmz` ou
# `gdb`, o usuário deve ser informado quantas camadas existem. E se
# elas forem mescladas, uma coluna com o `layer_name` deve ser
# adicionada na primeira posição da tabela de atributos. Além, essas
# camadas podem ter projeções distintas (distintos CRS), impedindo sua
# mesclagem diretamente. Nesse caso, a melhor estratégia seria ler
# cada camada independentemente. O contéudo da tabela de atributos de
# cada camada deve ser inserida em uma list-columns (ver
# https://jennybc.github.io/purrr-tutorial/ls13_list-columns.html). Assim,
# o contéudo retornado após a leitura de um arquivo compactado deve ser
# uma tibble com `fpath`, `file_type`, `layer_name`, metadados de
# `sf::st_layers()` (`geometry_type`, contagem de feições/campos, `crs_name`)
# e a coluna `data` (list-column de objetos `sf`).
#
# Uma forma de verificar a existência de mais uma camada é usando a função `sf::st_layers()`
#
# `read_kmz()` extrai o KMZ para um diretório temporário e lê os KML com `sf`,
# uma camada de cada vez (sem depender do pacote `keyholeio`). Em `read_kmz()`,
# `fpath` na tibble devolvida é o caminho do arquivo `.kmz` de origem, não do KML temporário.
# `read_geo()` escolhe entre zip, kmz, kml, gdb e leitura genérica `sf` pela extensão do caminho.

.read_geo_check_path <- function(path) {
  p <- fs::path_expand(path)
  if (!fs::dir_exists(p) && !fs::file_exists(p)) {
    stop("Path not found: ", p, call. = FALSE)
  }
  normalizePath(p, winslash = "/", mustWork = TRUE)
}

.read_geo_crs_input <- function(crs_obj) {
  if (is.null(crs_obj)) {
    return(NA_character_)
  }
  if (is.list(crs_obj) && !is.null(crs_obj$input)) {
    return(as.character(crs_obj$input))
  }
  NA_character_
}

.read_geo_row_meta <- function(dsn, gdal_layer_name, sf_obj) {
  ly <- tryCatch(sf::st_layers(dsn), error = function(e) NULL)
  i <- if (!is.null(ly)) match(gdal_layer_name, ly$name) else NA_integer_

  if (is.null(ly) || is.na(i)) {
    gt <- unique(as.character(sf::st_geometry_type(sf_obj)))
    return(list(
      geometry_type = paste(gt, collapse = ", "),
      nrows_aka_features = as.integer(nrow(sf_obj)),
      ncols_aka_fields = as.integer(max(0L, ncol(sf_obj) - 1L)),
      crs_name = tryCatch(sf::st_crs(sf_obj)$input, error = function(e) NA_character_)
    ))
  }

  gt_raw <- ly$geomtype[[i]]
  geometry_type <- paste(as.character(unlist(gt_raw)), collapse = ", ")

  list(
    geometry_type = geometry_type,
    nrows_aka_features = as.integer(ly$features[i]),
    ncols_aka_fields = as.integer(ly$fields[i]),
    crs_name = .read_geo_crs_input(ly$crs[[i]])
  )
}

.read_geo_make_row <- function(fpath, file_type, layer_name, dsn, gdal_layer_name, data) {
  m <- .read_geo_row_meta(dsn, gdal_layer_name, data)
  list(
    fpath = fpath,
    file_type = file_type,
    layer_name = layer_name,
    geometry_type = m$geometry_type,
    nrows_aka_features = m$nrows_aka_features,
    ncols_aka_fields = m$ncols_aka_fields,
    crs_name = m$crs_name,
    data = data
  )
}

.read_geo_build_result <- function(row_specs) {
  if (length(row_specs) == 0L) {
    stop("No spatial layers to return.", call. = FALSE)
  }
  dplyr::tibble(
    fpath = vapply(row_specs, function(r) r$fpath, character(1)),
    file_type = vapply(row_specs, function(r) r$file_type, character(1)),
    layer_name = vapply(row_specs, function(r) r$layer_name, character(1)),
    geometry_type = vapply(row_specs, function(r) r$geometry_type, character(1)),
    nrows_aka_features = vapply(row_specs, function(r) r$nrows_aka_features, integer(1)),
    ncols_aka_fields = vapply(row_specs, function(r) r$ncols_aka_fields, integer(1)),
    crs_name = vapply(row_specs, function(r) r$crs_name, character(1)),
    data = purrr::map(row_specs, ~ .x$data)
  )
}

.read_geo_read_sf_dsn <- function(path, layer = NULL, quiet = TRUE, ...) {
  meta <- sf::st_layers(path)
  nms <- meta$name

  if (!is.null(layer)) {
    if (length(layer) != 1L || !nzchar(layer)) {
      stop("`layer` must be NULL or a single non-empty character string.", call. = FALSE)
    }
    if (!layer %in% nms) {
      stop("Layer not found in data source: ", layer, call. = FALSE)
    }
    nms <- layer
  }

  ft <- tolower(tools::file_ext(path))
  rows <- vector("list", length(nms))
  for (j in seq_along(nms)) {
    l <- nms[[j]]
    obj <- sf::read_sf(path, layer = l, quiet = quiet, ...)
    rows[[j]] <- .read_geo_make_row(
      fpath = path,
      file_type = ft,
      layer_name = l,
      dsn = path,
      gdal_layer_name = l,
      data = obj
    )
  }
  .read_geo_build_result(rows)
}

.read_geo_read_kml_path <- function(path, layer = NULL, quiet = TRUE, ...) {
  path <- .read_geo_check_path(path)
  kp <- path
  meta_full <- sf::st_layers(kp)
  n_layers_src <- length(meta_full$name)
  nms <- meta_full$name

  if (!is.null(layer)) {
    if (length(layer) != 1L || !nzchar(layer)) {
      stop("`layer` must be NULL or a single non-empty character string.", call. = FALSE)
    }
    if (!layer %in% nms) {
      stop("Layer not found in KML: ", layer, call. = FALSE)
    }
    nms <- layer
  }

  rows <- vector("list", length(nms))
  for (j in seq_along(nms)) {
    ln <- nms[[j]]
    obj <- sf::read_sf(kp, layer = ln, quiet = quiet, ...)
    key <- if (n_layers_src == 1L) {
      ln
    } else {
      paste0(fs::path_file(kp), "::", ln)
    }
    rows[[j]] <- .read_geo_make_row(
      fpath = path,
      file_type = "kml",
      layer_name = key,
      dsn = kp,
      gdal_layer_name = ln,
      data = obj
    )
  }
  .read_geo_build_result(rows)
}

#' Read layers from a file geodatabase (.gdb)
#'
#' @param path Path to a `.gdb` directory (the folder whose name ends in
#'   `.gdb`).
#' @param layer If `NULL` (default), every layer reported by [sf::st_layers()]
#'   is read. If a character string, only that layer is read; it must exist in
#'   the geodatabase.
#' @param quiet Passed to [sf::read_sf()].
#' @param ... Additional arguments passed to [sf::read_sf()].
#'
#' @return A tibble with columns `fpath` (path or GDAL dsn used for the layer),
#'   `file_type` ([tools::file_ext()]), `layer_name`, `geometry_type`, `nrows_aka_features`,
#'   `ncols_aka_fields`, `crs_name` (from `st_layers()$crs` when available), and
#'   `data` (list-column of [sf::sf] objects). Layers are not row-bound; differing CRS are preserved
#'   per row.
#'
#' @importFrom dplyr tibble
#' @importFrom fs dir_exists file_exists path_expand
#' @importFrom purrr map
#' @importFrom sf read_sf st_crs st_geometry_type st_layers
#' @importFrom tools file_ext
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_gdb("path/to/data.gdb")
#' read_gdb("path/to/data.gdb", layer = "my_layer")
#' }
read_gdb <- function(path, layer = NULL, quiet = TRUE, ...) {
  path <- .read_geo_check_path(path)
  .read_geo_read_sf_dsn(path, layer, quiet, ...)
}

#' Read shapefile(s) inside a ZIP archive via GDAL `/vsizip/`
#'
#' Uses [zip::zip_list()] to find `.shp` members, then reads each with
#' [sf::read_sf()] on a `/vsizip/...` path. Multiple shapefiles become one row
#' each (list-column `data`), so differing CRS are not merged.
#'
#' @param path Path to a `.zip` file.
#' @param quiet Passed to [sf::read_sf()].
#' @param ... Additional arguments passed to [sf::read_sf()].
#'
#' @return A tibble with `fpath` (the `/vsizip/...` dsn), `file_type`, metadata
#'   from [sf::st_layers()], and `data` (list-column of `sf`). See [read_gdb()].
#'
#' @importFrom dplyr tibble
#' @importFrom purrr imap map
#' @importFrom sf read_sf st_layers
#' @importFrom tools file_ext
#' @importFrom zip zip_list
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_sf_zip("path/to/data.zip")
#' }
read_sf_zip <- function(path, quiet = TRUE, ...) {
  path <- .read_geo_check_path(path)
  zl <- zip::zip_list(path)
  fn <- zl$filename
  shps <- fn[grepl("\\.shp$", fn, ignore.case = TRUE)]
  shps <- unique(shps)
  if (length(shps) == 0L) {
    stop("No .shp file found inside the ZIP archive.", call. = FALSE)
  }

  zip_abs <- normalizePath(path, winslash = "/", mustWork = TRUE)
  layer_names <- sub("\\.shp$", "", basename(shps), ignore.case = TRUE)
  if (anyDuplicated(layer_names)) {
    layer_names <- gsub("\\\\", "/", shps)
  }
  names(shps) <- layer_names

  rows <- unname(purrr::imap(shps, function(entry, lyr_display) {
    entry <- gsub("\\\\", "/", entry)
    vsip <- paste0("/vsizip/", zip_abs, "/", entry)
    ly <- sf::st_layers(vsip)
    gdal_name <- ly$name[[1]]
    obj <- sf::read_sf(vsip, layer = gdal_name, quiet = quiet, ...)
    .read_geo_make_row(
      fpath = vsip,
      file_type = tolower(tools::file_ext(entry)),
      layer_name = lyr_display,
      dsn = vsip,
      gdal_layer_name = gdal_name,
      data = obj
    )
  }))

  .read_geo_build_result(rows)
}

#' Read a KMZ file (KML in a ZIP)
#'
#' Extracts the archive to a temporary directory and reads each KML layer with
#' [sf::read_sf()] after [sf::st_layers()]. Multiple KML files or multiple
#' layers yield one row per layer; `layer_name` is simplified when there is only
#' one layer in one file.
#'
#' @param path Path to a `.kmz` file.
#' @param quiet Passed to [sf::read_sf()].
#' @param ... Additional arguments passed to [sf::read_sf()].
#'
#' @return A tibble with the same columns as [read_gdb()]. Here `fpath` is the
#'   path to the original `.kmz` (not the temporary `.kml`), and `file_type` is
#'   typically `"kmz"`. Metadata columns still come from [sf::st_layers()] on the
#'   extracted KML file used for reading.
#'
#' @importFrom dplyr tibble
#' @importFrom fs dir_create dir_ls
#' @importFrom sf read_sf st_layers
#' @importFrom tools file_ext
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_kmz("path/to/data.kmz")
#' }
read_kmz <- function(path, quiet = TRUE, ...) {
  path <- .read_geo_check_path(path)
  exdir <- tempfile("kmz_")
  fs::dir_create(exdir)
  on.exit(unlink(exdir, recursive = TRUE), add = TRUE)

  utils::unzip(path, exdir = exdir)
  kml_paths <- fs::dir_ls(exdir, regexp = "\\.[kK][mM][lL]$", recurse = TRUE)
  if (length(kml_paths) == 0L) {
    stop("No .kml file found inside the KMZ.", call. = FALSE)
  }

  kml_paths <- normalizePath(kml_paths, winslash = "/", mustWork = TRUE)
  exdir_n <- normalizePath(exdir, winslash = "/", mustWork = TRUE)

  rows <- list()
  multiple_total <- sum(vapply(kml_paths, function(kp) length(sf::st_layers(kp)$name), 0L))

  for (kp in kml_paths) {
    layers <- sf::st_layers(kp)
    for (ln in layers$name) {
      obj <- sf::read_sf(kp, layer = ln, quiet = quiet, ...)
      key <- if (length(kml_paths) == 1L && length(layers$name) == 1L && multiple_total == 1L) {
        ln
      } else {
        rel <- sub(paste0("^", exdir_n, "/"), "", kp)
        paste0(rel, "::", ln)
      }
      rows[[length(rows) + 1L]] <- .read_geo_make_row(
        fpath = path,
        file_type = tolower(tools::file_ext(path)),
        layer_name = key,
        dsn = kp,
        gdal_layer_name = ln,
        data = obj
      )
    }
  }

  .read_geo_build_result(rows)
}

#' Read a geospatial file or dataset (auto-detect by extension)
#'
#' Chooses the reader from `tools::file_ext(path)` (case-insensitive):
#' * `.zip` — [read_sf_zip()]
#' * `.kmz` — [read_kmz()]
#' * `.kml` — internal KML reader (same tibble layout; `fpath` is the `.kml` file)
#' * `.gdb` — [read_gdb()]
#' * anything else GDAL/`sf` can open on `path` — one row per layer from
#'   [sf::st_layers()] (e.g. `.shp`, `.gpkg`, `.geojson`)
#'
#' @param path Path to a spatial file or a `.gdb` directory.
#' @param layer Passed to multi-layer GDAL readers. Ignored for `.zip` and `.kmz`.
#' @inheritParams read_gdb
#'
#' @return A tibble as described in [read_gdb()].
#'
#' @importFrom dplyr tibble
#' @importFrom fs path_file
#' @importFrom purrr map
#' @importFrom sf read_sf st_layers
#' @importFrom tools file_ext
#'
#' @export
#'
#' @examples
#' \dontrun{
#' read_geo("areas.zip")
#' read_geo("overlay.kmz")
#' read_geo("data.gpkg")
#' read_geo("file.gdb", layer = "parcels")
#' }
read_geo <- function(path, layer = NULL, quiet = TRUE, ...) {
  path <- .read_geo_check_path(path)
  ext <- tolower(tools::file_ext(path))
  switch(ext,
    zip = read_sf_zip(path, quiet = quiet, ...),
    kmz = read_kmz(path, quiet = quiet, ...),
    kml = .read_geo_read_kml_path(path, layer = layer, quiet = quiet, ...),
    gdb = read_gdb(path, layer = layer, quiet = quiet, ...),
    .read_geo_read_sf_dsn(path, layer, quiet = quiet, ...)
  )
}
