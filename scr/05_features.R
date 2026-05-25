source("scr/01_set_up.R")

# As barras de 15 min vêm pré-agregadas do BigQuery (ver 02_extraction.R).
# Aqui aplicamos apenas o filtro de qualidade e calculamos o log-retorno
# que alimenta EGARCH e VAR.

df_bars_raw <- readRDS("data/raw/df_bars_raw_30d.rds") |>
  arrange(bar_time)

df_bars_15m <- df_bars_raw |>
  dplyr::filter(tx_count >= 3) |>
  mutate(
    log_gas = log(gas_mean),
    log_return = log_gas - lag(log_gas)
  )

saveRDS(df_bars_15m, "data/processed/df_bars_15m.rds")

cat("--- Auditoria de barras de 15 minutos ---\n")
cat("Barras brutas (do BigQuery):", nrow(df_bars_raw), "\n")
cat("Barras pós-filtro (tx_count >= 3):", nrow(df_bars_15m), "\n")
cat("Descartadas:", nrow(df_bars_raw) - nrow(df_bars_15m), "\n")
cat("Janela temporal:\n")
print(range(df_bars_15m$bar_time))
cat("\n")
print(summary(df_bars_15m))
