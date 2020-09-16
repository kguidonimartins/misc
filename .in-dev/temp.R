
cite_pkg <- function(pkg_list) {
  packages <- sort(pkg_list)
  cites <- lapply(packages, utils::citation)
  cites.bib <- lapply(cites, utils::toBibtex)

  # generate reference key
  for (i in seq_len(length(cites.bib))) {
    cites.bib[[i]] <-
      sub(
        pattern = "\\{,$",
        replacement = paste0("{", packages[i], ","),
        x = cites.bib[[i]]
      )
  }

  # write bibtex references to file
  if (!dir.exists("sources")) {
    dir.create("sources")
  }
  file.create("sources/pkg_list-refs.bib")
  writeLines(enc2utf8(unlist(cites.bib)), con = "sources/pkg_list-refs.bib", useBytes = TRUE)

  # return named list of bibtex references
  names(cites.bib) <- packages # pkgs

  writeLines(paste("- ", names(cites.bib), " [@", names(cites.bib), "]", sep = ""))
}


render_notebook <- function(notebook_file) {
  rmarkdown::render(
    notebook_file,
    output_dir = dir_reports,
    encoding = "utf-8"
  )
}

# FROM https://github.com/dgrtwo/drlib/blob/master/R/reorder_within.R

reorder_within <- function(x, by, within, fun = mean, sep = "___", ...) {
  new_x <- paste(x, within, sep = sep)
  stats::reorder(new_x, by, FUN = fun)
}

scale_x_reordered <- function(..., sep = "___") {
  reg <- paste0(sep, ".+$")
  ggplot2::scale_x_discrete(labels = function(x) gsub(reg, "", x), ...)
}

scale_y_reordered <- function(..., sep = "___") {
  reg <- paste0(sep, ".+$")
  ggplot2::scale_y_discrete(labels = function(x) gsub(reg, "", x), ...)
}

# https://github.com/kguidonimartins/monitora-derramamento-oleo/raw/gh-pages/data-raw/2020-03-19_LOCALIDADES_AFETADAS.xlsx

latitude_raw <- str_extract_all(df$latitude, "\\(?[0-9, ., A-Z]+\\)?")

latitude_separated <-
  data.frame(
    matrix(
      unlist(latitude_raw),
      nrow = length(latitude_raw),
      byrow = TRUE
    ),
    stringsAsFactors = FALSE
  ) %>%
  mutate_all(str_squish) %>%
  set_names(c("lat_graus", "lat_minutos", "lat_segundos", "lat_letra")) %>%
  mutate_at(vars("lat_graus", "lat_minutos", "lat_segundos"), as.numeric)

suppressWarnings(
  latitude_clean <- latitude_separated %>%
    mutate(
      latitude = from_dms_to_dd(
        lat_graus,
        lat_minutos,
        lat_segundos,
        lat_letra
      )
    ) %>%
    select(latitude)
)
