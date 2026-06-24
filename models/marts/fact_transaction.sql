-- =====================================================================
-- fact_transaction
-- Grano: 1 fila por transacción (transaction_id = clave primaria).
-- Hecho transaccional limpio y conformado contra las dimensiones.
-- Conserva todas las transacciones identificables; la validez de negocio
-- queda expresada en banderas reutilizables (is_valid_transaction, etc.).
-- =====================================================================
CREATE OR REPLACE TABLE fact_transaction AS
SELECT
    t.transaction_id,
    -- Claves foráneas conformadas a dimensiones.
    t.customer_id,
    t.card_id,
    t.merchant_id,
    -- Degeneradas de fecha (útiles para análisis temporal y partición en BQ).
    t.transaction_date,
    CAST(t.transaction_date AS DATE)                    AS transaction_day,
    -- Medidas.
    t.amount,
    t.currency,
    t.installments,
    -- Atributos de estado normalizados.
    t.transaction_status,
    t.transaction_type,
    -- Banderas de negocio / calidad (definición única, ver stg_transactions).
    t.is_3_installments,
    t.is_valid_transaction,
    t.is_invalid_amount,
    t.is_invalid_date,
    -- Integridad referencial materializada como banderas (no se borra nada).
    (dc.customer_id IS NOT NULL)                        AS customer_exists,
    (dm.merchant_id IS NOT NULL)                        AS merchant_exists,
    (sc.card_id IS NOT NULL)                            AS card_exists
FROM stg_transactions t
LEFT JOIN dim_customer dc ON dc.customer_id = t.customer_id
LEFT JOIN dim_merchant dm ON dm.merchant_id = t.merchant_id
LEFT JOIN stg_cards   sc ON sc.card_id     = t.card_id;
