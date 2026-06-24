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
    "models/00_sources/analysis_config.sql",
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


def print_table(cur):
    """Imprime un resultado DuckDB como tabla, SIN depender de pandas."""
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    widths = [len(c) for c in cols]
    str_rows = []
    for r in rows:
        cells = ["" if v is None else str(v) for v in r]
        str_rows.append(cells)
        widths = [max(w, len(c)) for w, c in zip(widths, cells)]
    line = "  ".join(c.ljust(widths[i]) for i, c in enumerate(cols))
    print(line)
    print("  ".join("-" * widths[i] for i in range(len(cols))))
    for cells in str_rows:
        print("  ".join(c.ljust(widths[i]) for i, c in enumerate(cells)))


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
        # Permite reapuntar la campaña objetivo: --campaign CMP202604CASHBACK
        if "--campaign" in sys.argv:
            cid = sys.argv[sys.argv.index("--campaign") + 1]
            con.execute(
                "CREATE OR REPLACE VIEW analysis_config AS "
                f"SELECT '{cid}' AS target_campaign_id, 0 AS attribution_post_days"
            )
        target = con.execute(
            "SELECT target_campaign_id FROM analysis_config").fetchone()[0]
        print("\n" + "=" * 64)
        print(f"CONSULTAS DE NEGOCIO — campaña {target}")
        print("=" * 64)
        # Ejecuta cada sentencia SELECT del archivo y muestra el resultado.
        with open("analytics/business_queries.sql", encoding="utf-8") as fh:
            statements = [s.strip() for s in fh.read().split(";")
                          if "select" in s.lower()]
        for i, stmt in enumerate(statements, 1):
            print(f"\n--- Q{i} ---")
            print_table(con.execute(stmt))

    con.close()
    print("\nListo. Base persistida en challenge.duckdb")


if __name__ == "__main__":
    main()
