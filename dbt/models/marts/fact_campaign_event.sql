-- Grano: 1 fila por evento (event_id = PK). Hecho de interacción conformado.
select
    e.event_id,
    e.campaign_id,
    e.customer_id,
    e.event_date,
    cast(e.event_date as date)              as event_day,
    e.event_type,
    e.channel,
    e.is_valid_event_type,
    (cmp.campaign_id is not null)           as campaign_exists,
    (dc.customer_id is not null)            as customer_exists,
    (cmp.start_date is not null
        and cast(e.event_date as date) between cmp.start_date and cmp.end_date)
                                            as in_campaign_window
from {{ ref('stg_campaign_events') }} e
left join {{ ref('stg_campaigns') }} cmp on cmp.campaign_id = e.campaign_id
left join {{ ref('dim_customer') }}  dc  on dc.customer_id  = e.customer_id
