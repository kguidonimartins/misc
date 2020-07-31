
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

### Usage

``` r
library(misc)

# check available functions
getNamespaceExports("misc")
#> [1] "%>%"                           "read_all_sheets_then_save_csv"
#> [3] "ipak"                          "save_temp_data"               
#> [5] "prefer"                        "quick_map"                    
#> [7] "create_dirs"                   "read_sheet_then_save_csv"     
#> [9] "read_all_xlsx_then_save_csv"
```

#### Some examples

``` r
# install and load multiple packages
ipak(c("vegan", "dplyr"))

# create world map quickly
quick_map()
```

<img src="man/figures/README-unnamed-chunk-4-1.png" width="100%" />

``` r

# create other maps quickly
quick_map(region = "South America", type = "sf")
```

<img src="man/figures/README-unnamed-chunk-4-2.png" width="100%" />

``` r
quick_map(region = "Caribbean", type = "sf")
```

<img src="man/figures/README-unnamed-chunk-4-3.png" width="100%" />

``` r

# edit maps
if (!require("ggplot2")) install.packages("ggplot2")
quick_map(region = "Africa", type = "sf") +
  theme_void()
```

<img src="man/figures/README-unnamed-chunk-4-4.png" width="100%" />
