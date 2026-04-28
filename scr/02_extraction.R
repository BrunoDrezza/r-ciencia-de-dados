source("scr/01_set_up.R")

query_tx <- "
  SELECT `hash`, value, gas_price, receipt_gas_used, block_timestamp, block_number
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE DATE(block_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  LIMIT 50000
"
df_tx <- bq_project_query(project_id, query_tx) %>% bq_table_download()

query_blocks <- "
  SELECT number, size, transaction_count, difficulty, timestamp
  FROM `bigquery-public-data.crypto_ethereum.blocks`
  WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
"
df_blocks <- bq_project_query(project_id, query_blocks) %>% bq_table_download()

saveRDS(df_tx, "data/raw/df_tx_amostra.rds")
saveRDS(df_blocks, "data/raw/df_blocks_amostra.rds")