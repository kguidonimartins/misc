
<!-- README.md is generated from README.Rmd. Please edit that file -->

# misc

<!-- badges: start -->

[![Build
Status](https://travis-ci.com/kguidonimartins/misc.svg?branch=main)](https://travis-ci.com/kguidonimartins/misc)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R build
status](https://github.com/kguidonimartins/misc/workflows/R-CMD-check/badge.svg)](https://github.com/kguidonimartins/misc/actions)
[![Codecov test
coverage](https://codecov.io/gh/kguidonimartins/misc/branch/master/graph/badge.svg)](https://codecov.io/gh/kguidonimartins/misc?branch=master)
[![CodeFactor](https://www.codefactor.io/repository/github/kguidonimartins/misc/badge/main)](https://www.codefactor.io/repository/github/kguidonimartins/misc/overview/main)
<!-- badges: end -->

`{misc}` stands for *miscellaneous*. This is a personal package. Use it
at your own risk.

## Installation

You can install the released version of misc from
[github](https://github.com/kguidonimartins/misc) with:

``` r
if (!require("remotes")) install.packages("remotes")
if (!require("misc")) remotes::install_github("kguidonimartins/misc")
```

### Available functions

Check all available functions inside an interactive session using
`help(package = misc)` or in the site package
[here](https://kguidonimartins.github.io/misc/reference/index.html).

|  ID | Function                          | Description                                                  |
|----:|:----------------------------------|:-------------------------------------------------------------|
|   1 | `add_gitignore()`                 | Add a gitignore file to the project root                     |
|   2 | `combine_words_ptbr()`            | Combine words using ptbr rules                               |
|   3 | `create_dirs()`                   | Create directories                                           |
|   4 | `describe_data()`                 | Describe data                                                |
|   5 | `ipak()`                          | Install and load multiple CRAN and github R packages         |
|   6 | `na_count()`                      | Count NA frequency in data                                   |
|   7 | `na_viz()`                        | Visualize NA frequency in data                               |
|   9 | `prefer()`                        | Defines preferred package::functions                         |
|  10 | `quick_map()`                     | Create maps quickly                                          |
|  11 | `read_all_sheets_then_save_csv()` | Read and save all excel sheets and save them to a CSV file   |
|  12 | `read_all_xlsx_then_save_csv()`   | Read all sheets from all excel files and save into CSV files |
|  13 | `read_sheet_then_save_csv()`      | Read an excel sheet and save it to a CSV file                |
|  14 | `save_plot()`                     | Save a ggplot figure                                         |
|  15 | `save_temp_data()`                | Save object as RDS file                                      |
|  16 | `setup_lintr()`                   | Setup a config file for static code analysis                 |
|  17 | `trim_fig()`                      | Remove white spaces around figures                           |

### What commit is this file at?

``` r
misc::ipak("git2r")
if (in_repository(path = ".")) {
  repository(".")
}
#> Local:    main /home/karlo/GoogleDrive2/git-repos/misc
#> Remote:   main @ origin (https://github.com/kguidonimartins/misc.git)
#> Head:     [467fcac] 2020-12-23: update todo and in-dev
```
