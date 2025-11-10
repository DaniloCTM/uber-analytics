-- Gold DDL: Data Warehouse schema (star schema)
-- Schema: dwh

CREATE SCHEMA IF NOT EXISTS dwh;

-- ===============================================
-- DIMENSÕES
-- ===============================================

-- Dimensão: Dim_Data (Date Dimension)
CREATE TABLE IF NOT EXISTS dwh.dim_data (
    data_key INTEGER PRIMARY KEY, -- YYYYMMDD
    data_completa DATE,
    ano INTEGER,
    trimestre INTEGER,
    mes INTEGER,
    nome_mes VARCHAR(20),
    dia INTEGER,
    dia_da_semana INTEGER, -- 1=Segunda, 7=Domingo
    nome_dia_semana VARCHAR(20),
    fim_de_semana BOOLEAN,
    dia_util BOOLEAN
);

-- Dimensão: Dim_Tempo (Time Dimension - para hora do dia)
CREATE TABLE IF NOT EXISTS dwh.dim_tempo (
    tempo_key INTEGER PRIMARY KEY, -- HHMM (ex: 1430 para 14:30)
    hora INTEGER,
    minuto INTEGER,
    periodo VARCHAR(20), -- 'Madrugada', 'Manhã', 'Tarde', 'Noite'
    turno VARCHAR(20), -- 'Comercial', 'Noturno', etc
    hora_pico BOOLEAN -- TRUE se for horário de pico
);

-- Dimensão: Dim_Cliente
CREATE TABLE IF NOT EXISTS dwh.dim_cliente (
    cliente_key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    customer_id VARCHAR(100) UNIQUE,
    data_cadastro DATE -- Pode ser expandido com mais atributos SCD Type 2
);

-- Dimensão: Dim_Veiculo
CREATE TABLE IF NOT EXISTS dwh.dim_veiculo (
    veiculo_key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    vehicle_type VARCHAR(100) UNIQUE,
    categoria VARCHAR(50), -- 'Econômico', 'Premium', etc (pode ser derivado)
    capacidade INTEGER -- Capacidade de passageiros (pode ser adicionado)
);

-- Dimensão: Dim_Status
CREATE TABLE IF NOT EXISTS dwh.dim_status (
    status_key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    booking_status VARCHAR(100) UNIQUE,
    status_categoria VARCHAR(50), -- 'Completado', 'Cancelado', 'Incompleto'
    status_ativo BOOLEAN -- TRUE se for um status ativo/em andamento
);

-- Dimensão: Dim_Localizacao (Role-playing: pickup e drop)
CREATE TABLE IF NOT EXISTS dwh.dim_localizacao (
    local_key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    local_nome VARCHAR(255) UNIQUE,
    regiao VARCHAR(100), -- Pode ser derivado posteriormente
    zona VARCHAR(50) -- 'Norte', 'Sul', 'Centro', etc (pode ser adicionado)
);

-- Dimensão: Dim_Pagamento
CREATE TABLE IF NOT EXISTS dwh.dim_pagamento (
    pagamento_key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    payment_method VARCHAR(100) UNIQUE,
    tipo_pagamento VARCHAR(50) -- 'Digital', 'Dinheiro', etc (pode ser derivado)
);

-- Dimensão: Dim_Motivo_Cancelamento (Junk Dimension para motivos)
CREATE TABLE IF NOT EXISTS dwh.dim_motivo_cancelamento (
    motivo_key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    reason_cancel_customer VARCHAR(255),
    driver_cancellation_reason VARCHAR(255),
    incomplete_rides_reason VARCHAR(255),
    -- Hash para identificar combinações únicas
    motivo_hash VARCHAR(64) UNIQUE
);

-- ===============================================
-- TABELA FATO
-- ===============================================

-- Tabela Fato: Fato_Corridas
CREATE TABLE IF NOT EXISTS dwh.fato_corridas (
    corrida_key VARCHAR(100) PRIMARY KEY, -- booking_id do Silver
    
    -- Foreign Keys para Dimensões
    data_key INTEGER REFERENCES dwh.dim_data(data_key),
    tempo_key INTEGER REFERENCES dwh.dim_tempo(tempo_key),
    cliente_key BIGINT REFERENCES dwh.dim_cliente(cliente_key),
    veiculo_key BIGINT REFERENCES dwh.dim_veiculo(veiculo_key),
    status_key BIGINT REFERENCES dwh.dim_status(status_key),
    pagamento_key BIGINT REFERENCES dwh.dim_pagamento(pagamento_key),
    pickup_local_key BIGINT REFERENCES dwh.dim_localizacao(local_key),
    drop_local_key BIGINT REFERENCES dwh.dim_localizacao(local_key),
    motivo_key BIGINT REFERENCES dwh.dim_motivo_cancelamento(motivo_key),
    
    -- Métricas (Measures)
    booking_value NUMERIC(12,2),
    ride_distance DOUBLE PRECISION,
    avg_vtat DOUBLE PRECISION, -- Vehicle Turnaround Time
    avg_ctat DOUBLE PRECISION, -- Customer Turnaround Time
    driver_ratings DOUBLE PRECISION,
    customer_rating DOUBLE PRECISION,
    
    -- Métricas Derivadas (podem ser calculadas em queries, mas úteis pré-calculadas)
    valor_por_km NUMERIC(12,2), -- booking_value / ride_distance
    
    -- Flags para facilitar análises
    corrida_completa BOOLEAN, -- TRUE se status = 'Completed'
    corrida_cancelada BOOLEAN, -- TRUE se status contém 'Cancel'
    corrida_incompleta BOOLEAN, -- TRUE se status = 'Incomplete'
    
    -- Auditoria
    data_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===============================================
-- ÍNDICES PARA PERFORMANCE
-- ===============================================

-- Índices nas Foreign Keys da Fato
CREATE INDEX IF NOT EXISTS idx_fato_corridas_data_key ON dwh.fato_corridas(data_key);
CREATE INDEX IF NOT EXISTS idx_fato_corridas_tempo_key ON dwh.fato_corridas(tempo_key);
CREATE INDEX IF NOT EXISTS idx_fato_corridas_cliente_key ON dwh.fato_corridas(cliente_key);
CREATE INDEX IF NOT EXISTS idx_fato_corridas_veiculo_key ON dwh.fato_corridas(veiculo_key);
CREATE INDEX IF NOT EXISTS idx_fato_corridas_status_key ON dwh.fato_corridas(status_key);
CREATE INDEX IF NOT EXISTS idx_fato_corridas_pickup_local ON dwh.fato_corridas(pickup_local_key);
CREATE INDEX IF NOT EXISTS idx_fato_corridas_drop_local ON dwh.fato_corridas(drop_local_key);

-- Índices compostos para queries comuns
CREATE INDEX IF NOT EXISTS idx_fato_data_status ON dwh.fato_corridas(data_key, status_key);
CREATE INDEX IF NOT EXISTS idx_fato_data_veiculo ON dwh.fato_corridas(data_key, veiculo_key);
CREATE INDEX IF NOT EXISTS idx_fato_pickup_drop ON dwh.fato_corridas(pickup_local_key, drop_local_key);

-- Índices nas colunas de flag para filtros rápidos
CREATE INDEX IF NOT EXISTS idx_fato_corrida_completa ON dwh.fato_corridas(corrida_completa) WHERE corrida_completa = TRUE;
CREATE INDEX IF NOT EXISTS idx_fato_corrida_cancelada ON dwh.fato_corridas(corrida_cancelada) WHERE corrida_cancelada = TRUE;

-- ===============================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ===============================================

COMMENT ON SCHEMA dwh IS 'Data Warehouse - Camada Gold com modelagem Star Schema';

COMMENT ON TABLE dwh.dim_data IS 'Dimensão de Data com granularidade diária';
COMMENT ON TABLE dwh.dim_tempo IS 'Dimensão de Tempo com granularidade de minuto';
COMMENT ON TABLE dwh.dim_cliente IS 'Dimensão de Cliente (SCD Type 1)';
COMMENT ON TABLE dwh.dim_veiculo IS 'Dimensão de Tipo de Veículo';
COMMENT ON TABLE dwh.dim_status IS 'Dimensão de Status da Corrida';
COMMENT ON TABLE dwh.dim_localizacao IS 'Dimensão de Localização (Role-playing para pickup e drop)';
COMMENT ON TABLE dwh.dim_pagamento IS 'Dimensão de Método de Pagamento';
COMMENT ON TABLE dwh.dim_motivo_cancelamento IS 'Junk Dimension para combinações de motivos de cancelamento';
COMMENT ON TABLE dwh.fato_corridas IS 'Tabela Fato de Corridas com granularidade de 1 corrida';

COMMENT ON COLUMN dwh.fato_corridas.valor_por_km IS 'Métrica derivada: booking_value / ride_distance';
COMMENT ON COLUMN dwh.fato_corridas.avg_vtat IS 'Average Vehicle Turnaround Time';
COMMENT ON COLUMN dwh.fato_corridas.avg_ctat IS 'Average Customer Turnaround Time';
