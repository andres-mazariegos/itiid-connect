"""Conexión a PostgreSQL (local o Supabase) usando la variable DATABASE_URL.

La cadena de conexión se lee del archivo .env (que NO se sube a GitHub)
o de una variable de entorno. Ejemplo en .env.example.
"""
import os
from pathlib import Path

import psycopg


def _leer_env():
    archivo = Path(__file__).resolve().parent.parent / ".env"
    if archivo.exists():
        for linea in archivo.read_text(encoding="utf-8").splitlines():
            linea = linea.strip()
            if linea and not linea.startswith("#") and "=" in linea:
                clave, valor = linea.split("=", 1)
                os.environ.setdefault(clave.strip(), valor.strip().strip('"'))


def conectar():
    _leer_env()
    url = os.environ.get("DATABASE_URL")
    if not url:
        raise SystemExit("Falta DATABASE_URL. Copia .env.example como .env y pon tu cadena de conexión.")
    conn = psycopg.connect(url)
    conn.execute("SET search_path TO itiid")
    conn.commit()
    return conn
