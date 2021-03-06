#' Remove white spaces around figures
#'
#' @description
#' `trim_fig()` just remove white spaces around a figure and save it into the
#' `trim` folder (maintain the original figure untouchable)
#'
#' @param figure_path a character vector with path of the figure
#' @param overwrite logical
#'
#' @importFrom fs file_exists dir_create
#' @importFrom here here
#' @importFrom usethis ui_stop ui_field ui_todo ui_done
#'
#' @export
#'
#' @section Acknowledgment:
#' `trim_fig()` wraps the excellent `image_trim()` of
#' [`{magick}`](https://github.com/ropensci/magick)
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
#' trim_fig("output/figures/p.png")
#' }
trim_fig <- function(figure_path, overwrite = FALSE) {
  check_require("magick")
  if (!fs::file_exists(figure_path)) {
    usethis::ui_stop("{usethis::ui_field(here::here(figure_path))} does not exists!")
  }
  fig_dirname <- dirname(figure_path)
  fig_name <- basename(figure_path)
  fig_dir_trim <- paste0(fig_dirname, "/", "trim/")
  fs::dir_create(fig_dir_trim)
  name_to_save <- paste0(fig_dir_trim, fig_name)
  make_trim_fig <- function(figure_path, name_to_save) {
    fig <- magick::image_read(figure_path)
    fig_trim <- magick::image_trim(fig)
    magick::image_write(image = fig_trim, path = name_to_save)
  }
  if (!fs::file_exists(name_to_save)) {
    usethis::ui_todo("Saving {usethis::ui_field(here::here(name_to_save))}...")
    make_trim_fig(figure_path = figure_path, name_to_save = name_to_save)
    usethis::ui_done("{usethis::ui_field(here::here(name_to_save))} saved!")
  } else if (overwrite) {
    usethis::ui_todo("Overwriting {usethis::ui_field(here::here(name_to_save))}...")
    unlink(name_to_save)
    make_trim_fig(figure_path = figure_path, name_to_save = name_to_save)
    usethis::ui_done("{usethis::ui_field(here::here(name_to_save))} saved!")
  } else {
    usethis::ui_info("File {usethis::ui_field(here::here(name_to_save))} already exists! Use overwrite = TRUE.")
  }
}
