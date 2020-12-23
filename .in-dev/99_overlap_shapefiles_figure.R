# library(dplyr)
# library(maps)
# library(fs)
# library(sf)
# library(scales)
# library(purrr)
# library(readr)
# library(stringr)
# library(here)
# library(ggplot2)

# output <- fs::dir_create("output")

# plot_spp_range_by_trait <- function(trait) {
#   trait_spp <- dir_ls(path = "data", regexp = ".csv") %>%
#     map_dfr(~ read_csv(.x), .id = "trait_name") %>%
#     select(-X1) %>%
#     mutate(
#       trait_name = str_remove(trait_name, "data/"),
#       trait_name = str_remove(trait_name, "_spp_names_for_fig_poligons.csv")
#     ) %>%
#     filter(trait_name == {{ trait }})

#   spp_names <- unique(trait_spp$species)

#   shapes_spp <-
#     dir_ls(
#       path = "species_ranges_from_bien/",
#       recurse = TRUE,
#       regexp = "\\.shp$"
#     ) %>%
#     as_tibble() %>%
#     filter(str_detect(value, paste(spp_names, collapse = "|"))) %>%
#     pull() %>%
#     purrr::map(read_sf) %>%
#     purrr::map(st_set_precision, 1e7) %>%
#     # purrr::map(rename_all, str_to_lower) %>%
#     purrr::map(~ mutate(.x, "ID" = letters[1:n()])) %>%
#     purrr::map(~ dplyr::select(.x, "ID")) %>%
#     purrr::map(~ as_Spatial(.))

#   names_spp <-
#     dir_ls(
#       path = "species_ranges_from_bien/",
#       recurse = TRUE,
#       regexp = "\\.shp$"
#     ) %>%
#     as_tibble() %>%
#     filter(str_detect(value, paste(spp_names, collapse = "|"))) %>%
#     mutate(
#       value = basename(value),
#       value = str_remove(value, ".shp")
#     ) %>%
#     pull()

#   list_shapes <- shapes_spp

#   names(list_shapes) <- names_spp

#   shapes_fogo <- do.call(rbind, list_shapes)

#   shapes_fogo$ID

#   for (i in seq_along(shapes_fogo$ID)) {
#     shapes_fogo$ID[i] <- i
#   }

#   shapes_fogo$ID

#   colnames(shapes_fogo@data) <- "binomial"

#   pres_ab <-
#     letsR::lets.presab(
#       shapes = shapes_fogo,
#       xmn = -250,
#       xmx = 50,
#       ymn = -90,
#       ymx = 90,
#       resol = 1
#     )

#   plot(pres_ab)

#   data.frame(pres_ab$Presence_and_Absence_Matrix) %>%
#     write_csv(paste0(output, "/", trait, "_presence_and_absence_matrix.csv"))

#   fire_occ <- data.frame(pres_ab$Presence_and_Absence_Matrix)

#   fire_gradient <- cbind(fire_occ[, 1:2], apply(fire_occ[, -c(1, 2)], 1, sum))

#   names(fire_gradient) <- c("longitude", "latitude", "fire_gradient")

#   map_fire_gradient <-
#     fire_gradient %>%
#     ggplot(aes(x = longitude, y = latitude)) +
#     geom_raster(aes(fill = fire_gradient)) +
#     scale_fill_viridis_c() +
#     coord_equal() +
#     theme_void() +
#     labs(title = trait, fill = "Species range overlap")

#   ggsave(filename = paste0(output, "/", trait, "_overlap_map.png"), plot = map_fire_gradient, dpi = 200)
# }

# traits <- c("height", "sla", "seed")

# traits %>%
#   purrr::map(~ plot_spp_range_by_trait(.x))

# # for (i in seq_along(traits)) {
# #   plot_spp_range_by_trait(trait = traits[i])
# # }
