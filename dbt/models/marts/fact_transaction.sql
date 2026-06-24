-- Grano: 1 fila por transacción (transaction_id = PK). Hecho conformado.
-- Conserva todas las filas identificables; integridad referencial como banderas.
select
    t.transaction_id,
    t.customer_id,
    t.card_id,
    t.merchant_id,
    t.transaction_date,
    cast(t.transaction_date as date)                    as transaction_day,
    t.amount,
    t.currency,
    t.installments,
    t.transaction_status,
    t.transaction_type,
    t.is_3_installments,
    t.is_valid_transaction,
    t.is_invalid_amount,
    t.is_invalid_date,
    (dc.customer_id is not null)                        as customer_exists,
    (dm.merchant_id is not null)                        as merchant_exists,
    (sc.card_id is not null)                            as card_exists
from {{ ref('stg_transactions') }} t
left join {{ ref('dim_customer') }} dc on dc.customer_id = t.customer_id
left join {{ ref('dim_merchant') }} dm on dm.merchant_id = t.merchant_id
left join {{ ref('stg_cards') }}    sc on sc.card_id     = t.card_id
