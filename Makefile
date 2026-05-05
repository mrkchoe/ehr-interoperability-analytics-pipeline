up:
	docker compose up -d

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

demo:
	docker compose exec -T postgres psql -U ehr -d ehr_analytics < demo.sql
