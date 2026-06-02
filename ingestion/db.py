import os

import psycopg


def get_conn():
    return psycopg.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        user=os.getenv("PGUSER", "ehr"),
        password=os.getenv("PGPASSWORD", "ehr"),
        dbname=os.getenv("PGDATABASE", "ehr_analytics"),
    )
