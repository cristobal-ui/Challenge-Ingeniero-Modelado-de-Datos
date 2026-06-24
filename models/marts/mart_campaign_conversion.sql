-- =====================================================================
-- mart_campaign_conversion
-- Grano: 1 fila por (campaign_id, customer_id) para clientes IMPACTADOS.
-- Es la tabla de consumo principal para Producto/Marketing: responde
-- impacto, interacción y conversión de la campaña en un solo lugar.
--
-- Reglas de negocio (ver README / DATA_DICTIONARY):
--   - Impactado : al menos un evento 'sent' de la campaña.
--   - Interactuó: al menos un evento 'opened' u 'clicked'.
--   - Convertido: impactado con >= 1 transacción VÁLIDA en 3 cuotas
--                 dentro de la vigencia [start_date, end_date].
-- Funciona para cualquier campaña con rango de fechas válido; la campaña
-- principal del challenge es CMP2026053CSI.
-- =====================================================================
CREATE OR REPLACE TABLE mart_campaign_conversion AS
WITH camp AS (
    SELECT campaign_id, campaign_name, start_date, end_date, target_product
    FROM stg_campaigns
    WHERE is_valid_date_range          -- excluye campañas con fechas inválidas
),
events_agg AS (
    -- Una fila por cliente y campaña con sus tipos de interacción.
    SELECT
        campaign_id,
        customer_id,
        BOOL_OR(event_type = 'sent')                                AS is_impacted,
        BOOL_OR(event_type = 'opened')                              AS has_opened,
        BOOL_OR(event_type = 'clicked')                             AS has_clicked,
        MIN(CASE WHEN event_type = 'sent' THEN event_date END)      AS first_sent_at
    FROM fact_campaign_event
    WHERE customer_exists AND campaign_exists   -- solo claves válidas
    GROUP BY campaign_id, customer_id
),
impacted AS (
    SELECT
        e.campaign_id, e.customer_id, e.has_opened, e.has_clicked, e.first_sent_at,
        c.campaign_name, c.start_date, c.end_date
    FROM events_agg e
    JOIN camp c USING (campaign_id)
    WHERE e.is_impacted
),
conv_txn AS (
    -- Transacciones válidas en 3 cuotas dentro de la ventana, por cliente-campaña.
    SELECT
        i.campaign_id,
        i.customer_id,
        COUNT(*)            AS num_valid_3cuota_txn,
        SUM(t.amount)       AS amount_3cuota_clp
    FROM impacted i
    JOIN fact_transaction t
        ON t.customer_id = i.customer_id
       AND t.is_valid_transaction
       AND t.is_3_installments
       AND t.transaction_day BETWEEN i.start_date AND i.end_date
    GROUP BY i.campaign_id, i.customer_id
)
SELECT
    i.campaign_id,
    i.campaign_name,
    i.customer_id,
    i.start_date,
    i.end_date,
    i.first_sent_at,
    TRUE                                            AS is_impacted,
    COALESCE(i.has_opened, FALSE)                   AS has_opened,
    COALESCE(i.has_clicked, FALSE)                  AS has_clicked,
    COALESCE(i.has_opened OR i.has_clicked, FALSE)  AS has_interacted,
    (ct.customer_id IS NOT NULL)                    AS is_converted,
    COALESCE(ct.num_valid_3cuota_txn, 0)            AS num_valid_3cuota_txn,
    COALESCE(ct.amount_3cuota_clp, 0)               AS amount_3cuota_clp
FROM impacted i
LEFT JOIN conv_txn ct
    ON  ct.campaign_id = i.campaign_id
    AND ct.customer_id = i.customer_id;
