-- Grano: 1 fila por customer_id. Tipa fechas, normaliza dominios, deduplica
-- y descarta filas sin clave (no identificables).
with src as (
    select
        trim(customer_id)                       as customer_id,
        try_cast(created_at as timestamp)       as created_at,
        try_cast(birth_date as date)            as birth_date,
        upper(trim(gender))                     as gender,
        trim(region)                            as region,
        trim(city)                              as city,
        lower(trim(customer_status))            as customer_status,
        lower(trim(risk_segment))               as risk_segment,
        trim(income_range)                      as income_range
    from {{ source('raw', 'raw_customers') }}
    where customer_id is not null and trim(customer_id) <> ''
)
select
    customer_id,
    created_at,
    birth_date,
    case when gender in ('M','F') then gender else 'U' end                 as gender,
    region,
    city,
    case when customer_status in ('active','inactive','blocked')
         then customer_status else 'unknown' end                          as customer_status,
    case when risk_segment in ('low','medium','high')
         then risk_segment else 'unknown' end                             as risk_segment,
    coalesce(nullif(income_range,''), 'unknown')                          as income_range,
    (created_at > current_timestamp)                                      as is_future_created
from src
qualify row_number() over (
    partition by customer_id order by created_at desc nulls last
) = 1
