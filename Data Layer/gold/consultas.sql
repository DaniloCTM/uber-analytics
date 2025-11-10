-- ============================================================================
-- CONSULTAS ANALÍTICAS E DE VALIDAÇÃO - CAMADA GOLD (DATA WAREHOUSE)
-- ============================================================================
-- Schema: dwh
-- Tabelas: fato_corridas + 8 dimensões
-- ============================================================================

-- ============================================================================
-- SEÇÃO 1: VALIDAÇÃO E INTEGRIDADE
-- ============================================================================

-- 1.1) Contagem geral de registros
SELECT 
    'fato_corridas' AS tabela,
    COUNT(*) AS total_registros
FROM dwh.fato_corridas
UNION ALL
SELECT 'dim_data', COUNT(*) FROM dwh.dim_data
UNION ALL
SELECT 'dim_tempo', COUNT(*) FROM dwh.dim_tempo
UNION ALL
SELECT 'dim_cliente', COUNT(*) FROM dwh.dim_cliente
UNION ALL
SELECT 'dim_veiculo', COUNT(*) FROM dwh.dim_veiculo
UNION ALL
SELECT 'dim_status', COUNT(*) FROM dwh.dim_status
UNION ALL
SELECT 'dim_localizacao', COUNT(*) FROM dwh.dim_localizacao
UNION ALL
SELECT 'dim_pagamento', COUNT(*) FROM dwh.dim_pagamento
UNION ALL
SELECT 'dim_motivo_cancelamento', COUNT(*) FROM dwh.dim_motivo_cancelamento;

-- 1.2) Verificar integridade referencial (NULLs nas FKs)
SELECT 
    COUNT(*) AS total_corridas,
    COUNT(data_key) AS com_data,
    COUNT(tempo_key) AS com_tempo,
    COUNT(cliente_key) AS com_cliente,
    COUNT(veiculo_key) AS com_veiculo,
    COUNT(status_key) AS com_status,
    COUNT(pickup_local_key) AS com_pickup,
    COUNT(drop_local_key) AS com_drop,
    COUNT(pagamento_key) AS com_pagamento,
    COUNT(motivo_key) AS com_motivo
FROM dwh.fato_corridas;

-- 1.3) Estatísticas gerais de métricas
SELECT 
    COUNT(*) AS total_corridas,
    SUM(booking_value) AS receita_total,
    AVG(booking_value) AS ticket_medio,
    SUM(ride_distance) AS distancia_total_km,
    AVG(ride_distance) AS distancia_media_km,
    AVG(valor_por_km) AS valor_medio_por_km,
    AVG(driver_ratings) AS rating_medio_motorista,
    AVG(customer_rating) AS rating_medio_cliente,
    SUM(CASE WHEN corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    SUM(CASE WHEN corrida_cancelada THEN 1 ELSE 0 END) AS corridas_canceladas,
    SUM(CASE WHEN corrida_incompleta THEN 1 ELSE 0 END) AS corridas_incompletas
FROM dwh.fato_corridas;

-- ============================================================================
-- SEÇÃO 2: ANÁLISES TEMPORAIS
-- ============================================================================

-- 2.1) Receita e volume por dia da semana
SELECT 
    d.nome_dia_semana,
    d.dia_da_semana,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    SUM(f.ride_distance) AS distancia_total,
    AVG(f.driver_ratings) AS rating_medio_motorista
FROM dwh.fato_corridas f
JOIN dwh.dim_data d ON f.data_key = d.data_key
WHERE f.corrida_completa = TRUE
GROUP BY d.nome_dia_semana, d.dia_da_semana
ORDER BY d.dia_da_semana;

-- 2.2) Comparação Dia Útil vs Fim de Semana
SELECT 
    CASE WHEN d.fim_de_semana THEN 'Fim de Semana' ELSE 'Dia Útil' END AS tipo_dia,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media
FROM dwh.fato_corridas f
JOIN dwh.dim_data d ON f.data_key = d.data_key
WHERE f.corrida_completa = TRUE
GROUP BY d.fim_de_semana
ORDER BY tipo_dia;

-- 2.3) Análise por período do dia (Madrugada, Manhã, Tarde, Noite)
SELECT 
    t.periodo,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media
FROM dwh.fato_corridas f
JOIN dwh.dim_tempo t ON f.tempo_key = t.tempo_key
WHERE f.corrida_completa = TRUE
GROUP BY t.periodo
ORDER BY 
    CASE t.periodo
        WHEN 'Madrugada' THEN 1
        WHEN 'Manhã' THEN 2
        WHEN 'Tarde' THEN 3
        WHEN 'Noite' THEN 4
    END;

-- 2.4) Horário de pico vs Horário normal
SELECT 
    CASE WHEN t.hora_pico THEN 'Horário de Pico' ELSE 'Horário Normal' END AS tipo_horario,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media,
    AVG(f.avg_vtat) AS tempo_medio_vtat,
    AVG(f.avg_ctat) AS tempo_medio_ctat
FROM dwh.fato_corridas f
JOIN dwh.dim_tempo t ON f.tempo_key = t.tempo_key
WHERE f.corrida_completa = TRUE
GROUP BY t.hora_pico
ORDER BY tipo_horario;

-- 2.5) Evolução mensal de receita
SELECT 
    d.ano,
    d.mes,
    d.nome_mes,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    SUM(f.ride_distance) AS distancia_total_km
FROM dwh.fato_corridas f
JOIN dwh.dim_data d ON f.data_key = d.data_key
WHERE f.corrida_completa = TRUE
GROUP BY d.ano, d.mes, d.nome_mes
ORDER BY d.ano, d.mes;

-- ============================================================================
-- SEÇÃO 3: ANÁLISES POR VEÍCULO
-- ============================================================================

-- 3.1) Performance por tipo de veículo
SELECT 
    v.vehicle_type,
    v.categoria,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media,
    AVG(f.driver_ratings) AS rating_medio_motorista,
    SUM(f.ride_distance) AS distancia_total
FROM dwh.fato_corridas f
JOIN dwh.dim_veiculo v ON f.veiculo_key = v.veiculo_key
WHERE f.corrida_completa = TRUE
GROUP BY v.vehicle_type, v.categoria
ORDER BY receita_total DESC;

-- 3.2) Ranking de veículos por receita média (ticket médio)
SELECT 
    v.vehicle_type,
    COUNT(*) AS total_corridas,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media,
    AVG(f.valor_por_km) AS valor_por_km
FROM dwh.fato_corridas f
JOIN dwh.dim_veiculo v ON f.veiculo_key = v.veiculo_key
WHERE f.corrida_completa = TRUE
GROUP BY v.vehicle_type
HAVING COUNT(*) >= 10  -- Apenas veículos com volume significativo
ORDER BY ticket_medio DESC;

-- ============================================================================
-- SEÇÃO 4: ANÁLISES GEOGRÁFICAS (ROTAS E LOCALIZAÇÕES)
-- ============================================================================

-- 4.1) Top 20 rotas mais rentáveis
SELECT 
    pickup.local_nome AS origem,
    drop.local_nome AS destino,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media,
    AVG(f.driver_ratings) AS rating_medio
FROM dwh.fato_corridas f
JOIN dwh.dim_localizacao pickup ON f.pickup_local_key = pickup.local_key
JOIN dwh.dim_localizacao drop ON f.drop_local_key = drop.local_key
WHERE f.corrida_completa = TRUE
GROUP BY pickup.local_nome, drop.local_nome
ORDER BY receita_total DESC
LIMIT 20;

-- 4.2) Top 10 locais de origem (pickup) por volume
SELECT 
    pickup.local_nome AS origem,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio
FROM dwh.fato_corridas f
JOIN dwh.dim_localizacao pickup ON f.pickup_local_key = pickup.local_key
WHERE f.corrida_completa = TRUE
GROUP BY pickup.local_nome
ORDER BY total_corridas DESC
LIMIT 10;

-- 4.3) Top 10 locais de destino (drop) por volume
SELECT 
    drop.local_nome AS destino,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio
FROM dwh.fato_corridas f
JOIN dwh.dim_localizacao drop ON f.drop_local_key = drop.local_key
WHERE f.corrida_completa = TRUE
GROUP BY drop.local_nome
ORDER BY total_corridas DESC
LIMIT 10;

-- ============================================================================
-- SEÇÃO 5: ANÁLISES DE CLIENTES
-- ============================================================================

-- 5.1) Top 20 clientes por receita
SELECT 
    c.customer_id,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    SUM(f.ride_distance) AS distancia_total,
    AVG(f.customer_rating) AS rating_medio_cliente,
    MIN(d.data_completa) AS primeira_corrida,
    MAX(d.data_completa) AS ultima_corrida
FROM dwh.fato_corridas f
JOIN dwh.dim_cliente c ON f.cliente_key = c.cliente_key
JOIN dwh.dim_data d ON f.data_key = d.data_key
WHERE f.corrida_completa = TRUE
GROUP BY c.customer_id
ORDER BY receita_total DESC
LIMIT 20;

-- 5.2) Segmentação de clientes por frequência
SELECT 
    CASE 
        WHEN total_corridas >= 50 THEN 'VIP (50+)'
        WHEN total_corridas >= 20 THEN 'Frequente (20-49)'
        WHEN total_corridas >= 10 THEN 'Regular (10-19)'
        WHEN total_corridas >= 5 THEN 'Ocasional (5-9)'
        ELSE 'Esporádico (1-4)'
    END AS segmento,
    COUNT(DISTINCT customer_id) AS total_clientes,
    SUM(total_corridas) AS corridas_totais,
    SUM(receita_total) AS receita_total,
    AVG(ticket_medio) AS ticket_medio_geral
FROM (
    SELECT 
        c.customer_id,
        COUNT(*) AS total_corridas,
        SUM(f.booking_value) AS receita_total,
        AVG(f.booking_value) AS ticket_medio
    FROM dwh.fato_corridas f
    JOIN dwh.dim_cliente c ON f.cliente_key = c.cliente_key
    WHERE f.corrida_completa = TRUE
    GROUP BY c.customer_id
) AS cliente_stats
GROUP BY segmento
ORDER BY 
    CASE segmento
        WHEN 'VIP (50+)' THEN 1
        WHEN 'Frequente (20-49)' THEN 2
        WHEN 'Regular (10-19)' THEN 3
        WHEN 'Ocasional (5-9)' THEN 4
        ELSE 5
    END;

-- ============================================================================
-- SEÇÃO 6: ANÁLISES DE STATUS E CANCELAMENTO
-- ============================================================================

-- 6.1) Distribuição de status de corridas
SELECT 
    s.booking_status,
    s.status_categoria,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentual,
    SUM(f.booking_value) AS receita_perdida
FROM dwh.fato_corridas f
JOIN dwh.dim_status s ON f.status_key = s.status_key
GROUP BY s.booking_status, s.status_categoria
ORDER BY total DESC;

-- 6.2) Taxa de conversão (completas vs total)
SELECT 
    COUNT(*) AS total_corridas,
    SUM(CASE WHEN corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    SUM(CASE WHEN corrida_cancelada THEN 1 ELSE 0 END) AS corridas_canceladas,
    SUM(CASE WHEN corrida_incompleta THEN 1 ELSE 0 END) AS corridas_incompletas,
    ROUND(100.0 * SUM(CASE WHEN corrida_completa THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_conversao,
    ROUND(100.0 * SUM(CASE WHEN corrida_cancelada THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_cancelamento
FROM dwh.fato_corridas;

-- 6.3) Principais motivos de cancelamento
SELECT 
    m.reason_cancel_customer AS motivo_cliente,
    m.driver_cancellation_reason AS motivo_motorista,
    m.incomplete_rides_reason AS motivo_incompleto,
    COUNT(*) AS total_ocorrencias
FROM dwh.fato_corridas f
JOIN dwh.dim_motivo_cancelamento m ON f.motivo_key = m.motivo_key
WHERE f.corrida_cancelada = TRUE OR f.corrida_incompleta = TRUE
GROUP BY m.reason_cancel_customer, m.driver_cancellation_reason, m.incomplete_rides_reason
ORDER BY total_ocorrencias DESC
LIMIT 20;

-- ============================================================================
-- SEÇÃO 7: ANÁLISES DE PAGAMENTO
-- ============================================================================

-- 7.1) Distribuição por método de pagamento
SELECT 
    p.payment_method,
    p.tipo_pagamento,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentual_volume
FROM dwh.fato_corridas f
JOIN dwh.dim_pagamento p ON f.pagamento_key = p.pagamento_key
WHERE f.corrida_completa = TRUE
GROUP BY p.payment_method, p.tipo_pagamento
ORDER BY total_corridas DESC;

-- 7.2) Digital vs Dinheiro
SELECT 
    p.tipo_pagamento,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    AVG(f.ride_distance) AS distancia_media
FROM dwh.fato_corridas f
JOIN dwh.dim_pagamento p ON f.pagamento_key = p.pagamento_key
WHERE f.corrida_completa = TRUE
GROUP BY p.tipo_pagamento
ORDER BY receita_total DESC;

-- ============================================================================
-- SEÇÃO 8: ANÁLISES DE QUALIDADE E SATISFAÇÃO
-- ============================================================================

-- 8.1) Distribuição de ratings de motoristas
SELECT 
    CASE 
        WHEN driver_ratings >= 4.5 THEN 'Excelente (4.5+)'
        WHEN driver_ratings >= 4.0 THEN 'Bom (4.0-4.49)'
        WHEN driver_ratings >= 3.0 THEN 'Regular (3.0-3.99)'
        ELSE 'Ruim (<3.0)'
    END AS faixa_rating,
    COUNT(*) AS total_corridas,
    AVG(driver_ratings) AS rating_medio,
    AVG(booking_value) AS ticket_medio
FROM dwh.fato_corridas
WHERE driver_ratings IS NOT NULL AND corrida_completa = TRUE
GROUP BY faixa_rating
ORDER BY rating_medio DESC;

-- 8.2) Correlação entre rating e tipo de veículo
SELECT 
    v.vehicle_type,
    COUNT(*) AS total_corridas,
    AVG(f.driver_ratings) AS rating_medio_motorista,
    AVG(f.customer_rating) AS rating_medio_cliente,
    AVG(f.booking_value) AS ticket_medio
FROM dwh.fato_corridas f
JOIN dwh.dim_veiculo v ON f.veiculo_key = v.veiculo_key
WHERE f.corrida_completa = TRUE 
  AND f.driver_ratings IS NOT NULL
GROUP BY v.vehicle_type
HAVING COUNT(*) >= 10
ORDER BY rating_medio_motorista DESC;

-- ============================================================================
-- SEÇÃO 9: ANÁLISES AVANÇADAS (CUBOS OLAP)
-- ============================================================================

-- 9.1) Cubo: Dia da Semana x Período x Veículo
SELECT 
    d.nome_dia_semana,
    t.periodo,
    v.categoria AS categoria_veiculo,
    COUNT(*) AS total_corridas,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio
FROM dwh.fato_corridas f
JOIN dwh.dim_data d ON f.data_key = d.data_key
JOIN dwh.dim_tempo t ON f.tempo_key = t.tempo_key
JOIN dwh.dim_veiculo v ON f.veiculo_key = v.veiculo_key
WHERE f.corrida_completa = TRUE
GROUP BY d.nome_dia_semana, d.dia_da_semana, t.periodo, v.categoria
ORDER BY d.dia_da_semana, 
    CASE t.periodo
        WHEN 'Madrugada' THEN 1
        WHEN 'Manhã' THEN 2
        WHEN 'Tarde' THEN 3
        WHEN 'Noite' THEN 4
    END,
    receita_total DESC;

-- 9.2) Análise de eficiência: R$/km por veículo e período
SELECT 
    v.vehicle_type,
    t.periodo,
    COUNT(*) AS total_corridas,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.ride_distance) AS distancia_media,
    AVG(f.booking_value) AS ticket_medio
FROM dwh.fato_corridas f
JOIN dwh.dim_veiculo v ON f.veiculo_key = v.veiculo_key
JOIN dwh.dim_tempo t ON f.tempo_key = t.tempo_key
WHERE f.corrida_completa = TRUE AND f.valor_por_km IS NOT NULL
GROUP BY v.vehicle_type, t.periodo
ORDER BY v.vehicle_type, 
    CASE t.periodo
        WHEN 'Madrugada' THEN 1
        WHEN 'Manhã' THEN 2
        WHEN 'Tarde' THEN 3
        WHEN 'Noite' THEN 4
    END;

-- ============================================================================
-- SEÇÃO 10: KPIs E MÉTRICAS DE NEGÓCIO
-- ============================================================================

-- 10.1) Dashboard executivo (KPIs principais)
SELECT 
    COUNT(*) AS total_corridas,
    COUNT(DISTINCT c.customer_id) AS total_clientes_ativos,
    SUM(f.booking_value) AS receita_total,
    AVG(f.booking_value) AS ticket_medio,
    SUM(f.ride_distance) AS km_rodados,
    AVG(f.ride_distance) AS km_medio_por_corrida,
    AVG(f.valor_por_km) AS receita_por_km,
    AVG(f.driver_ratings) AS satisfacao_motorista,
    AVG(f.customer_rating) AS satisfacao_cliente,
    ROUND(100.0 * SUM(CASE WHEN f.corrida_completa THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_conversao,
    AVG(f.avg_vtat) AS tempo_medio_vtat,
    AVG(f.avg_ctat) AS tempo_medio_ctat
FROM dwh.fato_corridas f
JOIN dwh.dim_cliente c ON f.cliente_key = c.cliente_key
WHERE f.data_key >= 20230101;  -- Ajustar conforme período desejado
