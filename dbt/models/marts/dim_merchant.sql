-- Grano: 1 fila por comercio (merchant_id = PK).
select
    merchant_id,
    merchant_name,
    merchant_category,
    region,
    city
from {{ ref('stg_merchants') }}
