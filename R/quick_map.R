#' Create maps quickly
#'
#' @description
#' `quick_map()` allows the creation of maps quickly using `{ggplot2}`. For this
#' reason, the resulting map is fully editable through `{ggplot2}` layers.
#'
#' @param region character string or atomic vector containing countries names ou continents. Default is \code{NULL}.
#' @param type character string informing map type. Can be \code{"sf"} or \code{"ggplot"}
#'
#' @importFrom dplyr select filter_all any_vars mutate case_when pull
#' @importFrom ggplot2 ggplot geom_sf borders theme_bw labs theme element_blank element_line
#' @importFrom rnaturalearth ne_countries
#' @importFrom sf st_drop_geometry
#' @importFrom stringr str_detect
#'
#' @return a ggplot object
#'
#' @section Acknowledgment:
#' `quick_map()` depends heavily on the data available by
#' the [`{rnaturalearth}`](https://github.com/ropensci/rnaturalearth)
#' package. In this sense, `quick_map()` uses a wide and dirty filtering of
#' this data to create the map.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # plot a world map
#' quick_map()
#' # plot a new world map
#' quick_map(region = "Americas", type = "sf")
#' # using ggplot
#' quick_map(region = "Americas", type = "ggplot")
#' }
quick_map <- function(region = NULL, type = NULL) {
  world_data <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

  columns <- c(
    "continent",
    "region_un",
    "subregion",
    "region_wb",
    "name_sort",
    "formal_en",
    "name_long",
    "name",
    "sovereignt",
    "type",
    "admin",
    "geounit",
    "subunit",
    "iso_a2",
    "iso_a3"
  )

  if (is.null(region) && is.null(type)) {
    plot_map <-
      world_data %>%
      ggplot2::ggplot() +
      ggplot2::geom_sf()
  }

  if (!is.null(type)) {
    if (type == "sf") {
      data_filtered <-
        world_data %>%
        dplyr::select(!!columns) %>%
        dplyr::filter_all(., dplyr::any_vars(stringr::str_detect(., paste(region, collapse = "|"))))

      plot_map <-
        data_filtered %>%
        ggplot2::ggplot() +
        ggplot2::geom_sf()
    }

    if (type == "ggplot") {
      data_filtered <-
        world_data %>%
        sf::st_drop_geometry(x = .) %>%
        dplyr::select(!!columns) %>%
        dplyr::filter_all(., dplyr::any_vars(stringr::str_detect(., paste(region, collapse = "|")))) %>%
        dplyr::mutate(
          admin = dplyr::case_when(
            admin == "United States of America" ~ "USA",
            TRUE ~ as.character(admin)
          )
        ) %>%
        dplyr::pull(admin)

      map_borders <- ggplot2::borders(
        database = "world",
        regions = data_filtered,
        fill = "white",
        colour = "grey90"
      )

      plot_map <-
        ggplot2::ggplot() +
        map_borders +
        ggplot2::theme_bw() +
        ggplot2::labs(
          x = "Longitude (decimals)",
          y = "Latitude (decimals)"
        ) +
        ggplot2::theme(
          panel.border = ggplot2::element_blank(),
          panel.grid.major = ggplot2::element_line(colour = "grey80"),
          panel.grid.minor = ggplot2::element_blank()
        )
    }
  }
  return(plot_map)
}
