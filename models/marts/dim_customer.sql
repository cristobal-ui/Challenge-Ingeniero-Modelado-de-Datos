-- =====================================================================
-- dim_customer
-- Grano: 1 fila por cliente (customer_id = clave primaria).
-- Dimensión de consumo self-service: atributos descriptivos + algunos
-- derivados útiles (edad, tenencia) ya calculados para no repetir lógica.
-- =====================================================================
CREATE OR REPLACE TABLE dim_customer AS
SELECT
    c.customer_id,
    c.customer_status,
    c.risk_segment,
    c.income_range,
    c.gender,
    c.region,
    c.city,
    c.created_at                                        AS customer_created_at,
    c.birth_date,
    -- Edad en años a la fecha de referencia del análisis.
    CASE WHEN c.birth_date IS NOT NULL
         THEN DATE_DIFF('year', c.birth_date, CURRENT_DATE)
         END                                            AS age_years,
    -- Conteo de tarjetas asociadas (denormalizado para análisis rápido).
    COUNT(DISTINCT cr.card_id)                          AS num_cards,
    c.is_future_created
FROM stg_customers c
LEFT JOIN stg_cards cr
    ON cr.customer_id = c.customer_id
GROUP BY
    c.customer_id, c.customer_status, c.risk_segment, c.income_range,
    c.gender, c.region, c.city, c.created_at, c.birth_date, c.is_future_created;
