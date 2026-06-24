# Proyecto dbt — Campaña 3CSI (dbt-duckdb)

Implementación en **dbt Core + DuckDB** de la misma capa analítica que la
solución SQL por capas de la raíz del repo. Mismo modelo, orquestado con dbt:
`sources`, `ref()`, materializaciones, documentación y tests declarativos.

## Cómo correr

```bash
pip install dbt-duckdb
cd dbt
dbt build --profiles-dir .          # construye modelos + corre todos los tests
dbt docs generate --profiles-dir .  # (opcional) documentación y linaje
```

> `profiles.yml` está incluido en esta carpeta; por eso se pasa `--profiles-dir .`
> En lugar de las habituales `~/.dbt/profiles.yml`.

## Qué hay

- **Sources** (`models/staging/_staging__sources.yml`): los CSV de `../data/`
  leídos como *external sources* en texto (`all_varchar`), igual que la versión
  SQL pura (el tipado ocurre en staging).
- **Staging** (vistas): `stg_*` — limpieza, tipado, normalización, dedup.
- **Marts** (tablas): `dim_customer`, `dim_merchant`, `fact_transaction`,
  `fact_campaign_event`, `mart_campaign_conversion`.
- **Tests declarativos**: `unique`/`not_null` en PKs, `accepted_values` en
  estados normalizados, `relationships` (FK) con `severity: warn` para exponer
  los huérfanos controlados, y un test singular de unicidad compuesta del mart.
- **Analyses** (`analyses/business_queries.sql`): consultas de negocio
  parametrizadas con `{{ var('target_campaign_id') }}`.

## Resultado esperado

```
Done. PASS=40 WARN=3 ERROR=0
```

Los **3 WARN** son las claves huérfanas inyectadas a propósito en el dataset
(1 transacción con cliente inexistente, 1 con comercio inexistente, 1 evento con
campaña inexistente). Están configuradas como `warn`, no `error`: el modelo las
**detecta y reporta** sin romper el build, que es el comportamiento deseado para
errores de datos conocidos.

## Parametrizar la campaña

```bash
dbt build --profiles-dir . --vars 'target_campaign_id: CMP202604CASHBACK'
```
