if (!require("remotes")) install.packages("remotes")
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("prefixer")) remotes::install_github("dreamRs/prefixer")
if (!require("xpectr")) install.packages("xpectr")


# udpate description file
c("sf", "rnaturalearth", "ggplot2", "dplyr", "stringr", "magrittr", "xpectr", "conflicted") %>%
  stringr::str_remove(., "tidyverse") %>%
  .[. != ""] %>%
  purrr::map(~ usethis::use_package(package = .x, type = "Imports"))

# last function
func <- "prefer"

usethis::use_r(func)

usethis::use_test(func)

rstudioapi::navigateToFile("R/prefer.R")

prefixer::prefixer()

prefixer::import_from(prefer)
