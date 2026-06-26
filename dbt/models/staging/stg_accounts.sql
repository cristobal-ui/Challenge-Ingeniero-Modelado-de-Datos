-- Grano: 1 fila por account_id. Tipa fecha, normaliza estado, deduplica.
with src as (
    select
        trim(account_id)                    as account_id,
        trim(customer_id)                   as customer_id,
        lower(trim(account_type))           as account_type,
        {{ csi_safe_cast('created_at', 'timestamp') }}   as created_at,
        lower(trim(status))                 as status
    from {{ source('raw', 'raw_accounts') }}
    where account_id is not null and trim(account_id) <> ''
)
select
    account_id,
    nullif(customer_id, '')                 as customer_id,
    account_type,
    created_at,
    case when status in ('active','inactive','blocked','closed')
         then status else 'unknown' end     as status
from src
qualify row_number() over (
    partition by account_id order by created_at desc nulls last
) = 1
