-- =====================================================================
-- analysis_config
-- Parámetros del análisis en UN solo lugar (evita hardcodear el id de la
-- campaña en cada consulta). Cambiar aquí la campaña objetivo reapunta
-- todas las consultas de negocio.
--   - target_campaign_id : campaña a reportar (principal del challenge).
--   - attribution_post_days : ventana de atribución posterior (0 = solo
--     durante la vigencia; el diccionario sugiere 21 como alternativa).
-- En BigQuery sería una tabla de configuración o variables del proyecto.
-- =====================================================================
CREATE OR REPLACE VIEW analysis_config AS
SELECT
    'CMP2026053CSI' AS target_campaign_id,
    0               AS attribution_post_days;
