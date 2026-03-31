# Requires (install yourself if needed): readxl, tidyverse metapackage or its
# pieces, openxlsx, here, fs, janitor, glue — and this script uses tidyverse
# verbs (dplyr, etc.) after loading.
needed <- c(
  "readxl",
  "ggplot2",
  "tibble",
  "tidyr",
  "readr",
  "purrr",
  "dplyr",
  "stringr",
  "forcats",
  "openxlsx",
  "here",
  "fs",
  "janitor",
  "glue"
)
missing <- needed[!vapply(needed, requireNamespace, NA, quietly = TRUE)]
if (length(missing)) {
  stop(
    "Missing package(s): ", paste(missing, collapse = ", "),
    ". Install from CRAN (e.g. install.packages(...)) before sourcing this script.",
    call. = FALSE
  )
}

pkg_list <- c(
  "readxl",
  "tidyverse",
  "openxlsx",
  "here",
  "fs",
  "janitor",
  "glue"
)

## Load packages that are already installed (no install in this script).
misc::ipak(pkg_list)

#' # Criando dos dados de exemplos
#'
#' Usaremos o dataset `mtcars` como dados de exemplo para salvar em nossas planilhas. Esse dataset é automaticamente carregado com o `{tidyverse}`. A única modificação que faremos nele é passar os nomes das linhas para uma nova coluna.
#'
## ------------------------------------------------------------------------------------------------------------------------
df_mtcars <-
  mtcars %>%
  rownames_to_column("car")

head(df_mtcars)

#' # Salvando os dados de exemplo
#'
#' Primeiro, devemos criar dois diretórios para evitar a bagunça com os arquivos. Teremos um diretório para os arquivos em `.xlsx` e outro para os arquivos `.csv`.
#'
## ------------------------------------------------------------------------------------------------------------------------
dir_xlsx <- dir_create("inst/xlsx-examples")

#' O próximo passo é escrever o `mtcars` 10 vezes dentro de cada arquivo `.xlsx`. Os laços `for` abaixo vão fazer esse trabalho.
#'
## ------------------------------------------------------------------------------------------------------------------------
n_workbook <- 10

n_sheet <- 10

format_index <- function(index) {
  formated_index <- formatC(x = index, digits = 2, flag = "0", format = "d")
  return(formated_index)
}

for (i in 1:n_workbook) {
  i_formatted <- format_index(i)

  workbook_name_i <- glue("mtcars_workbook_", i_formatted)

  message("\n", glue("Criando workbook {workbook_name_i}"), "\n")

  workbook_i <- createWorkbook(workbook_name_i)

  for (j in 1:n_sheet) {
    j_formatted <- format_index(j)

    sheet_name_j <- glue("mtcars_sheet_", j_formatted)

    addWorksheet(wb = workbook_i, sheetName = sheet_name_j)

    message(glue("Escrevendo dados na sheet {sheet_name_j} do workbook {workbook_name_i}"))

    writeData(wb = workbook_i, sheet = sheet_name_j, x = df_mtcars)
  }

  workbook_name_to_save <- glue(dir_xlsx, "/", workbook_name_i, ".xlsx")

  message("\n", glue("Salvando {workbook_name_i} em {workbook_name_to_save}"), "\n")

  saveWorkbook(wb = workbook_i, file = workbook_name_to_save)
}

#' Conferindo os arquivos:
#'
## ------------------------------------------------------------------------------------------------------------------------
dir_ls(path = dir_xlsx, regexp = "\\.xlsx$")
