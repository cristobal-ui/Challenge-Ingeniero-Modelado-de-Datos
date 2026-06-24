-- =====================================================================
-- dim_merchant
-- Grano: 1 fila por comercio (merchant_id = clave primaria).
-- =====================================================================
CREATE OR REPLACE TABLE dim_merchant AS
SELECT
    merchant_id,
    merchant_name,
    merchant_category,
    region,
    city
FROM stg_merchants;
