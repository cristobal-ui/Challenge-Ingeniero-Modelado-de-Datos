# Migración a BigQuery — cambios exactos

La solución corre en **DuckDB** localmente. La lógica de modelado (capas,
granos, joins, reglas de negocio) es idéntica en BigQuery; lo único que cambia
es el **dialecto** y la **capa de materialización/carga**.

## 1. Sustituciones de dialecto SQL — ya automatizadas por macros

El SQL es **portable**: las funciones que difieren entre DuckDB y BigQuery están
encapsuladas en macros (`dbt/macros/cross_db.sql`) que emiten el dialecto correcto
según `target.type`. **El mismo modelo corre en ambos** sin reescribir SQL:

```bash
dbt build --profiles-dir .                 # target duckdb (local) -> try_cast, bool_or, ...
dbt build --profiles-dir . --target bq     # target bigquery       -> safe_cast, logical_or, ...
```

Qué resuelve cada macro:

| Macro | DuckDB emite | BigQuery emite | Dónde se usa |
|---|---|---|---|
| `csi_safe_cast(x, 'timestamp'/'date')` | `TRY_CAST(x AS TIMESTAMP/DATE)` | `SAFE_CAST(x AS TIMESTAMP/DATE)` | todo `staging` |
| `csi_safe_cast(x, 'numeric')` | `TRY_CAST(x AS DECIMAL(18,2))` | `SAFE_CAST(x AS NUMERIC)` | `stg_transactions` |
| `csi_safe_cast(x, 'integer')` | `TRY_CAST(x AS INTEGER)` | `SAFE_CAST(x AS INT64)` | `stg_transactions` |
| `csi_bool_or(cond)` | `BOOL_OR(cond)` | `LOGICAL_OR(cond)` | `mart_campaign_conversion` |
| `csi_year_diff(a, b)` | `DATE_DIFF('year', a, b)` | `DATE_DIFF(b, a, YEAR)` | `dim_customer.age_years` |

Lo que **ya es idéntico** en ambos motores y no necesita macro: `QUALIFY ROW_NUMBER()`,
`CAST(ts AS DATE)`, `CURRENT_TIMESTAMP` / `CURRENT_DATE`, y todo lo ANSI (CTEs,
`LEFT JOIN`, `BETWEEN`, `SUM/COUNT`, `USING`, `NULLIF`, `COALESCE`).

> Única pieza que sigue siendo específica del adaptador: la **carga de sources**
> (`read_csv(...)` en DuckDB) → ver §2. Es la capa de ingesta, no de transformación.

## 2. Capa de carga (sources)

- En local: el source de dbt (`models/staging/_staging__sources.yml`) lee los
  CSV con `read_csv(..., all_varchar=true)` vía `external_location` de dbt-duckdb.
- En BigQuery: las tablas `raw_*` se cargan con `bq load` (o son external
  tables sobre archivos en GCS) con esquema declarado. Se elimina el
  `external_location` del source y `{{ source('raw', ...) }}` apunta a la tabla
  nativa. El staging (transformación) no cambia.

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

## 4. Orquestación (ya implementada con dbt)

- Las capas ya son modelos **dbt**: `sources`, `staging`, `marts`, con
  `ref()`/`source()` generando el DAG y el linaje. En BigQuery basta cambiar el
  `target` del perfil; los modelos no se tocan (ver §1).
- Los controles de calidad ya son **tests declarativos** (`unique`, `not_null`,
  `accepted_values`, `relationships`) — portables a BigQuery sin cambios.
- La campaña objetivo ya es una **variable** de dbt (`vars.target_campaign_id`),
  no está hardcodeada.
- Pendiente para producción: añadir chequeo de *freshness* de las fuentes antes
  de publicar a los marts, y materializar los hechos con partición/clustering (§3).
