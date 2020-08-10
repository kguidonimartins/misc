#' Save a ggplot figure
#'
#' @description
#' `save_plot()` wraps `ggplot2::ggsave()` and offer option to remove white
#' spaces around figures (creates a additional file in `output/figures/trim`;
#' uses \code{\link{trim_fig}})
#'
#' @param object a ggplot object
#' @param filename a character vector with the name of the file to save. Default is NULL and saves with the name of the object
#' @param dir_to_save a character vector with the name of the directory to save
#' @param width a numerical vector with the width of the figure
#' @param height a numerical vector with the height of the figure
#' @param format a character vector with format of the figure. Can "jpeg", "tiff", "png" (default), or "pdf"
#' @param units a character vector with the units of the figure size. Can be "in", "cm" (default), or "mm"
#' @param dpi a numerical vector with the resolution of the figure. Default is 300
#' @param overwrite logical
#' @param trim logical
#'
#' @importFrom fs dir_exists file_exists
#' @importFrom ggplot2 ggsave
#' @importFrom here here
#' @importFrom usethis ui_stop ui_field ui_todo ui_done ui_info
#'
#' @export
#'
#' @section Acknowledgment:
#' `save_plot()` is derived from
#' [`write_plot()`](https://github.com/globeandmail/startr/blob/fff446f5a07a67f565a7bae887f0cdd24c808cdb/R/utils.R#L157),
#' available in the excellent
#' [`start`](https://github.com/globeandmail/startr) project template
#'
#' @examples
#' \dontrun{
#' library(misc)
#' ipak(c("ggplot2", "dplyr"))
#' create_dirs()
#' p <- mtcars %>%
#'   ggplot() +
#'   aes(x = mpg, y = cyl) +
#'   geom_point()
#' save_plot(p)
#' }
save_plot <- function(object, filename = NULL, dir_to_save = NULL, width = NA, height = NA, format = NULL, units = NULL, dpi = NULL, overwrite = FALSE, trim = FALSE) {
  default_format <- "png"
  default_units <- "cm"
  default_dpi <- 300
  default_filename <- deparse(substitute(object))
  default_dir_to_save <- "output/figures/"

  if (!is.null(format)) default_format <- format
  if (!is.null(units)) default_units <- units
  if (!is.null(dpi)) default_dpi <- dpi
  if (!is.null(filename)) default_filename <- filename

  if (is.null(dir_to_save)) {
    dir_to_save <- "output/figures"
    if (!fs::dir_exists(dir_to_save)) {
      usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs()`")
    }
  }
  if (!fs::dir_exists(dir_to_save)) {
    usethis::ui_stop("{usethis::ui_field(here::here(dir_to_save))} does not exists! Use `misc::create_dirs('{ui_field(dir_to_save)}')` before.")
  }
  name_to_save <- paste0(dir_to_save, "/", default_filename, ".", default_format)
  args <- list(
    plot = object,
    file = name_to_save,
    units = default_units,
    dpi = default_dpi,
    width = width,
    height = height
  )
  if (default_format == "pdf") args[["useDingbats"]] <- FALSE
  if (!fs::file_exists(name_to_save)) {
    usethis::ui_todo("Saving {usethis::ui_field(here::here(name_to_save))}...")
    do.call(ggplot2::ggsave, args)
    usethis::ui_done("{usethis::ui_field(here::here(name_to_save))} saved!")
  } else if (overwrite) {
    usethis::ui_todo("Overwriting {usethis::ui_field(here::here(name_to_save))}...")
    unlink(name_to_save)
    do.call(ggplot2::ggsave, args)
    usethis::ui_done("{usethis::ui_field(here::here(name_to_save))} saved!")
  } else {
    usethis::ui_info("File {usethis::ui_field(here::here(name_to_save))} already exists! Use overwrite = TRUE.")
  }
  if (trim) {
    trim_fig(figure_path = name_to_save, overwrite = overwrite)
  }
}
