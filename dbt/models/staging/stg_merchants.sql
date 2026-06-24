-- Grano: 1 fila por merchant_id. Normaliza texto/categoría y deduplica.
with src as (
    select
        trim(merchant_id)                   as merchant_id,
        trim(merchant_name)                 as merchant_name,
        lower(trim(merchant_category))      as merchant_category,
        trim(region)                        as region,
        trim(city)                          as city
    from {{ source('raw', 'raw_merchants') }}
    where merchant_id is not null and trim(merchant_id) <> ''
)
select
    merchant_id,
    coalesce(nullif(merchant_name,''), 'unknown')       as merchant_name,
    coalesce(nullif(merchant_category,''), 'unknown')   as merchant_category,
    region,
    city
from src
qualify row_number() over (
    partition by merchant_id order by merchant_name
) = 1
