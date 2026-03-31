## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Resubmission

In response to the previous review, we made the following changes.

* `DESCRIPTION` (software names): In the title and description, package, API, and software names are now in single quotes, with correct spelling and case (for example `'Excel'`, `'sf'`, `'lintr'`), as required by the CRAN guide.

* `.Rd` documentation (`\value` and `\arguments`): We added `@returns` sections (rendered as `\value{...}`) for exported functions that were missing them, describing the class or structure of the output and what it means; for functions that exist only for side effects we document explicitly that there is no return value. For the `%>%` pipe operator we added `@param` and `@returns` in `R/utils-pipe.R`.

* Examples (`\dontrun` / `\donttest`): We replaced `\dontrun{}` with `\donttest{}` for examples that need not be fully excluded from checking, in line with CRAN policy. We keep `\donttest{}` where an example depends on the network, runtime, or an interactive session.

* Console output (`print` / `cat`): We reduced use of `print()` / `cat()` for incidental informational output: for example, `ipak()` uses `message()` to suggest install commands when a package is not installed and returns a summary `data.frame` invisibly, while `add_gitignore()` uses `message()` when showing the contents of an existing `.gitignore`. The file `R/setup_lintr.R` is no longer part of the submitted package source.

* `installed.packages()`: We removed calls to `installed.packages()`. In `R/ipak.R`, the installed check uses `nzchar(system.file(package = ...))`. In `inst/xlsx-examples.R`, required packages are verified with `requireNamespace(..., quietly = TRUE)` before `stop()` with instructions for manual installation.

* Installing packages in functions, examples, and vignettes: `ipak()` no longer runs `install.packages()` or `remotes::install_github()`; it only loads what is already installed and suggests commands via `message()` for the user to run outside the function. The script in `inst/xlsx-examples.R` only loads packages that are already present and stops with a clear message if a dependency is missing, without installing anything during execution.

* Local checks: `R CMD check` was run locally (including `--as-cran`) with no errors, warnings, or notes.
