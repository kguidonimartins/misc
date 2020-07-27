# h/t to @jimhester and @yihui for this parse block:
# https://github.com/yihui/knitr/blob/dc5ead7bcfc0ebd2789fe99c527c7d91afb3de4a/Makefile#L1-L4
# Note the portability change as suggested in the manual:
# https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Writing-portable-packages
.DEFAULT_GOAL := help
PKGNAME = `sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION`
PKGVERS = `sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION`

.PHONY: help tests clean

all: build clean test_pkg check ## run test_pkg, check, and clean targets

build: ## build package
	R CMD build .

check: ## check package
	Rscript -e "devtools::check()"

test_pkg:     ## test functions and shiny app
	Rscript -e "devtools::test()"

install_deps: ## install dependencies
	Rscript \
	-e 'if (!requireNamespace("remotes")) install.packages("remotes")' \
	-e 'remotes::install_deps(dependencies = TRUE)'

install: install_deps build ## install package
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

clean: ## clean *.Rcheck
	@rm -rf $(PKGNAME)_$(PKGVERS).tar.gz $(PKGNAME).Rcheck

render: ## render README
	Rscript -e "rmarkdown::render('README.Rmd')"

help:         ## show this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
