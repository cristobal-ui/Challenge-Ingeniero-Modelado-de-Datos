-- Test singular: la clave compuesta (campaign_id, customer_id) del mart es única.
-- Devuelve filas que violan la regla; 0 filas => OK.
select
    campaign_id,
    customer_id,
    count(*) as n
from {{ ref('mart_campaign_conversion') }}
group by campaign_id, customer_id
having count(*) > 1
