# Análise de Microestrutura e Risco de Rede no Ethereum

## Descrição do Projeto
Este repositório contém a infraestrutura de código em linguagem R para extração, processamento e modelagem quantitativa de dados on-chain da rede Ethereum. O objetivo da pesquisa é analisar a dinâmica de risco sistêmico, a volatilidade das taxas de execução (*gas price*) e a resiliência da rede perante choques de congestionamento.

Os dados são extraídos diretamente do *dataset* público `crypto_ethereum` hospedado no Google Cloud BigQuery.

## Estrutura do Repositório

O projeto segue uma arquitetura modular para garantir reprodutibilidade e isolamento entre as etapas de extração de dados brutos, tratamento e visualização.

```text
/
├── data/
│   ├── raw/                   # Dados brutos extraídos do BigQuery via SQL (.rds)
│   └── processed/             # Dados higienizados e padronizados para modelagem (.rds)
├── scr/
│   ├── 01_set_up.R            # Carregamento de dependências e autenticação GCP
│   ├── 02_extraction.R        # Queries SQL: tick-by-tick 14d + barras agregadas 30d
│   ├── 03_analysis.R          # Transformações, conversão de unidades e estatísticas
│   ├── 04_viz.R               # Geração de gráficos exploratórios (ggplot2)
│   ├── 05_features.R          # Carrega barras pré-agregadas e calcula log_return
│   ├── 06_egarch.R            # EGARCH(1,1) com VaR e CVaR a 95%
│   ├── 07_var_irf.R           # VAR bivariado e funções de resposta ao impulso
│   └── 08_hmm.R               # Hidden Markov Model de regimes (normal/estresse)
├── reports/
│   └── primeiro_report.Rmd    # Documentação acadêmica e consolidação dos resultados
├── .gitignore                 # Exclusão de credenciais e bases de dados do controle de versão
└── README.md                  # Este documento
```

*Nota: Os diretórios `data/raw/` e `data/processed/` não são comitados no controle de versão para preservar a performance do repositório e obedecer às boas práticas de governança de dados.*

## Pré-requisitos e Dependências

A execução deste projeto requer a instalação do `R` (>= 4.1, para o pipe nativo `|>`) e das seguintes bibliotecas:
* `tidyverse` (Manipulação de dados e visualização)
* `bigrquery`, `dbplyr` (Interface de conexão com o Google BigQuery)
* `lubridate`, `vroom`, `scales` (Tratamento de séries temporais e formatação)
* `rugarch` (EGARCH e estimação de VaR/CVaR)
* `vars` (Vetores autorregressivos e funções de resposta ao impulso)
* `depmixS4` (Hidden Markov Models de mudança de regime)
* `tseries` (Testes de estacionariedade — ADF)
* `viridis`, `patchwork` (Paleta consistente e composição de gráficos)
* `knitr` (Geração de relatórios — `kableExtra` foi dropado para compatibilidade nativa de PDF)
* `pacman` (Gerenciamento de pacotes)

Todas as dependências são carregadas via `pacman::p_load()` em `scr/01_set_up.R` — instalando automaticamente o que estiver faltando.

## Configuração de Credenciais (.Renviron)

Por questões estritas de segurança, nenhuma credencial ou ID de projeto deve ser trafegada no código-fonte. A conexão com o Google Cloud é estabelecida localmente através de variáveis de ambiente.

Para configurar o seu ambiente local de execução, siga os passos abaixo:

1. Localize o **Project ID** da sua conta de faturamento no console do Google Cloud Platform (GCP).
2. No console do R, execute o comando abaixo para abrir o arquivo de ambiente do usuário:
   ```R
   usethis::edit_r_environ()
   ```
3. No arquivo `.Renviron` que será aberto, adicione a seguinte linha, substituindo o valor pelo seu Project ID real:
   ```text
   GCP_PROJECT_ID="seu-id-do-gcp-aqui"
   ```
4. Salve o arquivo e reinicie a sua sessão do R para que a variável de ambiente seja carregada na memória.
5. Verifique se o arquivo `.Renviron` consta no seu `.gitignore` para impedir vazamento de credenciais durante o *commit*.

## Ordem de Execução

Para reproduzir a pesquisa e gerar os relatórios, os scripts devem ser executados de forma estritamente sequencial. O *Working Directory* deve estar na raiz do projeto (onde o arquivo `.Rproj` está localizado). Cada script faz `source("scr/01_set_up.R")` no topo — não é necessário pré-carregar pacotes.

1. **`scr/01_set_up.R`**: Carrega dependências e estabelece a conexão segura com a API do Google utilizando o email pré-autorizado.
2. **`scr/02_extraction.R`**: Executa três queries SQL e salva os `.rds` em `data/raw/`:
   * tick-by-tick (`LIMIT 250000`, 14 dias) — para análise descritiva;
   * blocos (14 dias) — para densidade de transações;
   * **barras de 15 min agregadas server-side (30 dias)** — para modelagem econométrica robusta sem custo de RAM.
3. **`scr/03_analysis.R`**: Carrega o tick-by-tick bruto, aplica os fatores de conversão (Wei → Ether/Gwei) e salva a base limpa em `data/processed/df_tx_clean.rds`.
4. **`scr/04_viz.R`**: Plota o histograma logarítmico do gas e a série temporal de transações por bloco (análise exploratória).
5. **`scr/05_features.R`**: Lê as barras pré-agregadas de 30 dias, aplica filtro `tx_count >= 3` e calcula `log_return`; salva `data/processed/df_bars_15m.rds`.
6. **`scr/06_egarch.R`**: Ajusta um EGARCH(1,1) com inovação t de Student sobre o log-retorno do gas, calcula VaR e CVaR a 95% e persiste `fit_egarch.rds` e `df_risk_bands.rds`.
7. **`scr/07_var_irf.R`**: Estima um VAR bivariado (demanda × custo) com lag por AIC, extrai funções de resposta ao impulso via bootstrap e salva `fit_var.rds` e `df_irf.rds`.
8. **`scr/08_hmm.R`**: Ajusta um Hidden Markov Model gaussiano de 2 estados (normal/estresse), persiste `fit_hmm.rds` e `df_bars_15m_with_regime.rds`.
9. **`reports/primeiro_report.Rmd`**: Compila as métricas, modelos e gráficos em um documento PDF/HTML formalizado. Renderize com `rmarkdown::render("reports/primeiro_report.Rmd")` — os caminhos do Rmd são relativos a `reports/`.
