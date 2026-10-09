#!/usr/bin/env python3
"""Carga tolerante en una sola sesion SQL y transaccion de publicacion."""
import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

CONTAINER_NAME = "bigdata-sqlserver"
SQLCMD_PATH = "/opt/mssql-tools18/bin/sqlcmd"
SCRIPTS = [
    "00_prepare_source.sql",
    "01_create_dw_schema.sql",
    "02_populate_dim_date.sql",
    "03_etl_dimensions.sql",
    "04_etl_facts.sql",
    "05_audit_and_validation.sql",
]


def load_env_password(repo_root):
    for line in (repo_root / ".env").read_text(encoding="utf-8-sig").splitlines():
        if re.match(r"^\s*MSSQL_SA_PASSWORD\s*=", line):
            value = line.split("=", 1)[1].strip().strip("\"'")
            if value:
                return value
    raise ValueError("Configura MSSQL_SA_PASSWORD en .env.")


def validate_name(value):
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]{0,127}", value):
        raise ValueError("Nombre de base invalido: usa letras, numeros y guion bajo.")
    return value


def build_pipeline(repo_root, source="AdventureWorks2022", target="AdventureWorksDW"):
    validate_name(source)
    validate_name(target)
    if source.lower() == target.lower() or target.lower() in {"master", "model", "msdb", "tempdb"}:
        raise ValueError("El destino debe ser una base analitica separada.")
    sql = (
        "USE master;\nGO\n"
        f"IF DB_ID(N'{source}') IS NULL THROW 51007, 'No existe la base fuente.', 1;\n"
        f"IF DB_ID(N'{target}') IS NULL EXEC(N'CREATE DATABASE [{target}]');\nGO\n"
    )
    for filename in SCRIPTS:
        body = (repo_root / "database" / "dw" / filename).read_text(encoding="utf-8-sig")
        sql += f"PRINT 'Etapa: {filename}';\nGO\n" + body + "\nGO\n"
    return sql.replace("$(SourceDatabase)", source).replace("$(TargetDatabase)", target)


def execute_sql(sql, password, container=CONTAINER_NAME):
    env = os.environ.copy()
    env["SQLCMDPASSWORD"] = password
    result = subprocess.run(
        ["docker", "exec", "-i", "-e", "SQLCMDPASSWORD", container, SQLCMD_PATH,
         "-S", "localhost", "-U", "sa", "-C", "-b", "-f", "65001", "-w", "240"],
        input=sql, capture_output=True, text=True, encoding="utf-8", errors="replace", env=env,
    )
    if result.returncode:
        raise RuntimeError(result.stdout + "\n" + result.stderr)
    return '\n'.join(line for line in result.stdout.splitlines()
                     if not re.fullmatch(r"Changed database context to '.*'\.", line))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default="AdventureWorks2022")
    parser.add_argument("--target", default="AdventureWorksDW")
    parser.add_argument("--container", default=CONTAINER_NAME)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    started = time.monotonic()
    try:
        sql = build_pipeline(root, args.source, args.target)
        password = load_env_password(root)
        print('\n' + '=' * 78 + '\nPIPELINE ETL - ADVENTUREWORKS')
        print(f'Origen: {args.source}\nDestino: {args.target}\n' + '=' * 78)
        print(execute_sql(sql, password, args.container))
    except Exception as exc:
        print(f"ERROR TECNICO: {exc}\nLa transaccion no publicada se revierte.", file=sys.stderr)
        return 1
    print(f"ETL terminado en {time.monotonic()-started:.2f} s. "
          "Consulte el estado de calidad en dbo.EtlRun.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
