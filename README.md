
<!-- README.md is generated from README.Rmd. Please edit that file -->

# misc

<!-- badges: start -->

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

Check all available functions inside an interactive session using
`help(package = misc)` or in the site package
[here](https://kguidonimartins.github.io/misc/reference/index.html).

| ID | Function | Description |
|---:|:---|:---|
| 1 | `add_gitignore()` | Add a gitignore file to the project root |
| 2 | `combine_words_ptbr()` | Combine words using ptbr rules |
| 3 | `create_dirs()` | Create directories |
| 4 | `deduplicate_by()` | Remove duplicate rows based on specified grouping variables |
| 5 | `describe_data()` | Describe data |
| 6 | `filter_na()` | Easily filter NA values from data frames |
| 7 | `ipak()` | Load multiple CRAN and GitHub R packages |
| 8 | `na_count()` | Count NA frequency in data |
| 9 | `na_viz()` | Visualize NA frequency in data |
| 11 | `prefer()` | Defines preferred package::functions |
| 12 | `quick_map()` | Create maps quickly |
| 13 | `read_all_sheets_then_save_csv()` | Read and save all excel sheets and save them to a CSV file |
| 14 | `read_all_xlsx_then_save_csv()` | Read all sheets from all excel files and save into CSV files |
| 15 | `read_gdb()` | Read layers from a file geodatabase (.gdb) |
| 16 | `read_geo()` | Read a geospatial file or dataset (auto-detect by extension) |
| 17 | `read_kmz()` | Read a KMZ file (KML in a ZIP) |
| 18 | `read_sf_zip()` | Read shapefile(s) inside a ZIP archive via GDAL |
| 19 | `read_sheet_then_save_csv()` | Read an excel sheet and save it to a CSV file |
| 20 | `remove_columns_based_on_NA()` | Remove columns based on NA values |
| 21 | `save_plot()` | Save a ggplot figure |
| 22 | `save_temp_data()` | Save object as RDS file |
| 23 | `tad_view()` | Alternative data.frame viewer using tad |
| 24 | `trim_fig()` | Remove white spaces around figures |
| 25 | `view_excel()` | View data frame in Excel or other spreadsheet viewer |
| 26 | `view_in()` | Alternative data.frame viewer |
| 27 | `view_mapview_from_path()` | View spatial data from file path with optional map preview |
| 28 | `view_vd()` | View data in VisiData |
| 29 | `view_vd_nonint()` | View data frame in VisiData (non-interactive version) |
