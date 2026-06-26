{#-
  Macros cross-database.

  El MISMO modelo corre en DuckDB (local / CI) y en BigQuery (producción) sin
  reescribir SQL: cada macro emite el dialecto correcto según `target.type`.
  En DuckDB el SQL renderizado es IDÉNTICO al original (try_cast / bool_or /
  date_diff), por lo que el comportamiento local no cambia. La rama BigQuery
  solo se activa al correr con `--target bq`.

  Equivalencias cubiertas (ver docs/bigquery_migration.md):
    try_cast(...)            -> safe_cast(...)
    decimal(18,2) / integer  -> numeric / int64
    bool_or(...)            -> logical_or(...)
    date_diff('year', a, b)  -> date_diff(b, a, year)
-#}

{# Mapea un nombre de tipo "canónico" al tipo nativo del adaptador. #}
{% macro csi_type(type) -%}
    {%- if target.type == 'bigquery' -%}
        {%- if type == 'numeric' -%}numeric
        {%- elif type == 'integer' -%}int64
        {%- else -%}{{ type }}{%- endif -%}
    {%- else -%}
        {%- if type == 'numeric' -%}decimal(18, 2)
        {%- else -%}{{ type }}{%- endif -%}
    {%- endif -%}
{%- endmacro %}

{# Cast tolerante a errores (NULL si falla). Tipos canónicos:
   'timestamp', 'date', 'integer', 'numeric'. #}
{% macro csi_safe_cast(field, type) -%}
    {%- set resolved = csi_type(type) -%}
    {%- if target.type == 'bigquery' -%}
        safe_cast({{ field }} as {{ resolved }})
    {%- else -%}
        try_cast({{ field }} as {{ resolved }})
    {%- endif -%}
{%- endmacro %}

{# Agregación booleana OR sobre una condición. #}
{% macro csi_bool_or(expression) -%}
    {%- if target.type == 'bigquery' -%}
        logical_or({{ expression }})
    {%- else -%}
        bool_or({{ expression }})
    {%- endif -%}
{%- endmacro %}

{# Diferencia en años completos entre dos fechas (start -> end). #}
{% macro csi_year_diff(start_date, end_date) -%}
    {%- if target.type == 'bigquery' -%}
        date_diff({{ end_date }}, {{ start_date }}, year)
    {%- else -%}
        date_diff('year', {{ start_date }}, {{ end_date }})
    {%- endif -%}
{%- endmacro %}
