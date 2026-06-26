-- Grano: 1 fila por campaign_id. Tipa fechas y marca rango inválido.
with src as (
    select
        trim(campaign_id)                   as campaign_id,
        trim(campaign_name)                 as campaign_name,
        {{ csi_safe_cast('start_date', 'date') }}   as start_date,
        {{ csi_safe_cast('end_date', 'date') }}     as end_date,
        lower(trim(campaign_type))          as campaign_type,
        lower(trim(target_product))         as target_product
    from {{ source('raw', 'raw_campaigns') }}
    where campaign_id is not null and trim(campaign_id) <> ''
)
select
    campaign_id,
    campaign_name,
    start_date,
    end_date,
    campaign_type,
    target_product,
    (start_date is not null and end_date is not null and end_date >= start_date)
        as is_valid_date_range
from src
qualify row_number() over (
    partition by campaign_id order by start_date
) = 1
