-- Grano: 1 fila por transaction_id. Tipa fecha y monto, normaliza estado/tipo,
-- deduplica y materializa la definición ÚNICA de "transacción válida".
with src as (
    select
        trim(transaction_id)                        as transaction_id,
        trim(customer_id)                           as customer_id,
        trim(card_id)                               as card_id,
        trim(merchant_id)                           as merchant_id,
        {{ csi_safe_cast('transaction_date', 'timestamp') }}   as transaction_date,
        {{ csi_safe_cast('amount', 'numeric') }}           as amount,
        upper(trim(currency))                       as currency,
        {{ csi_safe_cast('installments', 'integer') }}     as installments,
        lower(trim(transaction_status))             as transaction_status,
        lower(trim(transaction_type))               as transaction_type
    from {{ source('raw', 'raw_transactions') }}
    where transaction_id is not null and trim(transaction_id) <> ''
),
typed as (
    select
        transaction_id,
        nullif(customer_id, '')                     as customer_id,
        nullif(card_id, '')                         as card_id,
        nullif(merchant_id, '')                     as merchant_id,
        transaction_date,
        amount,
        coalesce(nullif(currency,''), 'CLP')        as currency,
        installments,
        case when transaction_status in ('approved','pending','rejected','reversed')
             then transaction_status else 'unknown' end as transaction_status,
        case when transaction_type in ('purchase','refund','withdrawal')
             then transaction_type else 'unknown' end   as transaction_type,
        (amount is null or amount <= 0)             as is_invalid_amount,
        (transaction_date is null or transaction_date > current_timestamp) as is_invalid_date,
        (installments = 3)                          as is_3_installments
    from src
)
select
    *,
    (transaction_status = 'approved'
        and transaction_type = 'purchase'
        and not is_invalid_amount
        and not is_invalid_date)                    as is_valid_transaction
from typed
qualify row_number() over (
    partition by transaction_id order by transaction_date desc nulls last
) = 1
