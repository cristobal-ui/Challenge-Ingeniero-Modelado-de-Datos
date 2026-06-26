-- Grano: 1 fila por cliente (customer_id = PK). Dimensión de consumo.
select
    c.customer_id,
    c.customer_status,
    c.risk_segment,
    c.income_range,
    c.gender,
    c.region,
    c.city,
    c.created_at                                        as customer_created_at,
    c.birth_date,
    case when c.birth_date is not null
         then {{ csi_year_diff('c.birth_date', 'current_date') }} end as age_years,
    count(distinct cr.card_id)                          as num_cards,
    c.is_future_created
from {{ ref('stg_customers') }} c
left join {{ ref('stg_cards') }} cr
    on cr.customer_id = c.customer_id
group by
    c.customer_id, c.customer_status, c.risk_segment, c.income_range,
    c.gender, c.region, c.city, c.created_at, c.birth_date, c.is_future_created
