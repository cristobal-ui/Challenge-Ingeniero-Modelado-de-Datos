-- =====================================================================
-- stg_campaigns
-- Grano: 1 fila por campaign_id.
-- Limpieza: tipado de fechas, normalización de tipo, bandera de rango
--           de fechas inválido (end_date < start_date).
-- =====================================================================
CREATE OR REPLACE VIEW stg_campaigns AS
WITH src AS (
    SELECT
        TRIM(campaign_id)                   AS campaign_id,
        TRIM(campaign_name)                 AS campaign_name,
        TRY_CAST(start_date AS DATE)        AS start_date,
        TRY_CAST(end_date AS DATE)          AS end_date,
        LOWER(TRIM(campaign_type))          AS campaign_type,
        LOWER(TRIM(target_product))         AS target_product
    FROM raw_campaigns
    WHERE campaign_id IS NOT NULL AND TRIM(campaign_id) <> ''
)
SELECT
    campaign_id,
    campaign_name,
    start_date,
    end_date,
    campaign_type,
    target_product,
    -- Bandera de calidad: rango de vigencia coherente.
    (start_date IS NOT NULL
        AND end_date IS NOT NULL
        AND end_date >= start_date)         AS is_valid_date_range
FROM src
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY campaign_id
    ORDER BY start_date
) = 1;
