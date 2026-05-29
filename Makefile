.PHONY: help up down reset ingest dbt pipeline raw counts sources marts demo

.DEFAULT_GOAL := help

PSQL = docker compose exec -T postgres psql -U ehr -d ehr_analytics

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
	@echo "  make marts     Show final analytics marts"
	@echo "  make demo      Run full demo query set"

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
	$(PSQL) < sql/raw_counts.sql

counts:
	$(PSQL) < sql/staging_counts.sql

sources:
	$(PSQL) < sql/records_by_source.sql

marts:
	$(PSQL) < sql/demo_marts.sql

demo:
	cat sql/raw_counts.sql sql/staging_counts.sql sql/records_by_source.sql sql/demo_marts.sql | $(PSQL)
