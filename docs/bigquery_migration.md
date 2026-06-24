# Migración a BigQuery — cambios exactos

La solución corre en **DuckDB** localmente. La lógica de modelado (capas,
granos, joins, reglas de negocio) es idéntica en BigQuery; lo único que cambia
es el **dialecto** y la **capa de materialización/carga**. Abajo, el detalle
concreto de qué reemplazar.

## 1. Sustituciones de dialecto SQL

| Uso en DuckDB (este repo) | Equivalente en BigQuery | Dónde aparece |
|---|---|---|
| `TRY_CAST(x AS TIMESTAMP)` | `SAFE_CAST(x AS TIMESTAMP)` | todo `staging` |
| `TRY_CAST(x AS DATE)` | `SAFE_CAST(x AS DATE)` | `stg_customers`, `stg_campaigns` |
| `TRY_CAST(x AS DECIMAL(18,2))` | `SAFE_CAST(x AS NUMERIC)` | `stg_transactions` |
| `DATE_DIFF('year', a, b)` (orden: unidad, inicio, fin) | `DATE_DIFF(b, a, YEAR)` (orden: fin, inicio, unidad) | `dim_customer.age_years` |
| `read_csv(..., all_varchar=true)` | `bq load` / external table sobre GCS (no es SQL) | `00_sources/raw_sources.sql` |
| `CAST(ts AS DATE)` | igual (`DATE(ts)` también válido) | `fact_*` |
| `QUALIFY ROW_NUMBER() OVER (...)` | **igual** (BigQuery soporta `QUALIFY`) | dedup en `staging` |
| `BOOL_OR(cond)` | `LOGICAL_OR(cond)` | `mart_campaign_conversion` |
| `CURRENT_TIMESTAMP` / `CURRENT_DATE` | iguales | banderas de fecha futura |

> El resto (CTEs, `LEFT JOIN`, `BETWEEN`, `SUM/COUNT`, `USING`, `NULLIF`,
> `COALESCE`) es ANSI y no cambia.

## 2. Capa de carga (sources)

- En local: `read_csv(...)` materializa los CSV como tablas.
- En BigQuery: las tablas `raw_*` se cargan con `bq load` (o son external
  tables sobre archivos en GCS) con esquema declarado. El archivo
  `00_sources/raw_sources.sql` **no se ejecuta** en BQ; se reemplaza por la
  ingesta.

## 3. Materialización y costo

- `fact_transaction`: **PARTITION BY** `transaction_day` y **CLUSTER BY**
  `customer_id, merchant_id`. Las consultas por rango de fechas (toda la
  ventana de campaña) escanean solo las particiones necesarias → menos costo.
- `fact_campaign_event`: particionar por `event_day`.
- `staging`: dejar como vistas (o tablas si el volumen lo amerita).

```sql
-- Ejemplo de DDL equivalente en BigQuery para el hecho principal
CREATE OR REPLACE TABLE marts.fact_transaction
PARTITION BY transaction_day
CLUSTER BY customer_id, merchant_id AS
SELECT ... ;  -- mismo SELECT que models/marts/fact_transaction.sql
```

## 4. Orquestación recomendada

- Empaquetar las capas como modelos **dbt** (o **Dataform**): `sources`,
  `staging`, `marts`; los controles de `quality/` pasan a `tests`/`assertions`
  declarativos; `ref()`/`source()` generan el DAG y el linaje.
- `analysis_config` (la campaña objetivo y la ventana de atribución) pasa a
  ser una **variable** de dbt/Dataform o una tabla de configuración.
- Tests en CI y chequeo de *freshness* de las fuentes antes de publicar marts.
