source("scr/01_set_up.R")

query_tx <- "
  SELECT `hash`, value, gas_price, receipt_gas_used, block_timestamp, block_number
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE DATE(block_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
  LIMIT 250000
"
df_tx <- bq_project_query(project_id, query_tx) |> bq_table_download()

query_blocks <- "
  SELECT number, size, transaction_count, difficulty, timestamp
  FROM `bigquery-public-data.crypto_ethereum.blocks`
  WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
"
df_blocks <- bq_project_query(project_id, query_blocks) |> bq_table_download()

# Barras de 15 min agregadas server-side em janela de 30 dias.
# Justificativa: baixar 30d tick-by-tick estouraria a RAM (~30M linhas),
# enquanto a agregação no BigQuery devolve ~2880 linhas e dá robustez
# estatística ao EGARCH/VAR/HMM. SAFE_CAST é defensivo contra o schema
# legado de gas_price/value (podem vir como STRING).
query_bars_30d <- "
  SELECT
    TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(block_timestamp), 900) * 900) AS bar_time,
    AVG(SAFE_CAST(gas_price AS FLOAT64) / 1e9)    AS gas_mean,
    MAX(SAFE_CAST(gas_price AS FLOAT64) / 1e9)    AS gas_max,
    MIN(SAFE_CAST(gas_price AS FLOAT64) / 1e9)    AS gas_min,
    STDDEV(SAFE_CAST(gas_price AS FLOAT64) / 1e9) AS gas_sd,
    COUNT(*)                                       AS tx_count,
    SUM(SAFE_CAST(value AS FLOAT64) / 1e18)       AS eth_volume
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE DATE(block_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND SAFE_CAST(value AS FLOAT64) > 0
  GROUP BY bar_time
  ORDER BY bar_time
"
df_bars_raw_30d <- bq_project_query(project_id, query_bars_30d) |>
  bq_table_download()

saveRDS(df_tx, "data/raw/df_tx_amostra.rds")
saveRDS(df_blocks, "data/raw/df_blocks_amostra.rds")
saveRDS(df_bars_raw_30d, "data/raw/df_bars_raw_30d.rds")

cat("--- Extração concluída ---\n")
cat("Tick-by-tick (14d):", nrow(df_tx), "transações\n")
cat("Blocos (14d):", nrow(df_blocks), "blocos\n")
cat("Barras 15 min agregadas (30d):", nrow(df_bars_raw_30d), "barras\n")
cat("Janela das barras:\n")
print(range(df_bars_raw_30d$bar_time))