#!/usr/bin/env bash

set -euo pipefail

echo "Starting containers (waiting for Postgres healthcheck)..."
docker compose up -d --wait

echo "Loading raw data..."
docker compose exec ingestion python ingestion/fhir_loader.py
docker compose exec ingestion python ingestion/hl7_parser.py
docker compose exec ingestion python ingestion/csv_loader.py

echo "Running dbt models..."
docker compose exec dbt dbt run

echo "Running dbt tests..."
docker compose exec dbt dbt test

echo "Pipeline summary:"
cat sql/raw_counts.sql sql/staging_counts.sql sql/records_by_source.sql \
  | docker compose exec -T postgres psql -U ehr -d ehr_analytics

echo "Pipeline complete."
