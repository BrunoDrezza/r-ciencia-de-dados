source("scr/01_set_up.R")

df_tx <- readRDS("data/raw/df_tx_amostra.rds")
df_blocks <- readRDS("data/raw/df_blocks_amostra.rds")

df_tx_clean <- df_tx %>%
  mutate(
    eth_value = as.numeric(value) / 1e18,
    gas_gwei = as.numeric(gas_price) / 1e9,
    timestamp = as_datetime(block_timestamp)
  ) %>%
  filter(eth_value > 0)

saveRDS(df_tx_clean, "data/processed/df_tx_clean.rds")

summary_stats <- df_tx_clean %>%
  summarise(
    avg_gas = mean(gas_gwei, na.rm = TRUE),
    median_gas = median(gas_gwei, na.rm = TRUE),
    sd_gas = sd(gas_gwei, na.rm = TRUE),
    max_gas = max(gas_gwei, na.rm = TRUE),
    total_volume_eth = sum(eth_value, na.rm = TRUE)
  )

print(summary_stats)