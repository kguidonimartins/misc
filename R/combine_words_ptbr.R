#' Combine words using ptbr rules
#'
#' @description
#' `combine_words_ptbr()` collapse words using ptbr rules. This function
#' differ from [`knitr::combine_words()`](https://github.com/yihui/knitr/blob/2e08d5a9cb0a3b83cd73fd30d507a18676b0c4a4/R/utils.R#L830)
#' which uses oxford commas.
#'
#' @param words a character vector with words to combine
#' @param sep a character with the separator of the words. Default is NULL and insert ", "
#' @param last a character vector with the last separator of the words. Default is NULL and insert " e "
#'
#' @importFrom glue identity_transformer glue_collapse glue
#'
#' @return a character vector
#'
#' @export
#'
#' @section Acknowledgment:
#' `combine_words_ptbr()` uses [transformers](https://CRAN.R-project.org/package=glue)
#' available in the excellent [`{glue}`](https://github.com/tidyverse/glue) package
#'
#' @examples
#' \donttest{
#' misc::ipak("glue")
#'
#' # using in an ordinary text
#' feira <- c("banana", "maça", "pepino", "ovos")
#' glue("Por favor, compre: {combine_words_ptbr(feira)}")
#' }
combine_words_ptbr <- function(words, sep = NULL, last = NULL) {
  collapse_transformer <- function(regex = "[*]$", ...) {
    function(text, envir) {
      collapse <- grepl(regex, text)
      if (collapse) {
        text <- sub(regex, "", text)
      }
      res <- glue::identity_transformer(text, envir)
      if (collapse) {
        glue::glue_collapse(res, ...)
      } else {
        res
      }
    }
  }
  if (is.null(sep)) {
    sep <- ", "
  }
  if (is.null(last)) {
    last <- " e "
  }
  glue::glue("{words*}", .transformer = collapse_transformer(sep = sep, last = last))
}
