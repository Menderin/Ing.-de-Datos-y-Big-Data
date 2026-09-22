#!/usr/bin/env python3
"""
run_etl.py
Orquestador multiplataforma del Pipeline ETL para la Entrega 2.
Ejecuta la secuencia de scripts SQL sobre el contenedor Docker de SQL Server,
verificando la integridad y registrando los tiempos de ejecución.
"""

import os
import sys
import time
import subprocess
from pathlib import Path

CONTAINER_NAME = "bigdata-sqlserver"
SQLCMD_PATH = "/opt/mssql-tools18/bin/sqlcmd"

SCRIPTS = [
    ("1. Esquema DDL", "database/dw/01_create_dw_schema.sql"),
    ("2. DimDate (Calendario)", "database/dw/02_populate_dim_date.sql"),
    ("3. Dimensiones Maestras", "database/dw/03_etl_dimensions.sql"),
    ("4. Tablas de Hechos", "database/dw/04_etl_facts.sql"),
    ("5. Auditoria de Cuadratura", "database/dw/05_audit_and_validation.sql"),
]


def load_env_password(repo_root: Path) -> str:
    env_path = repo_root / ".env"
    if not env_path.exists():
        raise FileNotFoundError(
            "No se encontró el archivo .env en la raíz del repositorio. "
            "Copia .env.example a .env y define MSSQL_SA_PASSWORD."
        )

    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("MSSQL_SA_PASSWORD="):
                val = line.split("=", 1)[1].strip().strip('"').strip("'")
                if val:
                    return val
    raise ValueError("MSSQL_SA_PASSWORD no está configurado en .env")


def check_container_running(container_name: str):
    res = subprocess.run(
        ["docker", "inspect", "--format", "{{.State.Running}}", container_name],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0 or res.stdout.strip() != "true":
        raise RuntimeError(
            f"El contenedor Docker '{container_name}' no está ejecutándose. "
            "Inícialo con: docker compose up -d"
        )


def run_sql_script(script_path: Path, sa_password: str) -> str:
    with open(script_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    cmd = [
        "docker", "exec", "-i",
        "-e", f"SQLCMDPASSWORD={sa_password}",
        CONTAINER_NAME,
        SQLCMD_PATH,
        "-S", "localhost",
        "-U", "sa",
        "-C",
        "-b",
    ]

    proc = subprocess.run(
        cmd,
        input=sql_content,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        err_msg = proc.stderr.strip() or proc.stdout.strip()
        raise RuntimeError(f"Error ejecutando {script_path.name}:\n{err_msg}")
    return proc.stdout


def main():
    repo_root = Path(__file__).resolve().parent.parent.parent
    os.chdir(repo_root)

    print("=" * 65)
    print(" INICIANDO PIPELINE ETL - ENTREGA 2 (DATA WAREHOUSE)")
    print(f" Contenedor: {CONTAINER_NAME}")
    print(f" Directorio raíz: {repo_root}")
    print("=" * 65)

    try:
        sa_password = load_env_password(repo_root)
        check_container_running(CONTAINER_NAME)
    except Exception as e:
        print(f"\n[ERROR DE CONFIGURACIÓN] {e}", file=sys.stderr)
        sys.exit(1)

    total_start = time.time()

    for idx, (title, rel_path) in enumerate(SCRIPTS, start=1):
        full_path = repo_root / rel_path
        if not full_path.exists():
            print(f"\n[ERROR] Archivo no encontrado: {rel_path}", file=sys.stderr)
            sys.exit(1)

        print(f"\n>>> Paso {idx}/{len(SCRIPTS)}: {title} ({rel_path}) ...")
        step_start = time.time()
        try:
            output = run_sql_script(full_path, sa_password)
            step_duration = time.time() - step_start
            if output.strip():
                print(output.strip())
            print(f"✓ Paso completado en {step_duration:.2f} segundos.")
        except Exception as e:
            print(f"\n[ERROR EN ETAPA {idx}] {e}", file=sys.stderr)
            sys.exit(1)

    total_duration = time.time() - total_start
    print("\n" + "=" * 65)
    print(" PIPELINE ETL FINALIZADO EXITOSAMENTE")
    print(f" Tiempo total: {total_duration:.2f} segundos")
    print(" Base analítica operativa: AdventureWorksDW")
    print("=" * 65)


if __name__ == "__main__":
    main()
