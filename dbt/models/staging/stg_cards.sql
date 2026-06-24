-- Grano: 1 fila por card_id. Tipa fecha, normaliza estado, deduplica.
with src as (
    select
        trim(card_id)                       as card_id,
        trim(customer_id)                   as customer_id,
        trim(account_id)                    as account_id,
        lower(trim(card_type))              as card_type,
        try_cast(created_at as timestamp)   as created_at,
        lower(trim(status))                 as status
    from {{ source('raw', 'raw_cards') }}
    where card_id is not null and trim(card_id) <> ''
)
select
    card_id,
    nullif(customer_id, '')                 as customer_id,
    nullif(account_id, '')                  as account_id,
    card_type,
    created_at,
    case when status in ('active','inactive','blocked','expired')
         then status else 'unknown' end     as status
from src
qualify row_number() over (
    partition by card_id order by created_at desc nulls last
) = 1
