# Data Dictionary — Challenge Ingeniero/a de Modelado de Datos Senior

## raw_customers
Cliente registrado en la fintech/neobank.

- customer_id: identificador del cliente.
- created_at: fecha/hora de creación del cliente.
- birth_date: fecha de nacimiento.
- gender: género declarado.
- region: región.
- city: ciudad.
- customer_status: estado del cliente.
- risk_segment: segmento de riesgo.
- income_range: rango de ingreso estimado.

## raw_accounts
Cuentas o productos financieros asociados a clientes.

- account_id: identificador de cuenta.
- customer_id: cliente propietario.
- account_type: tipo de cuenta.
- created_at: fecha/hora de creación.
- status: estado de la cuenta.

## raw_cards
Tarjetas asociadas a clientes y cuentas.

- card_id: identificador de tarjeta.
- customer_id: cliente propietario.
- account_id: cuenta asociada.
- card_type: tipo de tarjeta.
- created_at: fecha/hora de creación.
- status: estado de la tarjeta.

## raw_transactions
Transacciones realizadas con tarjeta.

- transaction_id: identificador de transacción.
- customer_id: cliente asociado.
- card_id: tarjeta utilizada.
- merchant_id: comercio.
- transaction_date: fecha/hora de transacción.
- amount: monto en pesos chilenos.
- currency: moneda.
- installments: número de cuotas.
- transaction_status: estado de transacción.
- transaction_type: tipo de transacción.

## raw_merchants
Comercios donde ocurren transacciones.

- merchant_id: identificador del comercio.
- merchant_name: nombre del comercio.
- merchant_category: categoría.
- region: región.
- city: ciudad.

## raw_campaigns
Campañas comerciales.

- campaign_id: identificador de campaña.
- campaign_name: nombre.
- start_date: fecha de inicio.
- end_date: fecha de término.
- campaign_type: tipo de campaña.
- target_product: producto objetivo.

## raw_campaign_events
Eventos de interacción de clientes con campañas.

- event_id: identificador de evento.
- campaign_id: campaña asociada.
- customer_id: cliente asociado.
- event_date: fecha/hora de evento.
- event_type: tipo de evento: sent, opened, clicked.
- channel: canal de contacto.

## Reglas sugeridas de negocio

- Cliente impactado: cliente con al menos un evento `sent` para una campaña.
- Cliente que abrió: cliente con al menos un evento `opened`.
- Cliente que hizo clic: cliente con al menos un evento `clicked`.
- Transacción válida: transaction_status normalizado = approved y transaction_type = purchase.
- Conversión campaña 3CSI: cliente impactado que realiza al menos una transacción válida en 3 cuotas durante la vigencia de la campaña.
- Ventana pre campaña: 21 días antes del start_date.
- Ventana durante campaña: desde start_date hasta end_date inclusive.
- Ventana post campaña: 21 días después del end_date.

## Errores controlados incluidos

El dataset incluye intencionalmente algunos problemas para evaluar calidad de datos:

- Clientes duplicados.
- Cliente sin customer_id.
- Cliente con fecha futura.
- Cuenta con customer_id inexistente.
- Tarjeta con account_id inexistente.
- Comercio duplicado.
- Campaña con fechas inválidas.
- Eventos duplicados.
- Eventos con campaign_id o customer_id inexistentes.
- Evento con event_type inválido.
- Transacciones duplicadas.
- Transacciones con customer_id, card_id o merchant_id inexistentes.
- Transacción con monto negativo.
- Transacción con fecha futura.

El candidato debe detectar, documentar y tratar estos problemas según su criterio.
