if (!require("remotes")) install.packages("remotes")
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("prefixer")) remotes::install_github("dreamRs/prefixer")
if (!require("xpectr")) install.packages("xpectr")
if (!require("devtools")) install.packages("devtools")

devtools::load_all()

# udpate description file
c(
  "sf",
  "rnaturalearth",
  "ggplot2",
  "dplyr",
  "stringr",
  "magrittr",
  "xpectr",
  "conflicted",
  "usethis",
  "fs",
  "here",
  "janitor",
  "readxl",
  "tools"
) %>%
  stringr::str_remove(., "tidyverse") %>%
  .[. != ""] %>%
  purrr::map(~ usethis::use_package(package = .x, type = "Imports"))

# last function
func <- "na_viz"

usethis::use_r(func)

usethis::use_test(func)

rstudioapi::navigateToFile(paste0("R/", func, ".R"))

prefixer::prefixer()

prefixer::import_from(paste(func))
