-- =====================================================================
-- fact_campaign_event
-- Grano: 1 fila por evento de campaña (event_id = clave primaria).
-- Hecho de interacción cliente-campaña, conformado a las dimensiones.
-- =====================================================================
CREATE OR REPLACE TABLE fact_campaign_event AS
SELECT
    e.event_id,
    e.campaign_id,
    e.customer_id,
    e.event_date,
    CAST(e.event_date AS DATE)              AS event_day,
    e.event_type,
    e.channel,
    e.is_valid_event_type,
    -- Integridad referencial como banderas.
    (cmp.campaign_id IS NOT NULL)           AS campaign_exists,
    (dc.customer_id IS NOT NULL)            AS customer_exists,
    -- ¿El evento ocurrió dentro de la vigencia de su campaña?
    (cmp.start_date IS NOT NULL
        AND CAST(e.event_date AS DATE) BETWEEN cmp.start_date AND cmp.end_date)
                                            AS in_campaign_window
FROM stg_campaign_events e
LEFT JOIN stg_campaigns cmp ON cmp.campaign_id = e.campaign_id
LEFT JOIN dim_customer  dc  ON dc.customer_id  = e.customer_id;
