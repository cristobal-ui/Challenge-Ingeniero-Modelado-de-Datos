-- =====================================================================
-- CONSULTAS DE NEGOCIO sobre el modelo final
-- Campaña principal: CMP2026053CSI (3 cuotas sin interés, mayo 2026).
-- Todas se apoyan en mart_campaign_conversion / fact_* (sin lógica ad hoc).
-- =====================================================================

-- Q1 — ¿Cuántos clientes fueron impactados, interactuaron y convirtieron?
--       + tasa de conversión global de la campaña.
SELECT
    COUNT(*)                                              AS clientes_impactados,
    SUM(CASE WHEN has_interacted THEN 1 ELSE 0 END)       AS clientes_interactuaron,
    SUM(CASE WHEN is_converted   THEN 1 ELSE 0 END)       AS clientes_convertidos,
    ROUND(100.0 * SUM(CASE WHEN is_converted THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                          AS tasa_conversion_pct
FROM mart_campaign_conversion
WHERE campaign_id = (SELECT target_campaign_id FROM analysis_config);

-- Q2 — Tasa de conversión por segmento de riesgo (rendimiento por segmento).
SELECT
    dc.risk_segment,
    COUNT(*)                                              AS impactados,
    SUM(CASE WHEN m.is_converted THEN 1 ELSE 0 END)       AS convertidos,
    ROUND(100.0 * SUM(CASE WHEN m.is_converted THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                          AS tasa_conversion_pct
FROM mart_campaign_conversion m
JOIN dim_customer dc USING (customer_id)
WHERE m.campaign_id = (SELECT target_campaign_id FROM analysis_config)
GROUP BY dc.risk_segment
ORDER BY tasa_conversion_pct DESC;

-- Q3 — Comercios que concentraron mayor MONTO en 3 cuotas durante la campaña.
--       (solo transacciones válidas de clientes impactados, dentro de ventana)
SELECT
    dm.merchant_id,
    dm.merchant_name,
    dm.merchant_category,
    COUNT(*)                                              AS num_txn_3cuotas,
    SUM(t.amount)                                         AS monto_total_3cuotas_clp,
    ROUND(AVG(t.amount), 0)                               AS ticket_promedio_clp
FROM mart_campaign_conversion m
JOIN stg_campaigns c        ON c.campaign_id = m.campaign_id
JOIN fact_transaction t
    ON  t.customer_id = m.customer_id
    AND t.is_valid_transaction
    AND t.is_3_installments
    AND t.transaction_day BETWEEN c.start_date AND c.end_date
JOIN dim_merchant dm        ON dm.merchant_id = t.merchant_id
WHERE m.campaign_id = (SELECT target_campaign_id FROM analysis_config)
GROUP BY dm.merchant_id, dm.merchant_name, dm.merchant_category
ORDER BY monto_total_3cuotas_clp DESC
LIMIT 10;

-- Q4 — Ticket promedio y monto total en 3 cuotas de clientes CONVERTIDOS.
SELECT
    COUNT(*)                                              AS clientes_convertidos,
    SUM(num_valid_3cuota_txn)                             AS total_txn_3cuotas,
    SUM(amount_3cuota_clp)                                AS monto_total_3cuotas_clp,
    ROUND(SUM(amount_3cuota_clp) / NULLIF(SUM(num_valid_3cuota_txn),0), 0)
                                                          AS ticket_promedio_clp
FROM mart_campaign_conversion
WHERE campaign_id = (SELECT target_campaign_id FROM analysis_config)
  AND is_converted;

-- Q5 — Embudo (funnel) de la campaña por canal del evento 'sent'.
SELECT
    fe.channel,
    COUNT(DISTINCT fe.customer_id)                        AS impactados,
    COUNT(DISTINCT CASE WHEN m.has_interacted THEN m.customer_id END) AS interactuaron,
    COUNT(DISTINCT CASE WHEN m.is_converted   THEN m.customer_id END) AS convirtieron
FROM fact_campaign_event fe
JOIN mart_campaign_conversion m
    ON m.campaign_id = fe.campaign_id AND m.customer_id = fe.customer_id
WHERE fe.campaign_id = (SELECT target_campaign_id FROM analysis_config)
  AND fe.event_type = 'sent'
GROUP BY fe.channel
ORDER BY impactados DESC;
