-- ===============================================
-- Gold DDL: Data Warehouse schema (Star Schema)
-- Schema: dwh
-- ===============================================
-- Arquitetura Medallion - Camada GOLD
-- 4 Dimensões reduzidas + 1 Tabela Fato
-- Mnemônicos silábicos (3-4 caracteres)
-- Documentação completa: docs/Mnemonicos_DWH.md
-- ===============================================

CREATE SCHEMA IF NOT EXISTS dwh;

-- ===============================================
-- DIMENSÕES (4 DIMENSÕES CONSOLIDADAS)
-- ===============================================

-- Dimensão: dim_dtt (DateTime - Data/Hora)
CREATE TABLE IF NOT EXISTS dwh.dim_dtt (
    srk_dtt BIGSERIAL PRIMARY KEY,
    dtt_key BIGINT UNIQUE NOT NULL,
    dat DATE NOT NULL,
    hor TIME,
    yrr INT,
    qtr INT,
    mth INT,
    day INT,
    dow INT,
    wkd VARCHAR(3)
);

-- Dimensão: dim_cst (Customer - Cliente)
CREATE TABLE IF NOT EXISTS dwh.dim_cst (
    srk_cst BIGSERIAL PRIMARY KEY,
    cst_ide VARCHAR(100) UNIQUE NOT NULL,
    dat_cad DATE
);

-- Dimensão: dim_loc (Location - Localização)
CREATE TABLE IF NOT EXISTS dwh.dim_loc (
    srk_loc BIGSERIAL PRIMARY KEY,
    loc_nme VARCHAR(255) UNIQUE NOT NULL,
    rgn VARCHAR(100),
    zon VARCHAR(50)
);

-- Dimensão: dim_rid (Ride - Corrida/Atributos)
CREATE TABLE IF NOT EXISTS dwh.dim_rid (
    srk_rid BIGSERIAL PRIMARY KEY,
    vhc_tpe VARCHAR(100),
    bkg_sts VARCHAR(100),
    pmt_mtd VARCHAR(100),
    rsn_cst TEXT,
    rsn_drv TEXT,
    rsn_inc TEXT,
    avg_vtt DOUBLE PRECISION,
    avg_ctt DOUBLE PRECISION
);

-- ===============================================
-- TABELA FATO
-- ===============================================

-- Tabela Fato: fat_cor (Corridas)
CREATE TABLE IF NOT EXISTS dwh.fat_cor (
    srk_cor BIGSERIAL PRIMARY KEY,
    cor_key VARCHAR(100) UNIQUE NOT NULL,
    srk_dtt BIGINT REFERENCES dwh.dim_dtt(srk_dtt),
    srk_cst BIGINT REFERENCES dwh.dim_cst(srk_cst),
    srk_rid BIGINT REFERENCES dwh.dim_rid(srk_rid),
    srk_pck BIGINT REFERENCES dwh.dim_loc(srk_loc),
    srk_drp BIGINT REFERENCES dwh.dim_loc(srk_loc),
    amt NUMERIC(12,2),
    dst DOUBLE PRECISION,
    rtg_drv DOUBLE PRECISION,
    rtg_cst DOUBLE PRECISION,
    amt_km NUMERIC(12,2),
    flg_cmp VARCHAR(3),
    flg_cnc VARCHAR(3),
    flg_inc VARCHAR(3),
    dat_crg TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===============================================
-- COMENTÁRIOS DAS TABELAS
-- ===============================================

COMMENT ON SCHEMA dwh IS 'Data Warehouse - Camada Gold (Star Schema com 4 dimensões)';

COMMENT ON TABLE dwh.dim_dtt IS 'Dimensão temporal (data e hora combinados)';
COMMENT ON COLUMN dwh.dim_dtt.srk_dtt IS 'Surrogate key (PK auto-increment)';
COMMENT ON COLUMN dwh.dim_dtt.dtt_key IS 'Datetime key YYYYMMDDHHMM (ex: 202511121430)';
COMMENT ON COLUMN dwh.dim_dtt.dat IS 'Data completa (origem: silver.date)';
COMMENT ON COLUMN dwh.dim_dtt.hor IS 'Hora HH:MM:SS (origem: silver.time)';
COMMENT ON COLUMN dwh.dim_dtt.yrr IS 'Ano (Year)';
COMMENT ON COLUMN dwh.dim_dtt.qtr IS 'Trimestre 1-4 (Quarter). Q1=Jan-Mar, Q2=Abr-Jun, Q3=Jul-Set, Q4=Out-Dez';
COMMENT ON COLUMN dwh.dim_dtt.mth IS 'Mês 1-12 (Month)';
COMMENT ON COLUMN dwh.dim_dtt.day IS 'Dia do mês 1-31';
COMMENT ON COLUMN dwh.dim_dtt.dow IS 'Dia da semana 1-7 (1=Segunda, 7=Domingo)';
COMMENT ON COLUMN dwh.dim_dtt.wkd IS 'Weekend: Yes=final de semana, No=dia útil';

COMMENT ON TABLE dwh.dim_cst IS 'Dimensão de clientes (SCD Type 1)';
COMMENT ON COLUMN dwh.dim_cst.srk_cst IS 'Surrogate key (PK auto-increment)';
COMMENT ON COLUMN dwh.dim_cst.cst_ide IS 'Customer ID natural key (origem: silver.customer_id)';
COMMENT ON COLUMN dwh.dim_cst.dat_cad IS 'Data de cadastro (primeira corrida)';

COMMENT ON TABLE dwh.dim_loc IS 'Dimensão de localização (role-playing para pickup e drop)';
COMMENT ON COLUMN dwh.dim_loc.srk_loc IS 'Surrogate key (PK auto-increment)';
COMMENT ON COLUMN dwh.dim_loc.loc_nme IS 'Nome da localização (origem: pickup_location ou drop_location)';
COMMENT ON COLUMN dwh.dim_loc.rgn IS 'Região (a ser derivada via geocoding)';
COMMENT ON COLUMN dwh.dim_loc.zon IS 'Zona/bairro (a ser derivada)';

COMMENT ON TABLE dwh.dim_rid IS 'Dimensão consolidada de corrida (veículo, status, pagamento, motivos, tempos)';
COMMENT ON COLUMN dwh.dim_rid.srk_rid IS 'Surrogate key (PK auto-increment)';
COMMENT ON COLUMN dwh.dim_rid.vhc_tpe IS 'Vehicle type (origem: silver.vehicle_type)';
COMMENT ON COLUMN dwh.dim_rid.bkg_sts IS 'Booking status (origem: silver.booking_status)';
COMMENT ON COLUMN dwh.dim_rid.pmt_mtd IS 'Payment method (origem: silver.payment_method)';
COMMENT ON COLUMN dwh.dim_rid.rsn_cst IS 'Reason cancel by customer (NULL se não cancelado)';
COMMENT ON COLUMN dwh.dim_rid.rsn_drv IS 'Reason cancel by driver (NULL se não cancelado)';
COMMENT ON COLUMN dwh.dim_rid.rsn_inc IS 'Reason incomplete (NULL se completa)';
COMMENT ON COLUMN dwh.dim_rid.avg_vtt IS 'Avg Vehicle TAT - Vehicle Turnaround Allocation Time (min)';
COMMENT ON COLUMN dwh.dim_rid.avg_ctt IS 'Avg Customer TAT - Customer Turnaround Allocation Time (min)';

COMMENT ON TABLE dwh.fat_cor IS 'Tabela fato de corridas (granularidade: 1 booking)';
COMMENT ON COLUMN dwh.fat_cor.srk_cor IS 'Surrogate key (PK auto-increment)';
COMMENT ON COLUMN dwh.fat_cor.cor_key IS 'Corrida key = booking_id (natural key único)';
COMMENT ON COLUMN dwh.fat_cor.srk_dtt IS 'FK para dim_dtt (datetime)';
COMMENT ON COLUMN dwh.fat_cor.srk_cst IS 'FK para dim_cst (customer)';
COMMENT ON COLUMN dwh.fat_cor.srk_rid IS 'FK para dim_rid (ride attributes)';
COMMENT ON COLUMN dwh.fat_cor.srk_pck IS 'FK para dim_loc (pickup location)';
COMMENT ON COLUMN dwh.fat_cor.srk_drp IS 'FK para dim_loc (drop location)';
COMMENT ON COLUMN dwh.fat_cor.amt IS 'Amount - Valor da corrida em R$ (métrica aditiva)';
COMMENT ON COLUMN dwh.fat_cor.dst IS 'Distance - Distância em km (métrica semi-aditiva)';
COMMENT ON COLUMN dwh.fat_cor.rtg_drv IS 'Rating driver 0-5 (métrica não-aditiva - usar AVG)';
COMMENT ON COLUMN dwh.fat_cor.rtg_cst IS 'Rating customer 0-5 (métrica não-aditiva - usar AVG)';
COMMENT ON COLUMN dwh.fat_cor.amt_km IS 'Amount per km - Valor por km derivado (amt/dst)';
COMMENT ON COLUMN dwh.fat_cor.flg_cmp IS 'Flag complete: Yes=corrida completa, No=não';
COMMENT ON COLUMN dwh.fat_cor.flg_cnc IS 'Flag cancel: Yes=corrida cancelada, No=não';
COMMENT ON COLUMN dwh.fat_cor.flg_inc IS 'Flag incomplete: Yes=corrida incompleta, No=não';
COMMENT ON COLUMN dwh.fat_cor.dat_crg IS 'Data de carga no DWH (auditoria)';

-- ===============================================
-- ÍNDICES PARA PERFORMANCE
-- ===============================================

-- Índices nas Foreign Keys da Tabela Fato
CREATE INDEX IF NOT EXISTS idx_fat_cor_dtt ON dwh.fat_cor(srk_dtt);
CREATE INDEX IF NOT EXISTS idx_fat_cor_cst ON dwh.fat_cor(srk_cst);
CREATE INDEX IF NOT EXISTS idx_fat_cor_rid ON dwh.fat_cor(srk_rid);
CREATE INDEX IF NOT EXISTS idx_fat_cor_pck ON dwh.fat_cor(srk_pck);
CREATE INDEX IF NOT EXISTS idx_fat_cor_drp ON dwh.fat_cor(srk_drp);

-- Índices compostos para queries comuns
CREATE INDEX IF NOT EXISTS idx_fat_cor_dtt_cst ON dwh.fat_cor(srk_dtt, srk_cst);
CREATE INDEX IF NOT EXISTS idx_fat_cor_pck_drp ON dwh.fat_cor(srk_pck, srk_drp);

-- Índices nas flags para filtros rápidos (partial indexes)
CREATE INDEX IF NOT EXISTS idx_fat_cor_flg_cmp ON dwh.fat_cor(flg_cmp) WHERE flg_cmp = 'Yes';
CREATE INDEX IF NOT EXISTS idx_fat_cor_flg_cnc ON dwh.fat_cor(flg_cnc) WHERE flg_cnc = 'Yes';

-- Índice no natural key da fato
CREATE INDEX IF NOT EXISTS idx_fat_cor_key ON dwh.fat_cor(cor_key);

-- Índice no datetime_key da dimensão temporal
CREATE INDEX IF NOT EXISTS idx_dim_dtt_key ON dwh.dim_dtt(dtt_key);
