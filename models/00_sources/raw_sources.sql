-- =====================================================================
-- CAPA SOURCES (solo ejecución local con DuckDB)
-- ---------------------------------------------------------------------
-- En BigQuery estas tablas NO se crean aquí: serían tablas nativas
-- cargadas vía `bq load` / external tables sobre GCS. Este archivo solo
-- existe para que la solución sea ejecutable localmente sobre los CSV.
--
-- Se cargan TODO como texto (VARCHAR) para reproducir el contrato real:
-- el casting y la limpieza ocurren recién en la capa staging, nunca antes.
-- Esto evita que el lector de CSV "arregle" silenciosamente datos sucios
-- (fechas inválidas, montos negativos) y nos oculte problemas de calidad.
-- =====================================================================

CREATE OR REPLACE TABLE raw_customers AS
SELECT * FROM read_csv('data/raw_customers.csv', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_accounts AS
SELECT * FROM read_csv('data/raw_accounts.csv', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_cards AS
SELECT * FROM read_csv('data/raw_cards.csv', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_merchants AS
SELECT * FROM read_csv('data/raw_merchants.csv', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_campaigns AS
SELECT * FROM read_csv('data/raw_campaigns.csv', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_campaign_events AS
SELECT * FROM read_csv('data/raw_campaign_events.csv', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_transactions AS
SELECT * FROM read_csv('data/raw_transactions.csv', header=true, all_varchar=true);
