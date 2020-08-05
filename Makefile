.DEFAULT_GOAL := help

R := Rscript -e

PKGNAME := $(shell sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION)
PKGVERS := $(shell sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION)

.PHONY: help tests clean

all: install tests check clean README.md ## run install_deps, build, install, tests, check, clean, and README.md

build: ## build package
	$(R) "devtools::build()"

check: ## check package
	$(R) "devtools::check()"

styler: ## styler package
	$(R) "styler::style_dir('R')"

tests: ## run test
	$(R) "devtools::test()"

install_deps: ## install dependencies
	$(R) 'if (!requireNamespace("remotes")) install.packages("remotes")' \
	-e 'if (!requireNamespace("dotenv")) install.packages("dotenv")' \
	-e 'if (file.exists(".env")) dotenv::load_dot_env()' \
	-e 'remotes::install_deps(dependencies = TRUE)'

install: install_deps build ## install package
	cd ..; \
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

clean: ## clean *.tar.gz *.Rcheck
	cd ..; \
	$(RM) -rv $(PKGNAME)_$(PKGVERS).tar.gz $(PKGNAME).Rcheck

README.md: README.Rmd ## render README
	$(R) "rmarkdown::render('$<')"

render: ## force render README
	$(R) "rmarkdown::render('README.Rmd')"

help:         ## show this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
