#!/usr/bin/env python3
"""
Runner local de la capa analítica (DuckDB).

Construye todo el modelo a partir de los CSV crudos, ejecuta los controles
de calidad y opcionalmente las consultas de negocio. No requiere GCP.

Uso:
    python run_local.py            # build + reporte de calidad
    python run_local.py --queries  # además imprime las consultas de negocio

La base se persiste en challenge.duckdb para inspección con cualquier
cliente DuckDB.
"""
import os
import sys
import duckdb

ROOT = os.path.dirname(os.path.abspath(__file__))
os.chdir(ROOT)  # para que las rutas 'data/...' resuelvan

# Orden de ejecución = orden de dependencias del DAG.
BUILD_ORDER = [
    "models/00_sources/raw_sources.sql",
    "models/staging/stg_customers.sql",
    "models/staging/stg_accounts.sql",
    "models/staging/stg_cards.sql",
    "models/staging/stg_merchants.sql",
    "models/staging/stg_campaigns.sql",
    "models/staging/stg_campaign_events.sql",
    "models/staging/stg_transactions.sql",
    "models/marts/dim_customer.sql",
    "models/marts/dim_merchant.sql",
    "models/marts/fact_transaction.sql",
    "models/marts/fact_campaign_event.sql",
    "models/marts/mart_campaign_conversion.sql",
    "quality/quality_checks.sql",
]

QC_VIEWS = [
    ("QC01", "qc01_pk_customer",        "PK duplicada en dim_customer"),
    ("QC02", "qc02_pk_transaction",     "PK duplicada en fact_transaction"),
    ("QC03", "qc03_txn_customer_fk",    "Txn con customer_id inexistente"),
    ("QC04", "qc04_negative_amounts",   "Compras aprobadas con monto <= 0"),
    ("QC05", "qc05_invalid_dates",      "Txn con fecha futura/invalida"),
    ("QC06", "qc06_unknown_event_type", "Eventos con event_type no reconocido"),
    ("QC07", "qc07_event_orphans",      "Eventos huerfanos (campaign/customer)"),
    ("QC08", "qc08_campaign_bad_dates", "Campanas con rango de fechas invalido"),
    ("QC09", "qc09_unknown_txn_status", "Estados de transaccion no reconocidos"),
]

MODELS = [
    "stg_customers", "stg_accounts", "stg_cards", "stg_merchants",
    "stg_campaigns", "stg_campaign_events", "stg_transactions",
    "dim_customer", "dim_merchant", "fact_transaction",
    "fact_campaign_event", "mart_campaign_conversion",
]


def run_sql_file(con, path):
    with open(path, "r", encoding="utf-8") as fh:
        con.execute(fh.read())


def main():
    db_path = os.path.join(ROOT, "challenge.duckdb")
    if os.path.exists(db_path):
        os.remove(db_path)
    con = duckdb.connect(db_path)

    print("=" * 64)
    print("BUILD — construyendo capa analitica desde CSV crudos")
    print("=" * 64)
    for path in BUILD_ORDER:
        run_sql_file(con, path)
        print(f"  ok  {path}")

    print("\n" + "=" * 64)
    print("ROW COUNTS por modelo")
    print("=" * 64)
    for m in MODELS:
        n = con.execute(f"SELECT COUNT(*) FROM {m}").fetchone()[0]
        print(f"  {m:<28} {n:>8,}")

    print("\n" + "=" * 64)
    print("CONTROLES DE CALIDAD (violaciones encontradas)")
    print("=" * 64)
    total_fail = 0
    for code, view, desc in QC_VIEWS:
        n = con.execute(f"SELECT COUNT(*) FROM {view}").fetchone()[0]
        total_fail += n
        status = "OK  " if n == 0 else "WARN"
        print(f"  [{status}] {code} {desc:<42} -> {n} fila(s)")
    print(f"\n  Total de filas que violan algun control: {total_fail}")
    print("  (Se esperan WARN: son los errores controlados del dataset,")
    print("   detectados y aislados — no contaminan las metricas oficiales.)")

    if "--queries" in sys.argv:
        print("\n" + "=" * 64)
        print("CONSULTAS DE NEGOCIO — CMP2026053CSI")
        print("=" * 64)
        # Ejecuta cada sentencia SELECT del archivo y muestra el resultado.
        with open("analytics/business_queries.sql", encoding="utf-8") as fh:
            statements = [s.strip() for s in fh.read().split(";")
                          if "select" in s.lower()]
        for i, stmt in enumerate(statements, 1):
            print(f"\n--- Q{i} ---")
            print(con.execute(stmt).fetchdf().to_string(index=False))

    con.close()
    print("\nListo. Base persistida en challenge.duckdb")


if __name__ == "__main__":
    main()
