.PHONY: help up down reset ingest dbt pipeline raw counts sources demo

.DEFAULT_GOAL := help

help:
	@echo "Targets:"
	@echo "  make up        Start stack (waits for Postgres)"
	@echo "  make down      Stop containers"
	@echo "  make reset     Stop and remove volumes"
	@echo "  make ingest    Load FHIR, HL7, and CSV into raw tables"
	@echo "  make dbt       Run dbt models and tests"
	@echo "  make pipeline  Full ingest + transform flow"
	@echo "  make raw       Show raw table row counts"
	@echo "  make counts    Show staging model row counts"
	@echo "  make sources   Show record counts by source system"
	@echo "  make demo      Run demo analytics queries"

up:
	docker compose up -d --wait

down:
	docker compose down

reset:
	docker compose down -v

ingest:
	docker compose exec ingestion python ingestion/fhir_loader.py
	docker compose exec ingestion python ingestion/hl7_parser.py
	docker compose exec ingestion python ingestion/csv_loader.py

dbt:
	docker compose exec dbt dbt run
	docker compose exec dbt dbt test

pipeline:
	./run_pipeline.sh

raw:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/raw_counts.sql

counts:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/staging_counts.sql

sources:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/records_by_source.sql

demo:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/raw_counts.sql
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/staging_counts.sql
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/records_by_source.sql
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < sql/demo_marts.sql
