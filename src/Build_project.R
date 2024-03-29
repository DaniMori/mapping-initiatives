# ==============================================================================
# 
# FILE NAME:   Guild_project.R
# DESCRIPTION: This script builds the complete project from scratch (only the
#              Excel files in the `dat/` subfolder are necessary)
# 
# AUTHOR:      Daniel Morillo (daniel.morillo@cibersam.es)
# 
# DATE:        24/02/2022
# 
# ==============================================================================


## ---- GLOBAL OPTIONS: --------------------------------------------------------

gc()
rm(list = ls())

# First re-install locally all the project environment:
#  Must use R v4.1.3!!
renv::restore(prompt = FALSE)

## ---- INCLUDES: --------------------------------------------------------------

library(rmarkdown)
library(readxl)
library(tidyverse)
library(knitr)
library(xfun)

source("R/Constants.R", encoding = 'UTF-8')


## ---- CONSTANTS: -------------------------------------------------------------

WRITE_TABLES <- TRUE # This can be changed to `FALSE` if one doesn't want
                     #   to write again the tables from the source Excel files.
TEMP_FILE    <- "tmp.R"


## ---- FUNCTIONS: -------------------------------------------------------------


## ---- MAIN: ------------------------------------------------------------------

# Write notebooks: ----

# Notebook that generates the first version of the updated table:
Rscript_call(
  render,
  list(
    input  = "notebooks/Update_initiatives.Rmd",
    params = list(write_file = WRITE_TABLES)
  )
)

# Notebook that generates the complete version of the updated table:
Rscript_call(
  render,
  list(
    input  = "notebooks/Complete_initiatives_additional.Rmd",
    params = list(write_file = WRITE_TABLES)
  )
)


# File verification: ----

# Runs the notebook in the current session without writing the Excel file:
purl("notebooks/Complete_initiatives_additional.Rmd", output = TEMP_FILE)
source(TEMP_FILE, encoding = 'UTF-8')
unlink(TEMP_FILE)

read_table <- read_excel(INITIATIVES_FILEPATH, sheet = COMPLETE_TABLE_SHEET)

# This checks that the table written in the excel file and the result after
#   reading it are coincident:
coincidence_check <- initiatives_complete |> select(-id) |> imap_dfr(
  ~{
    comp <- initiatives_complete |> select(id, old = !!sym(.y))       |>
      full_join(read_table |> select(id, new = !!sym(.y)), by = "id") |>
      mutate(eq = (old == new) | (is.na(old) == is.na(new)))
    bind_cols(column = .y, comp |> count(eq))
  }
)

# Notebook that generates the version of the table for manual edition:
# This is a throughput output that requires manual processing, before
#   the manuscript is rendered, so please note there is a non-reproducible
#   step here:
Rscript_call(
  render,
  list(
    input  = "notebooks/Manual_editing_table.Rmd",
    params = list(write_file = WRITE_TABLES)
  )
)


# Render article and supplementary table files:

Rscript_call(
  render,
  list(
    input  = "output/manuscript/Main_text.Rmd",
    params = list(write_file = WRITE_TABLES)
  )
)

Rscript_call(
  render,
  list(
    input  = "output/manuscript/Supplementary_table.Rmd",
    params = list(write_file = WRITE_TABLES)
  )
)
