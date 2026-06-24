-- =====================================================================
-- stg_campaign_events
-- Grano: 1 fila por event_id.
-- Limpieza: tipado de fecha, normalización de event_type/channel, dedup,
--           bandera de event_type no reconocido (p.ej. 'bounce').
-- =====================================================================
CREATE OR REPLACE VIEW stg_campaign_events AS
WITH src AS (
    SELECT
        TRIM(event_id)                      AS event_id,
        TRIM(campaign_id)                   AS campaign_id,
        TRIM(customer_id)                   AS customer_id,
        TRY_CAST(event_date AS TIMESTAMP)   AS event_date,
        LOWER(TRIM(event_type))             AS event_type,
        LOWER(TRIM(channel))                AS channel
    FROM raw_campaign_events
    WHERE event_id IS NOT NULL AND TRIM(event_id) <> ''
)
SELECT
    event_id,
    NULLIF(campaign_id, '')                                     AS campaign_id,
    NULLIF(customer_id, '')                                     AS customer_id,
    event_date,
    event_type,
    channel,
    -- Solo estos tres tipos cuentan como interacción válida de campaña.
    (event_type IN ('sent','opened','clicked'))                 AS is_valid_event_type
FROM src
-- Dedup de eventos repetidos (mismo event_id).
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY event_id
    ORDER BY event_date DESC NULLS LAST
) = 1;
