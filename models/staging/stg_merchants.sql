-- =====================================================================
-- stg_merchants
-- Grano: 1 fila por merchant_id.
-- Limpieza: trim de texto, normalización de categoría, dedup.
-- =====================================================================
CREATE OR REPLACE VIEW stg_merchants AS
WITH src AS (
    SELECT
        TRIM(merchant_id)                   AS merchant_id,
        TRIM(merchant_name)                 AS merchant_name,
        LOWER(TRIM(merchant_category))      AS merchant_category,
        TRIM(region)                        AS region,
        TRIM(city)                          AS city
    FROM raw_merchants
    WHERE merchant_id IS NOT NULL AND TRIM(merchant_id) <> ''
)
SELECT
    merchant_id,
    COALESCE(NULLIF(merchant_name,''), 'unknown')       AS merchant_name,
    COALESCE(NULLIF(merchant_category,''), 'unknown')   AS merchant_category,
    region,
    city
FROM src
-- Dedup de comercios repetidos (mismo merchant_id): se conserva una fila.
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY merchant_id
    ORDER BY merchant_name
) = 1;
