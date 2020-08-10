
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

Check all available functions inside an interactive session with:
`help(package = misc)`

| ID | Function                          | Description                                                  |
| -: | :-------------------------------- | :----------------------------------------------------------- |
|  1 | `add_gitignore()`                 | Add a gitignore file to the project root                     |
|  2 | `combine_words_ptbr()`            | Combine words using ptbr rules                               |
|  3 | `create_dirs()`                   | Create directories                                           |
|  4 | `describe_data()`                 | Describe data                                                |
|  5 | `ipak()`                          | Install and load multiple CRAN and github R packages         |
|  6 | `na_count()`                      | Count NA frequency in data                                   |
|  7 | `na_viz()`                        | Visualize NA frequency in data                               |
|  9 | `prefer()`                        | Defines preferred package::functions                         |
| 10 | `quick_map()`                     | Create maps quickly                                          |
| 11 | `read_all_sheets_then_save_csv()` | Read and save all excel sheets and save them to a CSV file   |
| 12 | `read_all_xlsx_then_save_csv()`   | Read all sheets from all excel files and save into CSV files |
| 13 | `read_sheet_then_save_csv()`      | Read an excel sheet and save it to a CSV file                |
| 14 | `save_plot()`                     | Save a ggplot figure                                         |
| 15 | `save_temp_data()`                | Save object as RDS file                                      |
| 16 | `trim_fig()`                      | Remove white spaces around figures                           |

### Usage

``` r
# install and load multiple packages (cran and github) at once
library(misc)
ipak(c("vegan", "tidyverse", "git2r", "trinker/textclean", "jalvesaq/colorout"))
#> [33mℹ[39m Successful loaded:
#>  - [32mvegan[39m     ([34m2.5.6[39m) 
#>  - [32mgit2r[39m     ([34m0.27.1[39m) 
#>  - [32mtextclean[39m ([34m0.9.5[39m) 
#>  - [32mcolorout[39m  ([34m1.2.2[39m) 
#>  - [32mggplot2[39m   ([34m3.3.2[39m) 
#>  - [32mtibble[39m    ([34m3.0.3[39m) 
#>  - [32mtidyr[39m     ([34m1.1.1[39m) 
#>  - [32mreadr[39m     ([34m1.3.1[39m) 
#>  - [32mpurrr[39m     ([34m0.3.4[39m) 
#>  - [32mdplyr[39m     ([34m1.0.1[39m) 
#>  - [32mstringr[39m   ([34m1.4.0[39m) 
#>  - [32mforcats[39m   ([34m0.5.0[39m)
```

### What commit is this file at?

``` r
if (in_repository(path = ".")) {
  repository(".")
}
#> Local:    main /Users/runner/work/misc/misc
#> Remote:   main @ origin (https://github.com/kguidonimartins/misc)
#> Head:     [f9fcef6] 2020-08-10: add missing pkgs to gh ci
```
