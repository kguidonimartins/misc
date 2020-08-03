#' Combine words using ptbr rules (differ from knitr::combine_words() which uses oxford commas)
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
#' @examples
#' \dontrun{
#' misc::ipak(c("dplyr", "broom", "glue"))
#'
#' # showing significant variables
#' mtcars %>%
#'   select(mpg, cyl, carb, wt) %>%
#'   lm(mpg ~ cyl + carb + wt, data = .) %>%
#'   tidy() %>%
#'   filter(p.value <= 0.05, term != "(Intercept)") %>%
#'   pull(term) %>% {
#'     paste("Variáveis significativas:", combine_words_ptbr(.))
#'   }
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
