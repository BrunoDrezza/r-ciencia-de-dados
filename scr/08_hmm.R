source("scr/01_set_up.R")

# Reprodutibilidade: o algoritmo EM do depmixS4 é sensível a sementes.
set.seed(20260523)

df_bars <- readRDS("data/processed/df_bars_15m.rds") |>
  drop_na(gas_mean)

mod_hmm <- depmix(
  log_gas ~ 1,
  family = gaussian(),
  nstates = 2,
  data = df_bars
)

fit_hmm <- fit(mod_hmm, verbose = FALSE)
saveRDS(fit_hmm, "data/processed/fit_hmm.rds")

post <- posterior(fit_hmm, type = "viterbi")

# O estado com maior média de gas_mean é rotulado como "estresse".
mapa_estados <- df_bars |>
  mutate(estado_id = post$state) |>
  summarise(media_gas = mean(gas_mean), .by = estado_id) |>
  arrange(media_gas) |>
  mutate(rotulo = c("normal", "estresse"))

df_bars_with_regime <- df_bars |>
  mutate(estado_id = post$state) |>
  left_join(mapa_estados |> dplyr::select(estado_id, rotulo), by = "estado_id") |>
  mutate(regime = factor(rotulo, levels = c("normal", "estresse"))) |>
  dplyr::select(-estado_id, -rotulo)

saveRDS(df_bars_with_regime, "data/processed/df_bars_15m_with_regime.rds")

cat("--- Diagnóstico HMM ---\n")
cat("Log-likelihood:", round(as.numeric(logLik(fit_hmm)), 2), "\n")
cat("AIC:", round(AIC(fit_hmm), 2), "\n\n")
cat("Proporção de barras por regime:\n")
print(round(prop.table(table(df_bars_with_regime$regime)), 3))

cat("\nEstatísticas condicionais de gas_mean por regime:\n")
print(
  df_bars_with_regime |>
    summarise(
      n = n(),
      media = mean(gas_mean),
      mediana = median(gas_mean),
      desvio = sd(gas_mean),
      .by = regime
    )
)
