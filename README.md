
<!-- README.md is generated from README.Rmd. Please edit that file -->

# misc

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/misc)](https://CRAN.R-project.org/package=misc)
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

| ID | Function | Description | Family |
|---:|:---|:---|:---|
| 1 | `tad_view()` | Alternative data.frame viewer using tad | `data-viewers` |
| 2 | `view_excel()` | View data frame in Excel or other spreadsheet viewer | `data-viewers` |
| 3 | `view_in()` | Alternative data.frame viewer | `data-viewers` |
| 4 | `view_vd()` | View data in VisiData | `data-viewers` |
| 5 | `view_vd_nonint()` | View data frame in VisiData (non-interactive version) | `data-viewers` |
| 6 | `deduplicate_by()` | Remove duplicate rows based on specified grouping variables | `data-wrangling` |
| 7 | `describe_data()` | Describe data | `data-wrangling` |
| 8 | `read_all_sheets_then_save_csv()` | Read and save all excel sheets and save them to a CSV file | `excel-import` |
| 9 | `read_all_xlsx_then_save_csv()` | Read all sheets from all excel files and save into CSV files | `excel-import` |
| 10 | `read_sheet_then_save_csv()` | Read an excel sheet and save it to a CSV file | `excel-import` |
| 11 | `clean_geo()` | Clean a spatial file and write a normalized copy | `geo-io` |
| 12 | `read_gdb()` | Read layers from a file geodatabase (.gdb) | `geo-io` |
| 13 | `read_geo()` | Read a geospatial file or dataset (auto-detect by extension) | `geo-io` |
| 14 | `read_kmz()` | Read a KMZ file (KML in a ZIP) | `geo-io` |
| 15 | `read_sf_zip()` | Read shapefile(s) inside a ZIP archive via GDAL | `geo-io` |
| 16 | `intersect_mask_filter_area()` | Clip features to a mask and drop border slivers by area ratio | `geo-tools` |
| 17 | `quick_map()` | Create maps quickly | `geo-tools` |
| 18 | `view_mapview_from_path()` | View spatial data from file path with optional map preview | `geo-tools` |
| 19 | `filter_na()` | Easily filter NA values from data frames | `missing-data` |
| 20 | `na_count()` | Count NA frequency in data | `missing-data` |
| 21 | `na_viz()` | Visualize NA frequency in data | `missing-data` |
| 22 | `remove_columns_based_on_NA()` | Remove columns based on NA values | `missing-data` |
| 23 | `ipak()` | Load multiple CRAN and GitHub R packages | `package-management` |
| 24 | `prefer()` | Defines preferred package::functions | `package-management` |
| 25 | `add_gitignore()` | Add a gitignore file to the project root | `project-setup` |
| 26 | `create_dirs()` | Create directories | `project-setup` |
| 27 | `save_plot()` | Save a ggplot figure | `save-output` |
| 28 | `save_temp_data()` | Save object as RDS file | `save-output` |
| 29 | `trim_fig()` | Remove white spaces around figures | `save-output` |
| 30 | `combine_words_ptbr()` | Combine words using ptbr rules | — |
