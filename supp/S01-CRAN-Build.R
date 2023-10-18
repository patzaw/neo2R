library(here)

## Build and copy vignettes ----
## First instantiate one of the image described in README.Rmd
rmarkdown::render(here("README.Rmd"))

## Build and check package ----
pv <- desc::desc_get_version(here())
system(paste(
   sprintf("cd %s", here("..")),
   "R CMD build neo2R",
   sprintf("R CMD check --as-cran neo2R_%s.tar.gz", pv),
   sep=" ; "
))
# install.packages(here(sprintf("../neo2R_%s.tar.gz", pv)), repos=NULL)
