-- =====================================================================
-- stg_accounts
-- Grano: 1 fila por account_id.
-- Limpieza: tipado de fecha, normalización de estado, dedup.
-- La integridad referencial hacia customers se valida en la capa de
-- calidad (no se borran huérfanos aquí, se documentan).
-- =====================================================================
CREATE OR REPLACE VIEW stg_accounts AS
WITH src AS (
    SELECT
        TRIM(account_id)                    AS account_id,
        TRIM(customer_id)                   AS customer_id,
        LOWER(TRIM(account_type))           AS account_type,
        TRY_CAST(created_at AS TIMESTAMP)   AS created_at,
        LOWER(TRIM(status))                 AS status
    FROM raw_accounts
    WHERE account_id IS NOT NULL AND TRIM(account_id) <> ''
)
SELECT
    account_id,
    NULLIF(customer_id, '')                 AS customer_id,
    account_type,
    created_at,
    CASE WHEN status IN ('active','inactive','blocked','closed')
         THEN status ELSE 'unknown' END     AS status
FROM src
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY account_id
    ORDER BY created_at DESC NULLS LAST
) = 1;
