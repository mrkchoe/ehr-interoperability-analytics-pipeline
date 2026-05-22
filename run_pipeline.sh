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

echo "Staging model row counts:"
docker compose exec -T postgres psql -U ehr -d ehr_analytics -c "
select 'patients' as model_name, count(*) from analytics.patients
union all select 'encounters', count(*) from analytics.encounters
union all select 'conditions', count(*) from analytics.conditions
union all select 'observations', count(*) from analytics.observations
order by 1;
"

echo "Pipeline complete."
