-- =====================================================================
-- stg_customers
-- Grano: 1 fila por customer_id (cliente único).
-- Limpieza: tipado de fechas, normalización de estados, dedup, drop de
--           filas sin clave (no identificables).
-- =====================================================================
CREATE OR REPLACE VIEW stg_customers AS
WITH src AS (
    SELECT
        TRIM(customer_id)                               AS customer_id,
        TRY_CAST(created_at AS TIMESTAMP)               AS created_at,
        TRY_CAST(birth_date AS DATE)                    AS birth_date,
        UPPER(TRIM(gender))                             AS gender,
        TRIM(region)                                    AS region,
        TRIM(city)                                      AS city,
        LOWER(TRIM(customer_status))                    AS customer_status,
        LOWER(TRIM(risk_segment))                       AS risk_segment,
        TRIM(income_range)                              AS income_range
    FROM raw_customers
    -- Se descartan filas sin customer_id: no son identificables ni
    -- referenciables, por lo que no pueden formar parte de la dimensión.
    WHERE customer_id IS NOT NULL AND TRIM(customer_id) <> ''
),
flagged AS (
    SELECT
        customer_id,
        created_at,
        birth_date,
        -- Normalización de dominios a valores canónicos.
        CASE WHEN gender IN ('M','F') THEN gender ELSE 'U' END          AS gender,
        region,
        city,
        CASE WHEN customer_status IN ('active','inactive','blocked')
             THEN customer_status ELSE 'unknown' END                    AS customer_status,
        CASE WHEN risk_segment IN ('low','medium','high')
             THEN risk_segment ELSE 'unknown' END                       AS risk_segment,
        COALESCE(NULLIF(income_range,''), 'unknown')                    AS income_range,
        -- Bandera de calidad: fecha de creación en el futuro.
        (created_at > CURRENT_TIMESTAMP)                                AS is_future_created
    FROM src
)
SELECT *
FROM flagged
-- Dedup determinístico: ante customer_id repetido se conserva el registro
-- más reciente por created_at (los nulos al final).
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY created_at DESC NULLS LAST
) = 1;
