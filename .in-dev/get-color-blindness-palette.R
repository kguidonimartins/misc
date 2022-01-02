## https://stackoverflow.com/questions/65013406/how-to-generate-30-distinct-colors-that-are-color-blind-friendly

define_colors <- function(n_rasters) {

  set.seed(1970)
  cores <-
    sample(
      grDevices::hcl.colors(
        n = length(unique(n_rasters)),
        palette = "PuOr")
    )

  return(cores)

}
