if (!require("remotes")) install.packages("remotes")
if (!require("renv")) install.packages("renv")
if (!require("tidyverse")) install.packages("tidyverse")

pkg_deps <-
  renv::dependencies() %>%
  dplyr::filter(stringr::str_detect(Source, "DESCRIPTION")) %>%
  dplyr::pull(Package)

get_reqs <- function(pkg) {

  pkg_dep <-
    tryCatch(
      expr = {
        remotes::system_requirements(
          os = "ubuntu",
          os_release = "20.04",
          package = pkg
        )
      },
      error = function(err) {
        message("ERROR: ", err$message)
        NA
      })

  if (length(pkg_dep) == 0) {

    message("INFO: ", pkg, " does not have OS dependencies.")
    NA

  } else {

    pkg_dep %>%
      stringr::str_remove_all("apt-get install -y ")

  }

}

pkg_deps %>%
  purrr::map_chr(~ get_reqs(.x)) %>%
  .[!is.na(.)]
