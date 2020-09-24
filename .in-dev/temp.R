
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


extract_docx_comments <- function(path_to_docx, dir_to_save = NULL) {
  obj_name <- path_to_docx %>%
    gsub(".docx", "_comments.csv", .)
  if (is.null(dir_to_save)) {
    dir_to_save <- "manuscript"
    if (!fs::dir_exists(dir_to_save)) {
      usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs()`")
    }
  }
  if (!fs::dir_exists(dir_to_save)) {
    usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs('{ui_field(dir_to_save)}')` before.")
  }
  name_to_save <- obj_name
  if (!fs::file_exists(name_to_save)) {
    usethis::ui_todo("Saving {usethis::ui_field(here::here(name_to_save))}...")
    path_to_docx %>%
      docxtractr::read_docx(track_changes = NULL) %>%
      docxtractr::docx_extract_all_cmnts(include_text = TRUE) %>%
      dplyr::select(id, date, author, word_src, comment_text) %>%
      readr::write_csv(path = name_to_save, quote_escape = "double")
    usethis::ui_done("{usethis::ui_field(here::here(name_to_save))} saved!")
  } else {
    usethis::ui_info("File {usethis::ui_field(here::here(name_to_save))} already exists!")
  }
}


update_description <- function(pkg_list) {
  has_tidy <- grepl(pattern = "tidyverse", x = pkg_list)

  if (sum(has_tidy) >= 1) {
    pkg_list <- pkg_list[!pkg_list %in% "tidyverse"]
    pkg_list <- c(pkg_list, c("ggplot2", "tibble", "tidyr", "readr", "purrr", "dplyr", "stringr", "forcats"))
  }

  pkg_list_github <- pkg_list[grep(pattern = "/", x = pkg_list)]
  pkg_list_cran <- pkg_list[!pkg_list %in% pkg_list_github]

  if (!file.exists(here::here("DESCRIPTION"))) {
    usethis::use_description(check_name = FALSE)
  }

  suppressMessages({
    pkg_list_cran %>%
      map(~ use_package(package = .x, type = "Imports"))
  })

  message(glue("Consider include {pkg_list_cran} into Remotes section of DESCRIPTION file"))
}
