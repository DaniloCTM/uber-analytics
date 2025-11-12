-- ===============================================
-- CONSULTAS BI 
-- ===============================================

-- ===============================================
-- 1. DASHBOARD EXECUTIVO DO MOTORISTA
-- ===============================================
-- KPIs principais: total de corridas, receita, distância, avaliação média
-- Útil para: Resumo geral de performance

SELECT 
    COUNT(*) AS total_corridas,
    COUNT(CASE WHEN r.bkg_sts = 'Completed' THEN 1 END) AS corridas_completas,
    COUNT(CASE WHEN r.bkg_sts != 'Completed' THEN 1 END) AS corridas_canceladas,
    ROUND(COUNT(CASE WHEN r.bkg_sts = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 2) AS taxa_conclusao_pct,
    ROUND(CAST(SUM(CASE WHEN r.bkg_sts = 'Completed' THEN f.amt ELSE 0 END) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(CASE WHEN r.bkg_sts = 'Completed' THEN f.amt END) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(SUM(CASE WHEN r.bkg_sts = 'Completed' THEN f.dst ELSE 0 END) AS NUMERIC), 2) AS km_total,
    ROUND(CAST(AVG(CASE WHEN r.bkg_sts = 'Completed' THEN f.dst END) AS NUMERIC), 2) AS km_medio,
    ROUND(CAST(AVG(CASE WHEN r.bkg_sts = 'Completed' THEN f.rtg_drv END) AS NUMERIC), 2) AS avaliacao_media_motorista,
    ROUND(CAST(SUM(CASE WHEN r.bkg_sts = 'Completed' THEN f.amt ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN r.bkg_sts = 'Completed' THEN f.dst END), 0) AS NUMERIC), 2) AS receita_por_km
FROM dwh.fat_cor f
JOIN dwh.dim_rid r ON f.srk_rid = r.srk_rid;


-- ===============================================
-- 2. PERFORMANCE POR PERÍODO (TRIMESTRE/MÊS)
-- ===============================================
-- Análise temporal de receita e volume de corridas
-- Útil para: Identificar sazonalidade e tendências

SELECT 
    dt.yrr AS ano,
    dt.qtr AS trimestre,
    dt.mth AS mes,
    TO_CHAR(TO_DATE(dt.mth::text, 'MM'), 'TMMonth') AS nome_mes,
    COUNT(*) AS total_corridas,
    COUNT(CASE WHEN f.flg_cmp = 'Yes' THEN 1 END) AS corridas_completas,
    ROUND(CAST(SUM(CASE WHEN f.flg_cmp = 'Yes' THEN f.amt ELSE 0 END) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(CASE WHEN f.flg_cmp = 'Yes' THEN f.amt END) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(SUM(CASE WHEN f.flg_cmp = 'Yes' THEN f.dst ELSE 0 END) AS NUMERIC), 2) AS km_total,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media
FROM dwh.fat_cor f
JOIN dwh.dim_dtt dt ON f.srk_dtt = dt.srk_dtt
WHERE f.flg_cmp = 'Yes'
GROUP BY dt.yrr, dt.qtr, dt.mth
ORDER BY dt.yrr, dt.mth;


-- ===============================================
-- 3. ANÁLISE DE HORÁRIOS MAIS LUCRATIVOS
-- ===============================================
-- Identifica os melhores horários para trabalhar
-- Útil para: Otimização de turnos e planejamento de agenda

SELECT 
    EXTRACT(HOUR FROM dt.hor) AS hora_dia,
    CASE 
        WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 6 AND 11 THEN 'Manhã'
        WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 12 AND 17 THEN 'Tarde'
        WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 18 AND 23 THEN 'Noite'
        ELSE 'Madrugada'
    END AS periodo_dia,
    COUNT(*) AS total_corridas,
    ROUND(CAST(SUM(f.amt) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(f.amt) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(SUM(f.dst) AS NUMERIC), 2) AS km_total,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media
FROM dwh.fat_cor f
JOIN dwh.dim_dtt dt ON f.srk_dtt = dt.srk_dtt
WHERE f.flg_cmp = 'Yes'
GROUP BY EXTRACT(HOUR FROM dt.hor),
         CASE 
             WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 6 AND 11 THEN 'Manhã'
             WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 12 AND 17 THEN 'Tarde'
             WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 18 AND 23 THEN 'Noite'
             ELSE 'Madrugada'
         END
ORDER BY receita_total DESC;


-- ===============================================
-- 4. ANÁLISE DE DIAS DA SEMANA (ÚTIL VS WEEKEND)
-- ===============================================
-- Compara performance entre dias úteis e finais de semana
-- Útil para: Estratégia de trabalho semanal

SELECT 
    dt.dow AS dia_semana_num,
    CASE dt.dow
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana_nome,
    dt.wkd AS eh_final_semana,
    COUNT(*) AS total_corridas,
    ROUND(CAST(SUM(f.amt) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(f.amt) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(AVG(f.dst) AS NUMERIC), 2) AS km_medio,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media
FROM dwh.fat_cor f
JOIN dwh.dim_dtt dt ON f.srk_dtt = dt.srk_dtt
WHERE f.flg_cmp = 'Yes'
GROUP BY dt.dow, dt.wkd
ORDER BY dt.dow;


-- ===============================================
-- 5. TOP 20 ROTAS MAIS LUCRATIVAS
-- ===============================================
-- Identifica as rotas com maior receita
-- Útil para: Foco em rotas de alto valor

SELECT 
    pl.loc_nme AS origem,
    dl.loc_nme AS destino,
    COUNT(*) AS total_corridas,
    ROUND(CAST(SUM(f.amt) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(f.amt) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(AVG(f.dst) AS NUMERIC), 2) AS km_medio,
    ROUND(CAST(SUM(f.amt) / NULLIF(SUM(f.dst), 0) AS NUMERIC), 2) AS receita_por_km,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media
FROM dwh.fat_cor f
JOIN dwh.dim_loc pl ON f.srk_pck = pl.srk_loc
JOIN dwh.dim_loc dl ON f.srk_drp = dl.srk_loc
WHERE f.flg_cmp = 'Yes'
GROUP BY pl.loc_nme, dl.loc_nme
ORDER BY receita_total DESC
LIMIT 20;


-- ===============================================
-- 6. ANÁLISE DE CANCELAMENTOS (CAUSAS E IMPACTO)
-- ===============================================
-- Analisa motivos de cancelamento e perda de receita
-- Útil para: Reduzir taxa de cancelamento

SELECT 
    r.bkg_sts AS status_corrida,
    COALESCE(r.rsn_drv, 'N/A') AS motivo_cancelamento_motorista,
    COALESCE(r.rsn_cst, 'N/A') AS motivo_cancelamento_cliente,
    COUNT(*) AS total_ocorrencias,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentual_total,
    ROUND(CAST(AVG(r.avg_vtt) AS NUMERIC), 2) AS tempo_medio_veiculo_min,
    ROUND(CAST(AVG(r.avg_ctt) AS NUMERIC), 2) AS tempo_medio_cliente_min,
    -- Estimativa de perda (baseada no ticket médio geral)
    ROUND(CAST(COUNT(*) * (SELECT AVG(amt) FROM dwh.fat_cor WHERE flg_cmp = 'Yes') AS NUMERIC), 2) AS perda_estimada
FROM dwh.fat_cor f
JOIN dwh.dim_rid r ON f.srk_rid = r.srk_rid
WHERE r.bkg_sts != 'Completed'
GROUP BY r.bkg_sts, r.rsn_drv, r.rsn_cst
ORDER BY total_ocorrencias DESC;


-- ===============================================
-- 7. ANÁLISE POR TIPO DE VEÍCULO
-- ===============================================
-- Compara performance entre diferentes categorias de veículo
-- Útil para: Decidir qual categoria focar

SELECT 
    r.vhc_tpe AS tipo_veiculo,
    COUNT(*) AS total_corridas,
    COUNT(CASE WHEN f.flg_cmp = 'Yes' THEN 1 END) AS corridas_completas,
    ROUND(COUNT(CASE WHEN f.flg_cmp = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS taxa_conclusao_pct,
    ROUND(CAST(SUM(CASE WHEN f.flg_cmp = 'Yes' THEN f.amt ELSE 0 END) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(CASE WHEN f.flg_cmp = 'Yes' THEN f.amt END) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(AVG(CASE WHEN f.flg_cmp = 'Yes' THEN f.dst END) AS NUMERIC), 2) AS km_medio,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media,
    ROUND(CAST(SUM(CASE WHEN f.flg_cmp = 'Yes' THEN f.amt ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN f.flg_cmp = 'Yes' THEN f.dst END), 0) AS NUMERIC), 2) AS receita_por_km
FROM dwh.fat_cor f
JOIN dwh.dim_rid r ON f.srk_rid = r.srk_rid
GROUP BY r.vhc_tpe
ORDER BY receita_total DESC;


-- ===============================================
-- 8. ANÁLISE DE FORMAS DE PAGAMENTO
-- ===============================================
-- Identifica preferências de pagamento e impacto na receita
-- Útil para: Entender comportamento de clientes

SELECT 
    r.pmt_mtd AS metodo_pagamento,
    COUNT(*) AS total_corridas,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentual_corridas,
    ROUND(CAST(SUM(f.amt) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(SUM(f.amt) * 100.0 / SUM(SUM(f.amt)) OVER() AS NUMERIC), 2) AS percentual_receita,
    ROUND(CAST(AVG(f.amt) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media
FROM dwh.fat_cor f
JOIN dwh.dim_rid r ON f.srk_rid = r.srk_rid
WHERE f.flg_cmp = 'Yes'
GROUP BY r.pmt_mtd
ORDER BY receita_total DESC;


-- ===============================================
-- 9. ANÁLISE DE AVALIAÇÕES (QUALIDADE DO SERVIÇO)
-- ===============================================
-- Distribui avaliações e identifica padrões
-- Útil para: Melhorar qualidade do atendimento

SELECT 
    CASE 
        WHEN f.rtg_drv >= 4.5 THEN '5 Estrelas (4.5-5.0)'
        WHEN f.rtg_drv >= 4.0 THEN '4 Estrelas (4.0-4.4)'
        WHEN f.rtg_drv >= 3.0 THEN '3 Estrelas (3.0-3.9)'
        WHEN f.rtg_drv >= 2.0 THEN '2 Estrelas (2.0-2.9)'
        WHEN f.rtg_drv >= 1.0 THEN '1 Estrela (1.0-1.9)'
        ELSE 'Sem Avaliação'
    END AS faixa_avaliacao,
    COUNT(*) AS total_corridas,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentual,
    ROUND(CAST(AVG(f.amt) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(AVG(f.dst) AS NUMERIC), 2) AS km_medio
FROM dwh.fat_cor f
JOIN dwh.dim_rid r ON f.srk_rid = r.srk_rid
WHERE f.flg_cmp = 'Yes' AND f.rtg_drv IS NOT NULL
GROUP BY 
    CASE 
        WHEN f.rtg_drv >= 4.5 THEN '5 Estrelas (4.5-5.0)'
        WHEN f.rtg_drv >= 4.0 THEN '4 Estrelas (4.0-4.4)'
        WHEN f.rtg_drv >= 3.0 THEN '3 Estrelas (3.0-3.9)'
        WHEN f.rtg_drv >= 2.0 THEN '2 Estrelas (2.0-2.9)'
        WHEN f.rtg_drv >= 1.0 THEN '1 Estrela (1.0-1.9)'
        ELSE 'Sem Avaliação'
    END
ORDER BY 
    CASE 
        WHEN f.rtg_drv >= 4.5 THEN 1
        WHEN f.rtg_drv >= 4.0 THEN 2
        WHEN f.rtg_drv >= 3.0 THEN 3
        WHEN f.rtg_drv >= 2.0 THEN 4
        WHEN f.rtg_drv >= 1.0 THEN 5
        ELSE 6
    END;


-- ===============================================
-- 10. MATRIZ DE OPORTUNIDADES (HORÁRIO x DIA DA SEMANA)
-- ===============================================
-- Identifica os melhores momentos para trabalhar
-- Útil para: Planejamento estratégico semanal

SELECT 
    CASE dt.dow
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana,
    CASE 
        WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 6 AND 11 THEN 'Manhã (6-11h)'
        WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 12 AND 17 THEN 'Tarde (12-17h)'
        WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 18 AND 23 THEN 'Noite (18-23h)'
        ELSE 'Madrugada (0-5h)'
    END AS periodo,
    COUNT(*) AS total_corridas,
    ROUND(CAST(SUM(f.amt) AS NUMERIC), 2) AS receita_total,
    ROUND(CAST(AVG(f.amt) AS NUMERIC), 2) AS ticket_medio,
    ROUND(CAST(AVG(f.rtg_drv) AS NUMERIC), 2) AS avaliacao_media,
    -- Score de oportunidade (combina volume e receita)
    ROUND(CAST(
        (COUNT(*) / NULLIF(MAX(COUNT(*)) OVER(), 0) * 50) + 
        (SUM(f.amt) / NULLIF(MAX(SUM(f.amt)) OVER(), 0) * 50) AS NUMERIC), 
        2
    ) AS score_oportunidade
FROM dwh.fat_cor f
JOIN dwh.dim_dtt dt ON f.srk_dtt = dt.srk_dtt
WHERE f.flg_cmp = 'Yes'
GROUP BY dt.dow, 
         CASE 
             WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 6 AND 11 THEN 'Manhã (6-11h)'
             WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 12 AND 17 THEN 'Tarde (12-17h)'
             WHEN EXTRACT(HOUR FROM dt.hor) BETWEEN 18 AND 23 THEN 'Noite (18-23h)'
             ELSE 'Madrugada (0-5h)'
         END
ORDER BY dt.dow, 
         CASE periodo
             WHEN 'Manhã (6-11h)' THEN 1
             WHEN 'Tarde (12-17h)' THEN 2
             WHEN 'Noite (18-23h)' THEN 3
             ELSE 4
         END;
