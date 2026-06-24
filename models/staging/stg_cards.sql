-- =====================================================================
-- stg_cards
-- Grano: 1 fila por card_id.
-- Limpieza: tipado de fecha, normalización de estado, dedup.
-- =====================================================================
CREATE OR REPLACE VIEW stg_cards AS
WITH src AS (
    SELECT
        TRIM(card_id)                       AS card_id,
        TRIM(customer_id)                   AS customer_id,
        TRIM(account_id)                    AS account_id,
        LOWER(TRIM(card_type))              AS card_type,
        TRY_CAST(created_at AS TIMESTAMP)   AS created_at,
        LOWER(TRIM(status))                 AS status
    FROM raw_cards
    WHERE card_id IS NOT NULL AND TRIM(card_id) <> ''
)
SELECT
    card_id,
    NULLIF(customer_id, '')                 AS customer_id,
    NULLIF(account_id, '')                  AS account_id,
    card_type,
    created_at,
    CASE WHEN status IN ('active','inactive','blocked','expired')
         THEN status ELSE 'unknown' END     AS status
FROM src
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY card_id
    ORDER BY created_at DESC NULLS LAST
) = 1;
