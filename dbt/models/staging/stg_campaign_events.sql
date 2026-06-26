-- Grano: 1 fila por event_id. Tipa fecha, normaliza tipo/canal, deduplica
-- y marca event_type no reconocido (p.ej. 'bounce').
with src as (
    select
        trim(event_id)                      as event_id,
        trim(campaign_id)                   as campaign_id,
        trim(customer_id)                   as customer_id,
        {{ csi_safe_cast('event_date', 'timestamp') }}   as event_date,
        lower(trim(event_type))             as event_type,
        lower(trim(channel))                as channel
    from {{ source('raw', 'raw_campaign_events') }}
    where event_id is not null and trim(event_id) <> ''
)
select
    event_id,
    nullif(campaign_id, '')                             as campaign_id,
    nullif(customer_id, '')                             as customer_id,
    event_date,
    event_type,
    channel,
    (event_type in ('sent','opened','clicked'))         as is_valid_event_type
from src
qualify row_number() over (
    partition by event_id order by event_date desc nulls last
) = 1
