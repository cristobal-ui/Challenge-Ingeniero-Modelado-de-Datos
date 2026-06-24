-- =====================================================================
-- stg_transactions
-- Grano: 1 fila por transaction_id.
-- Limpieza: tipado de fecha y monto, normalización de estado/tipo, dedup.
-- Calidad: se conservan TODAS las transacciones identificables y se
--          marcan con banderas (negativo, futuro, estado inválido). La
--          regla de "transacción válida" se materializa en una sola
--          columna reutilizable para evitar duplicar lógica aguas abajo.
-- =====================================================================
CREATE OR REPLACE VIEW stg_transactions AS
WITH src AS (
    SELECT
        TRIM(transaction_id)                        AS transaction_id,
        TRIM(customer_id)                           AS customer_id,
        TRIM(card_id)                               AS card_id,
        TRIM(merchant_id)                           AS merchant_id,
        TRY_CAST(transaction_date AS TIMESTAMP)     AS transaction_date,
        TRY_CAST(amount AS DECIMAL(18,2))           AS amount,
        UPPER(TRIM(currency))                       AS currency,
        TRY_CAST(installments AS INTEGER)           AS installments,
        LOWER(TRIM(transaction_status))             AS transaction_status,
        LOWER(TRIM(transaction_type))               AS transaction_type
    FROM raw_transactions
    WHERE transaction_id IS NOT NULL AND TRIM(transaction_id) <> ''
),
typed AS (
    SELECT
        transaction_id,
        NULLIF(customer_id, '')                     AS customer_id,
        NULLIF(card_id, '')                         AS card_id,
        NULLIF(merchant_id, '')                     AS merchant_id,
        transaction_date,
        amount,
        COALESCE(NULLIF(currency,''), 'CLP')        AS currency,
        installments,
        CASE WHEN transaction_status IN ('approved','pending','rejected','reversed')
             THEN transaction_status ELSE 'unknown' END AS transaction_status,
        CASE WHEN transaction_type IN ('purchase','refund','withdrawal')
             THEN transaction_type ELSE 'unknown' END   AS transaction_type,
        -- Banderas de calidad individuales (sirven para los controles).
        (amount IS NULL OR amount <= 0)             AS is_invalid_amount,
        (transaction_date IS NULL
            OR transaction_date > CURRENT_TIMESTAMP) AS is_invalid_date,
        (installments = 3)                          AS is_3_installments
    FROM src
)
SELECT
    *,
    -- Definición ÚNICA y reutilizable de "transacción válida":
    -- compra aprobada, monto positivo y fecha no futura.
    (transaction_status = 'approved'
        AND transaction_type = 'purchase'
        AND NOT is_invalid_amount
        AND NOT is_invalid_date)                    AS is_valid_transaction
FROM typed
-- Dedup de transacciones repetidas (mismo transaction_id).
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY transaction_id
    ORDER BY transaction_date DESC NULLS LAST
) = 1;
