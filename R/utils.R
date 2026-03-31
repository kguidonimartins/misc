globalVariables(c(".", "admin", "excluded_files", "linter"))

check_require <- function(pkg) {
  full_pkgname <- pkg
  pkgname <- basename(full_pkgname)

  if (!requireNamespace(pkgname, quietly = TRUE)) {
    usethis::ui_stop(
      "Package {usethis::ui_field(pkgname)} needed for this function to work!
       Solution: For CRAN, run install.packages(\"{pkgname}\", repos = \"https://cloud.r-project.org\"). For GitHub, run remotes::install_github(\"{full_pkgname}\"). Then try again."
    )
  }
}
