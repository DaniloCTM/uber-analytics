# Uber Ride Analytics 2024 – Arquitetura de Medalhão

Este projeto implementa a Arquitetura de Medalhão (Medallion Architecture) aplicada ao dataset Uber Ride Analytics 2024, explorando práticas modernas de armazenamento, transformação e análise de dados em ambientes de data lake.

A arquitetura segue o fluxo Bronze → Silver → Gold, permitindo desde a ingestão de dados brutos até a modelagem analítica final.

# Dataset

## Descrição

O dataset contém informações detalhadas de operações da Uber em 2024, abrangendo padrões de reserva, desempenho da frota, métricas financeiras, cancelamentos e satisfação dos clientes.

## Estatísticas principais

Total de bookings: 148.77K corridas

Sucesso: 65.96% (93K completadas)

Cancelamentos: 25% (37.43K)

Por clientes: 19.15% (27K)

Por motoristas: 7.45% (10.5K)

# Arquitetura de Medalhão

## Bronze – Dados Brutos

Armazena os dados originais, sem tratamento (arquivos CSV).

## Silver – Dados Refinados

Padronização e limpeza dos dados armazenados no PostgreSQL.

**Localização**: Schema `silver` no banco de dados PostgreSQL
**Tabela**: `silver.uber_silver`

## Gold – Dados Prontos para Análise

Aplicação de regras de negócio e agregações.

# Configuração do Ambiente

## Requisitos

- Python 3.8+
- PostgreSQL 12+
- Docker (opcional)

## Configuração do Banco de Dados

1. Copie o arquivo `.env.example` para `.env`:
   ```
   cp .env.example .env
   ```

2. Configure as credenciais do PostgreSQL no arquivo `.env`:
   ```
   DB_USER=postgres
   DB_PASSWORD=sua_senha
   DB_HOST=localhost
   DB_PORT=5433
   DB_NAME=uber
   ```

3. Execute o ETL para popular a camada Silver:
   - Execute o notebook `Transformer/etl_raw_to_silver.ipynb`
   - Os dados tratados serão inseridos automaticamente no PostgreSQL

## Análise de Dados

### Camada Raw
- Arquivo: `Data Layer/raw/Analytics.ipynb`
- Dados: CSV bruto

### Camada Silver
- Arquivo: `Data Layer/silver/Analytics.ipynb`
- Dados: Carregados do PostgreSQL (schema `silver`)
- Comparação: Raw vs Silver com visualizações de outliers e qualidade

# Objetivos do Trabalho

Demonstrar na prática a aplicação da Arquitetura de Medalhão.

Implementar ingestão, limpeza e modelagem de dados em camadas.

Extrair insights do dataset da Uber (cancelamentos, receita, distâncias, satisfação).

# Equipe


Danilo César Tertuliano Melo - 22103119  
Marcos Vieira Marinho - 222021906  
Daniel Ferreira Santos Rabelo - 222006632  
Francisco Mizael Santos - 180113331  