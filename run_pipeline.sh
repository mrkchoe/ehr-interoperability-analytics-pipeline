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

echo "Raw table row counts:"
docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/raw_counts.sql

echo "Staging model row counts:"
docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/staging_counts.sql

echo "Records by source system:"
docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/records_by_source.sql

echo "Pipeline complete."
