.PHONY: help build up down reset fresh ingest dbt pipeline raw counts sources summary marts demo ps logs

.DEFAULT_GOAL := help

PSQL = docker compose exec -T postgres psql -U ehr -d ehr_analytics

help:
	@echo "Targets:"
	@echo "  make build     Build ingestion image"
	@echo "  make up        Start stack (waits for Postgres)"
	@echo "  make down      Stop containers"
	@echo "  make reset     Stop and remove volumes"
	@echo "  make fresh     Reset volumes and run full pipeline"
	@echo "  make ingest    Load FHIR, HL7, and CSV into raw tables"
	@echo "  make dbt       Run dbt models and tests"
	@echo "  make pipeline  Full ingest + transform flow"
	@echo "  make raw       Show raw table row counts"
	@echo "  make counts    Show staging model row counts"
	@echo "  make sources   Show record counts by source system"
	@echo "  make summary   Show raw, staging, and source counts"
	@echo "  make marts     Show final analytics marts"
	@echo "  make demo      Run full demo query set"
	@echo "  make ps        Show container status"
	@echo "  make logs      Tail service logs"

build:
	docker compose build ingestion

up:
	docker compose up -d --wait

down:
	docker compose down

reset:
	docker compose down -v

fresh: reset pipeline

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
	$(PSQL) < queries/raw_counts.sql

counts:
	$(PSQL) < queries/staging_counts.sql

sources:
	$(PSQL) < queries/records_by_source.sql

summary:
	$(PSQL) < queries/pipeline_summary.sql

marts:
	$(PSQL) < queries/demo_marts.sql

demo:
	cat queries/pipeline_summary.sql queries/demo_marts.sql | $(PSQL)

ps:
	docker compose ps

logs:
	docker compose logs --tail=100
