# main.R - Pipeline de Execução do Projeto Ethereum

cat("A iniciar o pipeline econométrico...\n")

# 1. Extração de Dados
# NOTA: Como a extração demora e consome quota do BigQuery, 
# deixe esta linha comentada a menos que queira dados novos.
# source("scr/02_extraction.R")

# 2. Processamento e Limpeza
cat("\n1/4: A processar dados e gerar barras de 15 minutos...\n")
source("scr/03_analysis.R")
source("scr/05_features.R")

# 3. Modelagem Econométrica
cat("\n2/4: A treinar modelo EGARCH (Risco de Cauda)...\n")
source("scr/06_egarch.R")

cat("\n3/4: A estimar modelo VAR e Funções de Resposta ao Impulso...\n")
source("scr/07_var_irf.R")

cat("\n4/4: A classificar regimes de mercado com HMM...\n")
source("scr/08_hmm.R")

# 4. Compilação do Relatório
cat("\nModelos concluídos! A gerar o relatório final em PDF...\n")
rmarkdown::render("reports/primeiro_report.Rmd")

cat("\n--- Pipeline finalizado com sucesso! ---\n")