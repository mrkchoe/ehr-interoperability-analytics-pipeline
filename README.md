# ehr-interoperability-analytics-pipeline

A small local demo that standardizes synthetic EHR data from different formats into shared analytics tables.

It reads three common source formats:

- FHIR NDJSON
- HL7 v2
- CSV extracts

## Goal

The project shows one simple interoperability pattern: load FHIR, HL7 v2, and CSV data, then normalize them into common `patients`, `encounters`, `conditions`, and `observations` models.

## How It Works

```text
FHIR / HL7 / CSV -> Python loaders -> raw Postgres tables -> standardized dbt models -> analytics tables
```

The main analytics tables are:

- `patient_summary`
- `encounter_counts`
- `observation_trends`
- `records_by_source`

## Quick Start

Run the whole pipeline from a clean slate:

```bash
make fresh
```

Or run the pipeline on an existing stack:

```bash
make pipeline
```

Show the demo queries:

```bash
make demo
```

That is enough for the normal local demo. `make pipeline` starts the Docker stack, loads the sample data, runs dbt, runs tests, and prints row counts after ingest and again at the end.

Run `make help` to list all targets.

## Useful Commands

```bash
make build     # build ingestion image
make up        # start containers
make fresh     # reset volumes and run full pipeline
make ingest    # load FHIR, HL7, and CSV samples
make dbt       # run dbt models and tests
make raw       # show row counts for raw ingestion tables
make counts    # show row counts for unified tables
make sources   # show row counts by source format/entity
make summary   # show raw, staging, and source counts
make marts     # show final analytics marts
make demo      # run full demo query set
make ps        # show container status
make logs      # tail service logs
make down      # stop containers
make reset     # stop containers and remove volumes
```

## What Gets Built

The loaders write source-specific tables into the `raw` schema. dbt then creates unified analytics models for:

- `patients`
- `encounters`
- `conditions`
- `observations`

The final marts answer simple questions:

- patient-level utilization in `patient_summary`
- monthly encounter volume in `encounter_counts`
- observation trends over time in `observation_trends`
- row counts by source format in `records_by_source`

## Data Quality

dbt tests check required IDs, uniqueness for key tables, relationships between patients, encounters, conditions, and observations, and accepted values for `records_by_source`.

## Notes

- Everything runs locally with Docker Compose.
- All data is synthetic sample data.
- There are no cloud services, APIs, or auth.
