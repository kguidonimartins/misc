
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
| 11 | `read_all_sheets_then_save_csv()` | Read and save into csv files all the sheets in a excel file  |
| 12 | `read_all_xlsx_then_save_csv()`   | Read all sheets from all excel files and save into csv files |
| 13 | `read_sheet_then_save_csv()`      | Read an excel sheet and save it to a CSV file                |
| 14 | `save_plot()`                     | Save a ggplot figure                                         |
| 15 | `save_temp_data()`                | Save objects as a RDS file                                   |
| 16 | `trim_fig()`                      | Remove white spaces around figures                           |

### Usage

``` r
# install and load multiple package (cran and github) at once
library(misc)
ipak(c("vegan", "ggplot2", "trinker/textclean", "jalvesaq/colorout"))
#> ℹ Successful loaded:
#>  - vegan (2.5.6) 
#>  - ggplot2 (3.3.2) 
#>  - textclean (0.9.5) 
#>  - colorout (1.2.2)
```

### What commit is this file at?

``` r
if (!require("git2r")) install.packages("git2r")
#> Loading required package: git2r
#> 
#> Attaching package: 'git2r'
#> The following object is masked from 'package:dplyr':
#> 
#>     pull
#> The following objects are masked from 'package:purrr':
#> 
#>     is_empty, when
if ("git2r" %in% installed.packages() & git2r::in_repository(path = ".")) {
  git2r::repository(here::here())
}
#> Local:    main /home/karlo/GoogleDrive2/git-repos/misc
#> Remote:   main @ origin (https://github.com/kguidonimartins/misc.git)
#> Head:     [10a8384] 2020-08-06: working on documentation
```
