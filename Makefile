.DEFAULT_GOAL := help

R := Rscript -e

PKGNAME := $(shell sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION)
PKGVERS := $(shell sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION)

.PHONY: help tests clean check-cran spell url-check cran-build submit-cran cran-release extdata

all: install tests check clean ## run install_deps, build, install, tests, check, and clean

document: ## refresh function documentation
	$(R) "devtools::document()"

extdata: ## regenerate inst/extdata spatial samples (sf, zip; GDB via bash data-raw/build_misc_example_gdb.sh)
	Rscript data-raw/build_read_geo_extdata.R
	bash data-raw/build_misc_example_gdb.sh

build: document ## build package
	$(R) "devtools::build()"

gp: ## get goodpractice' suggestions
	$(R) "goodpractice::gp()" 2>&1 | tee out-gp.txt

check: build ## check package
	$(R) "Sys.setenv('_R_CHECK_SYSTEM_CLOCK_' = 0); devtools::check(document = FALSE, build_args = c('--no-build-vignettes'))" 2>&1 | tee out-check.txt

check-cran: build ## check como o CRAN (devtools::check); grave em out-check-cran.txt
	$(R) "Sys.setenv('_R_CHECK_SYSTEM_CLOCK_' = 0); devtools::check(document = FALSE, cran = TRUE, args = c('--no-manual'))" 2>&1 | tee out-check-cran.txt

spell: ## ortografia em DESCRIPTION, README, Rd (pacote spelling)
	$(R) "if (!requireNamespace('spelling', quietly = TRUE)) stop('Install spelling: install.packages(\"spelling\")'); spelling::spell_check_package()"

url-check: ## links em Rd e README (pacote urlchecker)
	$(R) "if (!requireNamespace('urlchecker', quietly = TRUE)) stop('Install urlchecker: install.packages(\"urlchecker\")'); urlchecker::url_check()"

cran-build: document ## tarball limpo na pasta pai (para upload manual ao CRAN)
	cd .. && R CMD build --compact-vignettes=no $(PKGNAME)

submit-cran: ## envia ao CRAN (confirme no prompt R + e-mail do maintainer)
	$(R) "devtools::submit_cran('.')"

cran-release: ## fluxo interativo completo recomendado (checks + confirmações antes do upload)
	$(R) "if (!requireNamespace('devtools', quietly = TRUE)) stop('Install devtools'); devtools::release()"

styler: ## styler package
	$(R) "styler::style_dir('R')"

tests: ## run test
	$(R) "Sys.setenv('TESTTHAT_MAX_FAILS' = Inf); devtools::test()" 2>&1 | tee out-testthat.txt

install_deps: ## install dependencies
	$(R) 'if (!requireNamespace("remotes")) install.packages("remotes")' \
	-e 'if (!requireNamespace("dotenv")) install.packages("dotenv")' \
	-e 'if (file.exists(".env")) dotenv::load_dot_env()' \
	-e 'remotes::install_deps(dependencies = TRUE, upgrade = "never")'

install_remote: ## install package from remote version
	$(R) 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", repos = "https://cloud.r-project.org"); remotes::install_github("kguidonimartins/misc")'

install: install_deps build ## install package
	cd ..; \
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

quick_install: build ## quick install (document, build, install) tar package version (used in development)
	cd ..; \
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

clean: ## clean *.tar.gz *.Rcheck
	cd ..; \
	$(RM) -rv $(PKGNAME)_$(PKGVERS).tar.gz $(PKGNAME).Rcheck

README.md: README.Rmd ## render README
	$(R) "rmarkdown::render('$<')"

eg:     ## run examples
	$(R) "devtools::run_examples(run_dontrun = TRUE, run_donttest = TRUE)" 2>&1 | tee out-eg.txt

render: ## force render README
	$(R) "rmarkdown::render('README.Rmd')"

help:         ## show this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
