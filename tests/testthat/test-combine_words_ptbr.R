test_that("combine_words_ptbr works", {
  x <- c("A", "B", "C", "D")
  expect_equal(combine_words_ptbr(x), c("A, B, C e D"))
})

test_that("combine_words_ptbr works changing sep argument", {
  x <- c("A", "B", "C", "D")
  expect_equal(combine_words_ptbr(x, sep = "; "), c("A; B; C e D"))
})

test_that("combine_words_ptbr works changing last argument", {
  x <- c("A", "B", "C", "D")
  expect_equal(combine_words_ptbr(x, last = " and "), c("A, B, C and D"))
})
