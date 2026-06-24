# Dataset — Challenge Ingeniero/a de Modelado de Datos Senior

Este paquete contiene datos sintéticos para resolver el challenge de modelado de datos senior.

## Archivos incluidos

- raw_customers.csv
- raw_accounts.csv
- raw_cards.csv
- raw_transactions.csv
- raw_merchants.csv
- raw_campaigns.csv
- raw_campaign_events.csv
- DATA_DICTIONARY.md

## Caso principal

La campaña principal es:

- campaign_id: CMP2026053CSI
- campaign_name: 3 cuotas sin interes mayo 2026
- start_date: 2026-05-05
- end_date: 2026-05-25
- target_product: credit_card

El objetivo es construir una capa analítica que permita medir impacto, interacción, conversión y comportamiento transaccional asociado a esta campaña.

## Consideraciones

No es necesario usar GCP real. El dataset puede ejecutarse localmente con dbt Core + DuckDB/Postgres/SQLite, Dataform o SQL organizado por capas. La solución debe documentar cómo se llevaría a BigQuery en producción.

## Tamaño aproximado

- Clientes: ~500
- Cuentas: ~590
- Tarjetas: ~520
- Comercios: ~200
- Campañas: 3
- Eventos de campaña: ~750
- Transacciones: ~8.600

## Nota

Los datos contienen errores controlados para evaluar capacidades de calidad, gobernanza y trazabilidad.
