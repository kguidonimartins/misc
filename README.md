
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
| 14 | `save_plot()`                     | Save a ggplot figure                                                                          |
| 15 | `save_temp_data()`                | Save objects as a RDS file                                                                    |
| 16 | `trim_fig()`                      | Remove white spaces around figures                                                            |

### What commit is this file at?

``` r
if ("git2r" %in% installed.packages() & git2r::in_repository(path = ".")) git2r::repository(here::here())
#> Local:    main /home/karlo/GoogleDrive2/git-repos/misc
#> Remote:   main @ origin (https://github.com/kguidonimartins/misc.git)
#> Head:     [454b741] 2020-08-04: update tests
```
