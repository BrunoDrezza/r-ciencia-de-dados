source("scr/01_set_up.R")

df_bars <- readRDS("data/processed/df_bars_15m.rds") |>
  dplyr::filter(!is.na(log_return))

# Estacionariedade conjunta antes do VAR.
# log_return de gas costuma ser estacionário (verificado em 06_egarch.R);
# tx_count pode ter tendência diária — testamos e diferenciamos se preciso.
adf_tx <- adf.test(df_bars$tx_count)
cat("--- ADF: tx_count ---\n")
print(adf_tx)

usar_diff <- adf_tx$p.value > 0.05

df_var_input <- df_bars |>
  mutate(tx_count_use = if (usar_diff) c(NA, diff(tx_count)) else tx_count) |>
  dplyr::filter(!is.na(tx_count_use), !is.na(log_return))

mat_var <- df_var_input |>
  dplyr::select(tx_count = tx_count_use, log_return) |>
  as.matrix()

selecao_lag <- VARselect(mat_var, lag.max = 10, type = "const")
cat("\n--- Seleção de lag (critérios) ---\n")
print(selecao_lag$selection)

lag_otimo <- as.integer(selecao_lag$selection["AIC(n)"])
cat("\nLag escolhido (AIC):", lag_otimo, "\n")

fit_var <- VAR(mat_var, p = lag_otimo, type = "const")
saveRDS(fit_var, "data/processed/fit_var.rds")

set.seed(20260523)
irf_obj <- irf(
  fit_var,
  n.ahead = 20,
  boot = TRUE,
  runs = 200,
  ci = 0.95,
  cumulative = FALSE
)

# Achata o objeto `varirf` em um data frame longo:
# (horizonte, impulso, resposta, estimativa, lower, upper).
componente_para_df <- function(componente, nome_valor) {
  imap(componente, \(mat, imp) {
    as_tibble(mat) |>
      mutate(horizonte = row_number() - 1L, impulso = imp) |>
      pivot_longer(
        cols = -c(horizonte, impulso),
        names_to = "resposta",
        values_to = nome_valor
      )
  }) |>
    list_rbind()
}

df_irf <- componente_para_df(irf_obj$irf, "estimativa") |>
  left_join(
    componente_para_df(irf_obj$Lower, "lower"),
    by = c("horizonte", "impulso", "resposta")
  ) |>
  left_join(
    componente_para_df(irf_obj$Upper, "upper"),
    by = c("horizonte", "impulso", "resposta")
  )

saveRDS(df_irf, "data/processed/df_irf.rds")

cat("\n--- Diagnóstico VAR ---\n")
cat("Diferenciação aplicada em tx_count:", usar_diff, "\n")
cat("Raízes do polinômio característico (devem ser < 1):\n")
print(round(roots(fit_var), 4))
cat("\nCausalidade de Granger (tx_count -> log_return):\n")
print(causality(fit_var, cause = "tx_count")$Granger)
