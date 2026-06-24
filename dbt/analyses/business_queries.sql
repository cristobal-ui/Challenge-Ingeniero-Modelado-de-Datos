-- Consultas de negocio sobre el modelo final (campaña parametrizada con var).
-- Compilar con: dbt compile --select business_queries  (no materializan).
-- Campaña objetivo = {{ var('target_campaign_id') }}

-- Q1 — Impactados / interactuaron / convirtieron + tasa de conversión.
select
    count(*)                                              as clientes_impactados,
    sum(case when has_interacted then 1 else 0 end)       as clientes_interactuaron,
    sum(case when is_converted   then 1 else 0 end)       as clientes_convertidos,
    round(100.0 * sum(case when is_converted then 1 else 0 end) / count(*), 2)
                                                          as tasa_conversion_pct
from {{ ref('mart_campaign_conversion') }}
where campaign_id = '{{ var("target_campaign_id") }}';

-- Q2 — Tasa de conversión por segmento de riesgo.
select
    dc.risk_segment,
    count(*)                                              as impactados,
    sum(case when m.is_converted then 1 else 0 end)       as convertidos,
    round(100.0 * sum(case when m.is_converted then 1 else 0 end) / count(*), 2)
                                                          as tasa_conversion_pct
from {{ ref('mart_campaign_conversion') }} m
join {{ ref('dim_customer') }} dc using (customer_id)
where m.campaign_id = '{{ var("target_campaign_id") }}'
group by dc.risk_segment
order by tasa_conversion_pct desc;

-- Q3 — Comercios con mayor monto en 3 cuotas durante la campaña.
select
    dm.merchant_id,
    dm.merchant_name,
    dm.merchant_category,
    count(*)                                              as num_txn_3cuotas,
    sum(t.amount)                                         as monto_total_3cuotas_clp,
    round(avg(t.amount), 0)                               as ticket_promedio_clp
from {{ ref('mart_campaign_conversion') }} m
join {{ ref('stg_campaigns') }} c on c.campaign_id = m.campaign_id
join {{ ref('fact_transaction') }} t
    on  t.customer_id = m.customer_id
    and t.is_valid_transaction
    and t.is_3_installments
    and t.transaction_day between c.start_date and c.end_date
join {{ ref('dim_merchant') }} dm on dm.merchant_id = t.merchant_id
where m.campaign_id = '{{ var("target_campaign_id") }}'
group by dm.merchant_id, dm.merchant_name, dm.merchant_category
order by monto_total_3cuotas_clp desc
limit 10;

-- Q4 — Ticket promedio y monto total de clientes convertidos.
select
    count(*)                                              as clientes_convertidos,
    sum(num_valid_3cuota_txn)                             as total_txn_3cuotas,
    sum(amount_3cuota_clp)                                as monto_total_3cuotas_clp,
    round(sum(amount_3cuota_clp) / nullif(sum(num_valid_3cuota_txn),0), 0)
                                                          as ticket_promedio_clp
from {{ ref('mart_campaign_conversion') }}
where campaign_id = '{{ var("target_campaign_id") }}'
  and is_converted;
