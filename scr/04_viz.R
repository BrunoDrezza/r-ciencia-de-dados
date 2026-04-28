source("scr/01_set_up.R")

df_tx_clean <- readRDS("data/processed/df_tx_clean.rds")
df_blocks <- readRDS("data/raw/df_blocks_amostra.rds")

grafico_gas <- ggplot(df_tx_clean, aes(x = gas_gwei)) +
  geom_histogram(fill = "#2c3e50", color = "white", bins = 50) +
  scale_x_log10() +
  labs(
    title = "Distribuição Logarítmica do Preço do Gas (Gwei)",
    subtitle = "Análise de cauda e volatilidade de taxas da rede",
    x = "Gas Price (Gwei) - Log Scale",
    y = "Frequência"
  ) +
  theme_minimal()

grafico_blocos <- ggplot(df_blocks, aes(x = as_datetime(timestamp), y = transaction_count)) +
  geom_line(color = "#e74c3c", alpha = 0.6) +
  geom_smooth(method = "gam", color = "black") +
  labs(
    title = "Densidade de Transações por Bloco (Últimos 7 dias)",
    subtitle = "Proxy de utilização e congestionamento de rede",
    x = "Tempo",
    y = "Número de Transações"
  ) +
  theme_minimal()

print(grafico_gas)
print(grafico_blocos)