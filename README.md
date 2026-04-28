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
├── scripts/
│   ├── 01_setup.R             # Carregamento de dependências e autenticação GCP
│   ├── 02_extraction.R        # Queries SQL e download das amostras
│   ├── 03_analysis.R          # Transformações, conversão de unidades e estatísticas
│   └── 04_viz.R               # Geração de gráficos analíticos (ggplot2)
├── reports/
│   └── relatorio_previo.Rmd   # Documentação acadêmica e consolidação dos resultados
├── .gitignore                 # Exclusão de credenciais e bases de dados do controle de versão
└── README.md                  # Este documento
```

*Nota: Os diretórios `data/raw/` e `data/processed/` não são comitados no controle de versão para preservar a performance do repositório e obedecer às boas práticas de governança de dados.*

## Pré-requisitos e Dependências

A execução deste projeto requer a instalação do `R` e das seguintes bibliotecas:
* `tidyverse` (Manipulação de dados e visualização)
* `bigrquery` (Interface de conexão com o Google BigQuery)
* `lubridate` (Tratamento de séries temporais)
* `knitr` e `kableExtra` (Geração de relatórios e formatação de tabelas)
* `pacman` (Gerenciamento de pacotes)

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

Para reproduzir a pesquisa e gerar os relatórios, os scripts devem ser executados de forma estritamente sequencial. A definição do *Working Directory* deve estar na raiz do projeto (onde o arquivo `.Rproj` está localizado, se aplicável).

1. **`scripts/01_setup.R`**: Estabelece a conexão segura com a API do Google utilizando o email pré-autorizado.
2. **`scripts/02_extraction.R`**: Executa as queries SQL, delimitando a amostra temporal, e salva os arquivos `.rds` na pasta `data/raw/`.
3. **`scripts/03_analysis.R`**: Carrega os dados brutos, aplica os fatores de conversão matemática (Wei para Ether/Gwei) e salva a base final em `data/processed/`.
4. **`scripts/04_viz.R`**: Consome a base processada para plotar as distribuições de probabilidade e as séries temporais de risco.
5. **`reports/relatorio_previo.Rmd`**: Compila as métricas e os gráficos gerados nas etapas anteriores em um documento HTML/PDF formalizado.
