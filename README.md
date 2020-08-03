
<!-- README.md is generated from README.Rmd. Please edit that file -->

# misc

<!-- badges: start -->

[![Build
Status](https://travis-ci.com/kguidonimartins/misc.svg?branch=main)](https://travis-ci.com/kguidonimartins/misc)
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

| ID | Function                          | Description                                                                                   |
| -: | :-------------------------------- | :-------------------------------------------------------------------------------------------- |
|  1 | `add_gitignore()`                 | Add a gitignore to the project root                                                           |
|  2 | `combine_words_ptbr()`            | Combine words using ptbr rules (differ from knitr::combine\_words() which uses oxford commas) |
|  3 | `create_dirs()`                   | Create data, output and R directories                                                         |
|  4 | `describe_data()`                 | Describe data                                                                                 |
|  5 | `ipak()`                          | Install and load multiple R packages                                                          |
|  6 | `na_count()`                      | Count NA frequency in data                                                                    |
|  7 | `na_viz()`                        | Vizualize NA frequency in data                                                                |
|  9 | `prefer()`                        | Defines preferred functions from conflicts between namespaces                                 |
| 10 | `quick_map()`                     | Create maps quickly                                                                           |
| 11 | `read_all_sheets_then_save_csv()` | Read and save into csv files all the sheets in a excel file                                   |
| 12 | `read_all_xlsx_then_save_csv()`   | Read all sheets from all excel files and save into csv files                                  |
| 13 | `read_sheet_then_save_csv()`      | Read a excel sheet and save into a csv file                                                   |
| 14 | `save_temp_data()`                | Save objects as a RDS file                                                                    |

### Usage

``` r
library(misc)

# install and load multiple packages
ipak(c("vegan", "dplyr"))

# create world map quickly
quick_map()
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

``` r

# create other maps quickly
quick_map(region = "South America", type = "sf")
```

<img src="man/figures/README-unnamed-chunk-5-2.png" width="100%" />

``` r
quick_map(region = "Caribbean", type = "sf")
```

<img src="man/figures/README-unnamed-chunk-5-3.png" width="100%" />

``` r

# edit maps
if (!require("ggplot2")) install.packages("ggplot2")
quick_map(region = "Africa", type = "sf") +
  theme_void()
```

<img src="man/figures/README-unnamed-chunk-5-4.png" width="100%" />

### What commit is this file at?

``` r
if ("git2r" %in% installed.packages() & git2r::in_repository(path = ".")) git2r::repository(here::here())
#> Local:    main /home/karlo/GoogleDrive2/git-repos/misc
#> Remote:   main @ origin (https://github.com/kguidonimartins/misc.git)
#> Head:     [543bb91] 2020-08-03: add `combine_words_ptbr()`
```
