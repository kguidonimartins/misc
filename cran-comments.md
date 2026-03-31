Thanks,

Please always write package names, software names and API (application
programming interface) names in single quotes in title and description.
e.g: --> 'Excel', 'lintr'
Please note that package names are case sensitive.
For more details:
<https://contributor.r-project.org/cran-cookbook/description_issues.html#formatting-software-names>

Please add \value to .Rd files regarding exported methods and explain
the functions results in the documentation. Please write about the
structure of the output (class) and also what the output means. (If a
function does not return a value, please document that too, e.g.
\value{No return value, called for side effects} or similar)
For more details:
<https://contributor.r-project.org/cran-cookbook/docs_issues.html#missing-value-tags-in-.rd-files>
Missing Rd-tags:
     add_gitignore.Rd: \value
     create_dirs.Rd: \value
     ipak.Rd: \value
     pipe.Rd: \arguments,  \value
     prefer.Rd: \value
     read_all_sheets_then_save_csv.Rd: \value
     read_all_xlsx_then_save_csv.Rd: \value
     read_sheet_then_save_csv.Rd: \value
     save_plot.Rd: \value
     save_temp_data.Rd: \value
     trim_fig.Rd: \value

\dontrun{} should only be used if the example really cannot be executed
(e.g. because of missing additional software, missing API keys, ...) by
the user. That's why wrapping examples in \dontrun{} adds the comment
("# Not run:") as a warning for the user. Does not seem necessary.
Please replace \dontrun with \donttest.
Please unwrap the examples if they are executable in < 5 sec, or replace
dontrun{} with \donttest{}.
For more details:
<https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples>


You write information messages to the console that cannot be easily
suppressed.
It is more R like to generate objects that can be used to extract the
information a user is interested in, and then print() that object.
Instead of print()/cat() rather use message()/warning() or
if(verbose)cat(..) (or maybe stop()) if you really have to write text to
the console. (except for print, summary, interactive functions)
For more details:
<https://contributor.r-project.org/cran-cookbook/code_issues.html#using-printcat>
-> R/ipak.R;  R/setup_lintr.R; R/add_gitignore.R

You are using installed.packages() in your code. As mentioned in the
notes of installed.packages() help page, this can be very slow.
Therefore do not use installed.packages().

You are using installed.packages():
"This needs to read several files per installed package, which will be
slow on Windows and on some network-mounted file systems. It will be
slow when thousands of packages are installed, so do not use it to find
out if a named package is installed (use find.package or system.file)
nor to find out if a package is usable (call requireNamespace or require
and check the return value) nor to find details of a small number of
packages (use packageDescription)." [installed.packages() help page]
For more details:
<https://contributor.r-project.org/cran-cookbook/code_issues.html#calling-installed.packages>
-> inst/xlsx-examples.R; R/ipak.R

Please do not install packages in your functions, examples or vignette.
This can make the functions,examples and cran-check very slow.
For more details:
<https://contributor.r-project.org/cran-cookbook/code_issues.html#installing-software>

Please fix and resubmit.

Best,
Benjamin Altmann
