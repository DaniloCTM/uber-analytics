# Mnemônicos do Data Warehouse (Camada Gold)

Este documento apresenta os mnemônicos (atributos abreviados, descrições, tipos e regras) das tabelas do Data Warehouse na camada Gold.

**Padrão de nomenclatura:** Abreviações silábicas (3-4 caracteres) + tipo de dado reduzido.

---

## 1. Dimensão: `dwh.dim_dtt` (DateTime)

Dimensão temporal que combina informações de data e hora para análises temporais.

| Mnemônico | Descrição | Tipo | Regras/Observações |
|-----------|-----------|------|-------------------|
| **srk_dtt** | Surrogate Key - Datetime | BIGSERIAL | PK. Auto-increment |
| **dtt_key** | Datetime Key (YYYYMMDDHHMM) | BIGINT | UNIQUE. Ex: 202511121430 = 12/11/2025 14:30 |
| **dat** | Data completa | DATE | NOT NULL. Extraído de `silver.date` |
| **hor** | Hora | TIME | Extraído de `silver.time` (HH:MM:SS) |
| **yrr** | Ano (Year) | INT | Calculado: `EXTRACT(YEAR FROM dat)` |
| **qtr** | Trimestre (Quarter 1-4) | INT | Calculado: `EXTRACT(QUARTER FROM dat)` |
| **mth** | Mês (Month 1-12) | INT | Calculado: `EXTRACT(MONTH FROM dat)` |
| **day** | Dia (1-31) | INT | Calculado: `EXTRACT(DAY FROM dat)` |
| **dow** | Day of Week (1-7) | INT | 1=Segunda, 7=Domingo. `EXTRACT(DOW) + 1` |
| **wkd** | Weekend (fim de semana) | VARCHAR(3) | 'Yes' se dow IN (6,7), senão 'No' |


### Como é preenchido `dim_dtt`?

**Método SQL (PostgreSQL):**
```sql
INSERT INTO dwh.dim_dtt (dtt_key, dat, hor, yrr, qtr, mth, day, dow, wkd)
SELECT DISTINCT
    (to_char(date, 'YYYYMMDD') || to_char(time::time, 'HH24MI'))::bigint AS dtt_key,
    date::date AS dat,
    time::time AS hor,
    EXTRACT(YEAR FROM date)::int AS yrr,
    EXTRACT(QUARTER FROM date)::int AS qtr,  -- ← Trimestre gerado automaticamente (1-4)
    EXTRACT(MONTH FROM date)::int AS mth,
    EXTRACT(DAY FROM date)::int AS day,
    (EXTRACT(DOW FROM date)::int + 1) AS dow,
    CASE WHEN EXTRACT(DOW FROM date) IN (0,6) THEN 'Yes' ELSE 'No' END AS wkd
FROM silver.uber_silver
WHERE date IS NOT NULL AND time IS NOT NULL
ON CONFLICT (dtt_key) DO NOTHING;
```

**Método Python:**
```python
import pandas as pd

df = pd.read_sql("SELECT DISTINCT date, time FROM silver.uber_silver", conn)
df['date'] = pd.to_datetime(df['date'])
df['time'] = pd.to_datetime(df['time'], format='%H:%M:%S', errors='coerce')

# Gerar dtt_key
df['dtt_key'] = df.apply(
    lambda row: int(f"{row['date'].strftime('%Y%m%d')}{row['time'].hour:02d}{row['time'].minute:02d}"),
    axis=1
)

# Extrair componentes
df['dat'] = df['date'].dt.date
df['hor'] = df['time'].dt.time
df['yrr'] = df['date'].dt.year
df['qtr'] = df['date'].dt.quarter  # ← pandas gera automaticamente 1-4
df['mth'] = df['date'].dt.month
df['day'] = df['date'].dt.day
df['dow'] = df['date'].dt.dayofweek + 1
df['wkd'] = df['dow'].apply(lambda x: 'Yes' if x >= 6 else 'No')
```

**Observação sobre trimestre (qtr):**
- PostgreSQL: `EXTRACT(QUARTER FROM date)` retorna 1, 2, 3 ou 4 automaticamente
- Python pandas: `dt.quarter` retorna o trimestre diretamente
- Q1 = Jan-Mar, Q2 = Abr-Jun, Q3 = Jul-Set, Q4 = Out-Dez

---

## 2. Dimensão: `dwh.dim_cst` (Customer)

Dimensão de clientes (lentamente mutável - SCD Type 1).

| Mnemônico | Descrição | Tipo | Regras/Observações |
|-----------|-----------|------|-------------------|
| **srk_cst** | Surrogate Key - Customer | BIGSERIAL | PK, AUTO INCREMENT |
| **cst_ide** | Customer ID (natural key) | VARCHAR(100) | UNIQUE, NOT NULL. Vem de `silver.customer_id` |
| **dat_cad** | Data de cadastro | DATE | `MIN(date)` por `customer_id` |

### Preenchimento:
```sql
INSERT INTO dwh.dim_cst (cst_ide, dat_cad)
SELECT DISTINCT 
    customer_id AS cst_ide,
    MIN(date) AS dat_cad
FROM silver.uber_silver
GROUP BY customer_id
ON CONFLICT (cst_ide) DO NOTHING;
```

---

## 3. Dimensão: `dwh.dim_loc` (Location)

Dimensão de localização (role-playing: usada para pickup e drop).

| Mnemônico | Descrição | Tipo | Regras/Observações |
|-----------|-----------|------|-------------------|
| **srk_loc** | Surrogate Key - Location | BIGSERIAL | PK, AUTO INCREMENT |
| **loc_nme** | Nome da localização | VARCHAR(255) | UNIQUE, NOT NULL. Vem de `pickup_location` ou `drop_location` |
| **rgn** | Região (North, South, etc) | VARCHAR(100) | Pode ser derivado posteriormente |
| **zon** | Zona/bairro | VARCHAR(50) | Pode ser derivado posteriormente |

### Preenchimento:
```sql
INSERT INTO dwh.dim_loc (loc_nme, rgn, zon)
SELECT DISTINCT loc_nme, NULL AS rgn, NULL AS zon
FROM (
    SELECT pickup_location AS loc_nme FROM silver.uber_silver
    UNION
    SELECT drop_location FROM silver.uber_silver
) locations
WHERE loc_nme IS NOT NULL
ON CONFLICT (loc_nme) DO NOTHING;
```

---

## 4. Dimensão: `dwh.dim_rid` (Ride)

Dimensão consolidada com atributos da corrida.

| Mnemônico | Descrição | Tipo | Regras/Observações |
|-----------|-----------|------|-------------------|
| **srk_rid** | Surrogate Key - Ride | BIGSERIAL | PK, AUTO INCREMENT |
| **vhc_tpe** | Vehicle Type | VARCHAR(100) | Ex: 'Prime Sedan', 'Auto', 'Bike' |
| **bkg_sts** | Booking Status | VARCHAR(100) | Ex: 'Completed', 'Cancelled' |
| **pmt_mtd** | Payment Method | VARCHAR(100) | Ex: 'Cash', 'Card', 'Wallet' |
| **rsn_cst** | Reason Cancel by Customer | TEXT | NULL se não cancelado pelo cliente |
| **rsn_drv** | Reason Cancel by Driver | TEXT | NULL se não cancelado pelo motorista |
| **rsn_inc** | Reason Incomplete | TEXT | NULL se corrida completa |
| **avg_vtt** | Avg Vehicle TAT (min) | DOUBLE PRECISION | Vehicle Turnaround Allocation Time |
| **avg_ctt** | Avg Customer TAT (min) | DOUBLE PRECISION | Customer Turnaround Allocation Time |

### Preenchimento:
```sql
INSERT INTO dwh.dim_rid (vhc_tpe, bkg_sts, pmt_mtd, rsn_cst, rsn_drv, rsn_inc, avg_vtt, avg_ctt)
SELECT DISTINCT
    vehicle_type AS vhc_tpe,
    booking_status AS bkg_sts,
    payment_method AS pmt_mtd,
    reason_for_cancelling_by_customer AS rsn_cst,
    driver_cancellation_reason AS rsn_drv,
    incomplete_rides_reason AS rsn_inc,
    avg_vtat AS avg_vtt,
    avg_ctat AS avg_ctt
FROM silver.uber_silver;
```

---

## 5. Tabela Fato: `dwh.fat_cor` (Corridas)

Tabela fato com granularidade de 1 corrida (1 linha = 1 booking).

| Mnemônico | Descrição | Tipo | Regras/Observações |
|-----------|-----------|------|-------------------|
| **srk_cor** | Surrogate Key - Corrida | BIGSERIAL | PK, AUTO INCREMENT |
| **cor_key** | Corrida Key (booking_id) | VARCHAR(100) | UNIQUE. Natural key de `silver.booking_id` |
| **srk_dtt** | FK para dim_dtt | BIGINT | FK REFERENCES `dim_dtt(srk_dtt)` |
| **srk_cst** | FK para dim_cst | BIGINT | FK REFERENCES `dim_cst(srk_cst)` |
| **srk_rid** | FK para dim_rid | BIGINT | FK REFERENCES `dim_rid(srk_rid)` |
| **srk_pck** | FK para dim_loc (pickup) | BIGINT | FK REFERENCES `dim_loc(srk_loc)` |
| **srk_drp** | FK para dim_loc (drop) | BIGINT | FK REFERENCES `dim_loc(srk_loc)` |
| **amt** | Valor da corrida (R$) | NUMERIC(12,2) | Métrica aditiva. Vem de `booking_value` |
| **dst** | Distância (km) | DOUBLE PRECISION | Métrica semi-aditiva. Vem de `ride_distance` |
| **rtg_drv** | Rating Driver (0-5) | DOUBLE PRECISION | Métrica não-aditiva. Vem de `driver_ratings` |
| **rtg_cst** | Rating Customer (0-5) | DOUBLE PRECISION | Métrica não-aditiva. Vem de `customer_rating` |
| **amt_km** | Valor por km (R$/km) | NUMERIC(12,2) | Derivada: `amt / dst` |
| **flg_cmp** | Flag Completa | VARCHAR(3) | 'Yes' se `booking_status` = 'Completed' |
| **flg_cnc** | Flag Cancelada | VARCHAR(3) | 'Yes' se `booking_status` contém 'Cancel' |
| **flg_inc** | Flag Incompleta | VARCHAR(3) | 'Yes' se `booking_status` = 'Incomplete' |
| **dat_crg** | Data de Carga | TIMESTAMP | Auditoria. Default: `CURRENT_TIMESTAMP` |

### Preenchimento (lookup das FKs):
```sql
INSERT INTO dwh.fat_cor (
    cor_key, srk_dtt, srk_cst, srk_rid, srk_pck, srk_drp,
    amt, dst, rtg_drv, rtg_cst, amt_km, flg_cmp, flg_cnc, flg_inc
)
SELECT 
    s.booking_id AS cor_key,
    dt.srk_dtt,
    c.srk_cst,
    r.srk_rid,
    pl.srk_loc AS srk_pck,
    dl.srk_loc AS srk_drp,
    s.booking_value AS amt,
    s.ride_distance AS dst,
    s.driver_ratings AS rtg_drv,
    s.customer_rating AS rtg_cst,
    CASE WHEN s.ride_distance > 0 THEN ROUND(s.booking_value / s.ride_distance, 2) ELSE NULL END AS amt_km,
    CASE WHEN s.booking_status = 'Completed' THEN 'Yes' ELSE 'No' END AS flg_cmp,
    CASE WHEN s.booking_status ILIKE '%cancel%' THEN 'Yes' ELSE 'No' END AS flg_cnc,
    CASE WHEN s.booking_status = 'Incomplete' THEN 'Yes' ELSE 'No' END AS flg_inc
FROM silver.uber_silver s
LEFT JOIN dwh.dim_dtt dt ON dt.dtt_key = (to_char(s.date, 'YYYYMMDD') || to_char(s.time::time, 'HH24MI'))::bigint
LEFT JOIN dwh.dim_cst c ON c.cst_ide = s.customer_id
LEFT JOIN dwh.dim_loc pl ON pl.loc_nme = s.pickup_location
LEFT JOIN dwh.dim_loc dl ON dl.loc_nme = s.drop_location
LEFT JOIN dwh.dim_rid r 
    ON r.vhc_tpe = s.vehicle_type 
    AND r.bkg_sts = s.booking_status
    AND r.pmt_mtd = s.payment_method
ON CONFLICT (cor_key) DO NOTHING;
```

---

## Resumo das Chaves

| Dimensão/Fato | Chave Primária | Tipo | Chave Natural |
|---------------|----------------|------|---------------|
| dim_dtt | srk_dtt | BIGSERIAL | dtt_key (BIGINT UNIQUE) |
| dim_cst | srk_cst | BIGSERIAL | cst_ide |
| dim_loc | srk_loc | BIGSERIAL | loc_nme |
| dim_rid | srk_rid | BIGSERIAL | Combinação de atributos |
| fat_cor | srk_cor | BIGSERIAL | cor_key (booking_id) |

---

## Glossário de Abreviações

- **srk**: Surrogate Key (chave substituta)
- **dtt**: DateTime (data/hora)
- **cst**: Customer (cliente)
- **loc**: Location (localização)
- **rid**: Ride (corrida)
- **cor**: Corrida (booking)
- **fat**: Fato (fact table)
- **dim**: Dimensão (dimension table)
- **dat**: Data (date)
- **hor**: Hora (hour/time)
- **yrr**: Year (ano)
- **qtr**: Quarter (trimestre)
- **mth**: Month (mês)
- **dow**: Day of Week (dia da semana)
- **wkd**: Weekend (fim de semana)
- **vhc**: Vehicle (veículo)
- **tpe**: Type (tipo)
- **bkg**: Booking (reserva)
- **sts**: Status
- **pmt**: Payment (pagamento)
- **mtd**: Method (método)
- **rsn**: Reason (motivo)
- **cst**: Customer (cliente) [também usado em rsn_cst]
- **drv**: Driver (motorista)
- **inc**: Incomplete (incompleto)
- **avg**: Average (média)
- **vtt**: Vehicle TAT (tempo alocação veículo)
- **ctt**: Customer TAT (tempo alocação cliente)
- **pck**: Pickup (origem)
- **drp**: Drop (destino)
- **amt**: Amount (valor)
- **dst**: Distance (distância)
- **rtg**: Rating (avaliação)
- **flg**: Flag (sinalizador)
- **cmp**: Complete (completo)
- **cnc**: Cancel (cancelado)
- **crg**: Carga (load)
- **cad**: Cadastro (registration)
- **nme**: Name (nome)
- **rgn**: Region (região)
- **zon**: Zone (zona)
- **ide**: ID/Identifier

---

## Exemplos de Consultas Úteis

### Receita por trimestre:
```sql
SELECT dt.yrr, dt.qtr, SUM(f.amt) AS receita_total
FROM dwh.fat_cor f
JOIN dwh.dim_dtt dt ON f.srk_dtt = dt.srk_dtt
WHERE f.flg_cmp = 'Yes'
GROUP BY dt.yrr, dt.qtr
ORDER BY dt.yrr, dt.qtr;
```

### Top 10 rotas mais lucrativas:
```sql
SELECT pl.loc_nme AS origem, dl.loc_nme AS destino,
       COUNT(*) AS total_corridas,
       SUM(f.amt) AS receita_total
FROM dwh.fat_cor f
JOIN dwh.dim_loc pl ON f.srk_pck = pl.srk_loc
JOIN dwh.dim_loc dl ON f.srk_drp = dl.srk_loc
WHERE f.flg_cmp = 'Yes'
GROUP BY pl.loc_nme, dl.loc_nme
ORDER BY receita_total DESC
LIMIT 10;
```

---

**Autor:** Sistema ETL Uber Analytics  
**Versão:** 2.0 (Mnemônicos silábicos - 4 dimensões reduzidas)  
**Data:** Novembro 2025
