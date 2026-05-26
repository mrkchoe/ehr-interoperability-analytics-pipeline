# ehr-interoperability-analytics-pipeline

Minimal, production-style local data engineering project that ingests synthetic EHR data from mixed healthcare formats (FHIR NDJSON, HL7 v2, CSV), standardizes it, and builds analytics-ready Postgres tables with dbt.

## Architecture

- **Raw ingestion schema (`raw`)**: one set of source-specific tables loaded by Python scripts.
- **Standardized staging (`analytics`)**: dbt models unify source formats into shared entities:
  - `patients`
  - `encounters`
  - `conditions`
  - `observations`
- **Marts (`analytics`)**: simple analytics outputs:
  - `patient_summary`
  - `encounter_counts`
  - `observation_trends`
  - `records_by_source`

```text
FHIR NDJSON ----\
HL7 v2 ---------> Python loaders ----> raw.* tables ----> dbt staging ----> dbt marts
CSV extracts ---/                                           (patients,        (analytics-ready
                                                            encounters,       summary tables)
                                                            conditions,
                                                            observations)
```

## Project Structure

```text
.
├── data/
│   ├── fhir/
│   ├── hl7/
│   └── csv/
├── ingestion/
│   ├── fhir_loader.py
│   ├── hl7_parser.py
│   ├── csv_loader.py
│   ├── Dockerfile
│   └── requirements.txt
├── models/
│   ├── staging/
│   └── marts/
├── sql/
│   └── 001_init.sql
├── docker-compose.yml
├── dbt_project.yml
├── Makefile
├── profiles.yml
├── demo.sql
├── run_pipeline.sh
└── README.md
```

## Quick Start

1. Start local stack (waits for Postgres to be healthy):

```bash
make up
```

2. Load raw data:

```bash
docker compose exec ingestion python ingestion/fhir_loader.py
docker compose exec ingestion python ingestion/hl7_parser.py
docker compose exec ingestion python ingestion/csv_loader.py
```

3. Build analytics models and run tests:

```bash
docker compose exec dbt dbt run
docker compose exec dbt dbt test
```

Or run the full flow in one command:

```bash
./run_pipeline.sh
```

Or use make targets for common steps:

```bash
make up
make ingest
make dbt
make counts
make demo
```

## Source to Unified Mapping

### FHIR NDJSON
- `Patient` -> `raw.fhir_patients` -> `analytics.patients`
- `Encounter` -> `raw.fhir_encounters` -> `analytics.encounters`
- `Condition` -> `raw.fhir_conditions` -> `analytics.conditions`
- `Observation` -> `raw.fhir_observations` -> `analytics.observations`

### HL7 v2
- `PID` -> `raw.hl7_patients` -> `analytics.patients`
- `PV1` -> `raw.hl7_encounters` -> `analytics.encounters`
- `OBX` -> `raw.hl7_observations` -> `analytics.observations`

### CSV
- `patients.csv` -> `raw.csv_patients` -> `analytics.patients`
- `encounters.csv` -> `raw.csv_encounters` -> `analytics.encounters`
- `observations.csv` -> `raw.csv_observations` -> `analytics.observations`

## dbt Tests Included

- Not null:
  - `patients.patient_id`
  - `encounters.encounter_id`
  - `conditions.condition_id`
  - `conditions.patient_id`
  - `observations.patient_id`
  - `observations.encounter_id`
- Uniqueness:
  - `encounters.encounter_id`
  - `conditions.condition_id`
  - `observations.observation_id`
  - `patient_summary.patient_id`
- Accepted values:
  - `records_by_source.entity` is one of `patients`, `encounters`, `conditions`, `observations`
  - `records_by_source.source_system` is one of `fhir`, `hl7`, `csv`
- Referential integrity:
  - `encounters.patient_id` references `patients.patient_id`
  - `conditions.patient_id` references `patients.patient_id`
  - `observations.patient_id` references `patients.patient_id`
  - `observations.encounter_id` references `encounters.encounter_id`

## Example Analytics Queries

```sql
-- Per-patient utilization summary
select * from analytics.patient_summary order by encounter_count desc;

-- Monthly encounter volume by encounter class
select * from analytics.encounter_counts order by month_start, encounter_class;

-- Observation metric trends over time
select * from analytics.observation_trends order by observation_date, observation_code;

-- Unified entity volume by upstream source (FHIR, HL7, CSV)
select * from analytics.records_by_source order by entity, source_system;
```

## Demo Walkthrough

Use this flow for a quick project demo from empty local state to analytics output.

1. Reset and start services:

```bash
docker compose down -v
docker compose up -d
```

2. Load all source data and run transformations:

```bash
./run_pipeline.sh
```

3. Show raw ingestion counts by source table:

```bash
docker compose exec postgres psql -U ehr -d ehr_analytics -c "
select 'fhir_patients' as table_name, count(*) from raw.fhir_patients
union all select 'hl7_patients', count(*) from raw.hl7_patients
union all select 'csv_patients', count(*) from raw.csv_patients
union all select 'fhir_encounters', count(*) from raw.fhir_encounters
union all select 'fhir_conditions', count(*) from raw.fhir_conditions
union all select 'hl7_encounters', count(*) from raw.hl7_encounters
union all select 'csv_encounters', count(*) from raw.csv_encounters
union all select 'fhir_observations', count(*) from raw.fhir_observations
union all select 'hl7_observations', count(*) from raw.hl7_observations
union all select 'csv_observations', count(*) from raw.csv_observations
order by 1;
"
```

4. Show unified staging model counts:

```bash
docker compose exec postgres psql -U ehr -d ehr_analytics -c "
select 'patients' as model_name, count(*) from analytics.patients
union all select 'encounters', count(*) from analytics.encounters
union all select 'conditions', count(*) from analytics.conditions
union all select 'observations', count(*) from analytics.observations
order by 1;
"
```

5. Show final marts:

```bash
docker compose exec postgres psql -U ehr -d ehr_analytics -c "select * from analytics.patient_summary order by encounter_count desc;"
docker compose exec postgres psql -U ehr -d ehr_analytics -c "select * from analytics.encounter_counts order by month_start, encounter_class;"
docker compose exec postgres psql -U ehr -d ehr_analytics -c "select * from analytics.observation_trends order by observation_date, observation_code;"
docker compose exec postgres psql -U ehr -d ehr_analytics -c "select * from analytics.records_by_source order by entity, source_system;"
```

Optional one-file demo query run:

```bash
docker compose exec -T postgres psql -U ehr -d ehr_analytics < demo.sql
```

## Notes

- This repo intentionally favors readability and explicit mapping over advanced orchestration.
- No cloud services, APIs, or auth are included.
- All included records are synthetic sample data for local development demos.
- `records_by_source` summarizes how many unified rows came from each upstream format.
