# Projeto DATATRAN 2025 – Arquitetura Medallion

Este projeto utiliza a arquitetura Medallion (RAW → SILVER → GOLD) aplicada a dados de sinistros de trânsito no Brasil (2025).

## Estrutura

- **Data Layer/raw**
  - CSV original (dados brutos)
  - Analytics exploratório sem tratamento

- **Data Layer/Transformer**
  - ETL responsável por transformar RAW em SILVER

- **Data Layer/silver**
  - Camada lógica (dados persistidos no PostgreSQL)

## Como rodar

```bash
docker-compose up --build
```

Acesse:
http://localhost:8888

Use o notebook `etl_raw_to_silver.ipynb` para carregar os dados no PostgreSQL.


## Notebooks

- `Data Layer/raw/raw_analytics.ipynb` – análise exploratória RAW (sem tratamento)
- `Data Layer/Transformer/etl_raw_to_silver.ipynb` – ETL RAW → SILVER e carga no PostgreSQL

## Carga no PostgreSQL

1. Suba o ambiente:

```bash
docker-compose up --build
```

2. Abra o Jupyter em `http://localhost:8888`.
3. Rode o notebook `Data Layer/Transformer/etl_raw_to_silver.ipynb`.
4. A tabela `silver_sinistros` será criada no banco `transito_2025`.
