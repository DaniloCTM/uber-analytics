# Como Executar o ETL Raw -> Silver

## Ordem de Execução

Para evitar erros, execute as células do notebook `etl_raw_to_silver.ipynb` na seguinte ordem:

### 1. Importar Bibliotecas (Célula 1)
```python
import pandas as pd
import os
import warnings
```

### 2. Carregar Dados Raw (Célula 2)
- Carrega o arquivo CSV da camada Raw
- Verifica múltiplos caminhos possíveis

### 3. Renomear Colunas (Célula 3)
- Padroniza nomes para snake_case

### 4. Remover Colunas Redundantes (Célula 4)
- Remove flags desnecessárias

### 5. Limpar Texto (Célula 5)
- Remove aspas dos IDs

### 6. Remover Duplicados (Célula 6)
- Elimina Booking_IDs duplicados

### 7. Converter Datas e Horas (Célula 7)
- Padroniza formatos temporais

### 8. Remover Outliers (Célula 8)
- Aplica método IQR
- **IMPORTANTE**: Esta célula redefine `df_silver`

### 9. Tratar Valores Nulos (Célula 9)
- Preenche com médias/modas

### 10. Visualizar Amostra (Célula 10)
- Mostra 10 primeiras linhas

### 11. Exportar e Carregar no PostgreSQL (Célula 11)
- Salva CSV
- Insere no banco de dados

## Erro Comum: NameError

Se você receber `NameError: name 'df_silver' is not defined`:

**Causa**: Você executou a última célula sem executar as anteriores

**Solução**: Execute TODAS as células em ordem, de cima para baixo

### Executar Todas as Células

No Jupyter/VS Code:
- Menu: `Run` > `Run All Cells`
- Atalho: `Ctrl+Shift+Enter` (repetidas vezes)

## Pré-requisitos

1. Arquivo `.env` configurado
2. PostgreSQL rodando
3. Arquivo CSV em `Data Layer/raw/ncr_ride_bookings.csv`

## Verificação Rápida

Após executar todo o notebook, você deve ver:

```
Total de registros carregados: 150,000
Quantidade de dados duplicados: X
Outliers removidos com base no método IQR:
  • Avg_VTAT: X linhas removidas
  • Avg_CTAT: X linhas removidas
  • Booking_Value: X linhas removidas
  • Ride_Distance: X linhas removidas

Linhas finais após limpeza: ~140,000 (de 150,000)

Dados transformados salvos em 'Data Layer/silver/uber_silver.csv'.

Iniciando carregamento na camada SILVER (Postgres)...
Executando DDL...
Limpando tabela anterior...
Carga concluída: ~140,000 linhas inseridas em silver.uber_silver.

Processo ETL Raw -> Silver concluído!
```

## Próximos Passos

Após executar com sucesso:
1. Abra `Data Layer/silver/Analytics.ipynb`
2. Execute para ver análises comparativas Raw vs Silver
