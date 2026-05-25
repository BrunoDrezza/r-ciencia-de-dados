if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse, bigrquery, dbplyr, lubridate, vroom, scales,
  rugarch, vars, depmixS4, tseries, patchwork, viridis
)

project_id <- Sys.getenv("GCP_PROJECT_ID")

if (project_id == "") stop("Erro: GCP_PROJECT_ID não encontrado.")

# Autenticação direta sem menus
bq_auth(email = "brunodrs16@gmail.com")