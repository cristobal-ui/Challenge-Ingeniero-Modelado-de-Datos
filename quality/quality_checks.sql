-- =====================================================================
-- CONTROLES DE CALIDAD (data quality assertions)
-- ---------------------------------------------------------------------
-- Patrón: cada control es un SELECT que devuelve las filas que VIOLAN
-- la regla. failures = 0  ==>  control OK.
-- En dbt esto serían tests singulares; en Dataform, assertions.
-- El runner los ejecuta y reporta el conteo de violaciones por control.
-- =====================================================================

-- QC01 — Unicidad de PK en dim_customer (no debe haber customer_id repetido).
CREATE OR REPLACE VIEW qc01_pk_customer AS
SELECT customer_id, COUNT(*) AS n
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- QC02 — Unicidad de PK en fact_transaction.
CREATE OR REPLACE VIEW qc02_pk_transaction AS
SELECT transaction_id, COUNT(*) AS n
FROM fact_transaction
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- QC03 — Integridad referencial: transacciones con customer_id inexistente.
CREATE OR REPLACE VIEW qc03_txn_customer_fk AS
SELECT transaction_id, customer_id
FROM fact_transaction
WHERE customer_id IS NOT NULL
  AND customer_exists = FALSE;

-- QC04 — Montos no positivos en transacciones aprobadas de compra.
CREATE OR REPLACE VIEW qc04_negative_amounts AS
SELECT transaction_id, amount, transaction_status, transaction_type
FROM fact_transaction
WHERE is_invalid_amount = TRUE
  AND transaction_status = 'approved'
  AND transaction_type = 'purchase';

-- QC05 — Fechas fuera de rango (transacciones con fecha futura o no parseable).
CREATE OR REPLACE VIEW qc05_invalid_dates AS
SELECT transaction_id, transaction_date
FROM fact_transaction
WHERE is_invalid_date = TRUE;

-- QC06 — Eventos de campaña con event_type no reconocido (p.ej. 'bounce').
CREATE OR REPLACE VIEW qc06_unknown_event_type AS
SELECT event_id, event_type
FROM fact_campaign_event
WHERE is_valid_event_type = FALSE;

-- QC07 — Eventos con campaign_id o customer_id inexistente (huérfanos).
CREATE OR REPLACE VIEW qc07_event_orphans AS
SELECT event_id, campaign_id, customer_id, campaign_exists, customer_exists
FROM fact_campaign_event
WHERE campaign_exists = FALSE
   OR (customer_id IS NOT NULL AND customer_exists = FALSE);

-- QC08 — Campañas con rango de fechas inválido (end_date < start_date).
CREATE OR REPLACE VIEW qc08_campaign_bad_dates AS
SELECT campaign_id, start_date, end_date
FROM stg_campaigns
WHERE is_valid_date_range = FALSE;

-- QC09 — Estados de transacción no reconocidos tras normalizar.
CREATE OR REPLACE VIEW qc09_unknown_txn_status AS
SELECT transaction_id, transaction_status
FROM fact_transaction
WHERE transaction_status = 'unknown';
