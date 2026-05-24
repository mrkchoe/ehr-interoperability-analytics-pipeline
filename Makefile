.PHONY: help up down reset ingest dbt pipeline counts demo

.DEFAULT_GOAL := help

help:
	@echo "Targets:"
	@echo "  make up        Start stack (waits for Postgres)"
	@echo "  make down      Stop containers"
	@echo "  make reset     Stop and remove volumes"
	@echo "  make ingest    Load FHIR, HL7, and CSV into raw tables"
	@echo "  make dbt       Run dbt models and tests"
	@echo "  make pipeline  Full ingest + transform flow"
	@echo "  make counts    Show staging model row counts"
	@echo "  make demo      Run demo.sql analytics queries"

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

counts:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics -c "\
select 'patients' as model_name, count(*) from analytics.patients \
union all select 'encounters', count(*) from analytics.encounters \
union all select 'conditions', count(*) from analytics.conditions \
union all select 'observations', count(*) from analytics.observations \
order by 1;"

demo:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < demo.sql
