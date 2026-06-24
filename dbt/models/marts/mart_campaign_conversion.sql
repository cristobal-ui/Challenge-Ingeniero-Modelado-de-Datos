-- Grano: 1 fila por (campaign_id, customer_id) para clientes IMPACTADOS.
-- Tabla de consumo principal: impacto, interacción y conversión en un lugar.
with camp as (
    select campaign_id, campaign_name, start_date, end_date, target_product
    from {{ ref('stg_campaigns') }}
    where is_valid_date_range
),
events_agg as (
    select
        campaign_id,
        customer_id,
        bool_or(event_type = 'sent')                            as is_impacted,
        bool_or(event_type = 'opened')                          as has_opened,
        bool_or(event_type = 'clicked')                         as has_clicked,
        min(case when event_type = 'sent' then event_date end)  as first_sent_at
    from {{ ref('fact_campaign_event') }}
    where customer_exists and campaign_exists
    group by campaign_id, customer_id
),
impacted as (
    select
        e.campaign_id, e.customer_id, e.has_opened, e.has_clicked, e.first_sent_at,
        c.campaign_name, c.start_date, c.end_date
    from events_agg e
    join camp c using (campaign_id)
    where e.is_impacted
),
conv_txn as (
    select
        i.campaign_id,
        i.customer_id,
        count(*)            as num_valid_3cuota_txn,
        sum(t.amount)       as amount_3cuota_clp
    from impacted i
    join {{ ref('fact_transaction') }} t
        on t.customer_id = i.customer_id
       and t.is_valid_transaction
       and t.is_3_installments
       and t.transaction_day between i.start_date and i.end_date
    group by i.campaign_id, i.customer_id
)
select
    i.campaign_id,
    i.campaign_name,
    i.customer_id,
    i.start_date,
    i.end_date,
    i.first_sent_at,
    true                                            as is_impacted,
    coalesce(i.has_opened, false)                   as has_opened,
    coalesce(i.has_clicked, false)                  as has_clicked,
    coalesce(i.has_opened or i.has_clicked, false)  as has_interacted,
    (ct.customer_id is not null)                    as is_converted,
    coalesce(ct.num_valid_3cuota_txn, 0)            as num_valid_3cuota_txn,
    coalesce(ct.amount_3cuota_clp, 0)               as amount_3cuota_clp
from impacted i
left join conv_txn ct
    on  ct.campaign_id = i.campaign_id
    and ct.customer_id = i.customer_id
