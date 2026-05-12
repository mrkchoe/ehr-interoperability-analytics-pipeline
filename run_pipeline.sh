#!/usr/bin/env bash

set -euo pipefail

echo "Starting containers..."
docker compose up -d

echo "Waiting for Postgres to be ready..."
until docker compose exec postgres pg_isready -U ehr -d ehr_analytics > /dev/null 2>&1; do
  sleep 1
done

echo "Loading raw data..."
docker compose exec ingestion python ingestion/fhir_loader.py
docker compose exec ingestion python ingestion/hl7_parser.py
docker compose exec ingestion python ingestion/csv_loader.py

echo "Running dbt models..."
docker compose exec dbt dbt run

echo "Running dbt tests..."
docker compose exec dbt dbt test

echo "Pipeline complete."
