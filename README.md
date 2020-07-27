
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

# install and load multiple packages
ipak(c("vegan", "dplyr"))

# create world map quickly
quick_map()
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

``` r

# create other maps quickly
quick_map(region = "South America", type = "sf")
```

<img src="man/figures/README-unnamed-chunk-3-2.png" width="100%" />

``` r
quick_map(region = "Caribbean", type = "sf")
```

<img src="man/figures/README-unnamed-chunk-3-3.png" width="100%" />

``` r

# edit maps
if (!require("ggplot2")) install.packages("ggplot2")
quick_map(region = "Africa", type = "sf") +
  theme_void()
```

<img src="man/figures/README-unnamed-chunk-3-4.png" width="100%" />
