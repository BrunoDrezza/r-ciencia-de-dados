source("scr/01_set_up.R")

# Modelagem do log-retorno de gas_mean.
# Justificativa: retornos tendem a ser estacionários, atendendo a
# premissa do EGARCH; a série em nível costuma ter raiz unitária.
# A cauda direita (alta de gas) é o evento adverso para o usuário
# da rede, então VaR e CVaR são calculados sobre p = 0.95.

df_bars <- readRDS("data/processed/df_bars_15m.rds") |>
  dplyr::filter(!is.na(log_return))

teste_adf <- adf.test(df_bars$log_return)
cat("--- Teste ADF sobre log_return ---\n")
print(teste_adf)

spec_egarch <- ugarchspec(
  variance.model = list(model = "eGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std"
)

spec_sgarch <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std"
)

fit_egarch <- tryCatch(
  ugarchfit(spec_egarch, data = df_bars$log_return, solver = "hybrid"),
  error = \(e) {
    warning("EGARCH não convergiu, aplicando fallback sGARCH(1,1): ",
            conditionMessage(e))
    ugarchfit(spec_sgarch, data = df_bars$log_return, solver = "hybrid")
  }
)

stopifnot(convergence(fit_egarch) == 0)

saveRDS(fit_egarch, "data/processed/fit_egarch.rds")

sigma_t <- as.numeric(sigma(fit_egarch))
mu_t <- as.numeric(fitted(fit_egarch))
shape_nu <- as.numeric(coef(fit_egarch)["shape"])

z_95 <- qdist("std", 0.95, shape = shape_nu)

set.seed(20260523)
z_sim <- rdist("std", 50000, shape = shape_nu)
es_std <- mean(z_sim[z_sim >= quantile(z_sim, 0.95)])

df_risk_bands <- df_bars |>
  mutate(
    sigma_cond = sigma_t,
    var_95_ret = mu_t + sigma_t * z_95,
    cvar_95_ret = mu_t + sigma_t * es_std,
    gas_lag = lag(gas_mean),
    var_95_level = gas_lag * exp(var_95_ret),
    cvar_95_level = gas_lag * exp(cvar_95_ret)
  ) |>
  dplyr::select(bar_time, gas_mean, sigma_cond,
                var_95_ret, cvar_95_ret,
                var_95_level, cvar_95_level) |>
  dplyr::filter(!is.na(var_95_level))

saveRDS(df_risk_bands, "data/processed/df_risk_bands.rds")

cat("\n--- Diagnóstico EGARCH ---\n")
cat("Convergência:", convergence(fit_egarch), "(0 = OK)\n")
cat("Log-likelihood:", round(likelihood(fit_egarch), 2), "\n\n")
print(round(coef(fit_egarch), 4))
cat("\nQuantil padronizado 95%:", round(z_95, 3), "\n")
cat("ES padronizado 95%:", round(es_std, 3), "\n")
