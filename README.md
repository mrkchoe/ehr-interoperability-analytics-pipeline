# ehr-interoperability-analytics-pipeline

A **local, one-command demo** that takes synthetic EHR data in three formats and turns it into shared analytics tables in Postgres.

**Prerequisites:** Docker and Docker Compose.

---

## What this demo does

| Capability | What you see |
|------------|--------------|
| **Multi-format ingest** | Loads the same kinds of clinical data from **FHIR NDJSON**, **HL7 v2**, and **CSV** into Postgres |
| **Unified clinical models** | Normalizes everything into shared `patients`, `encounters`, `conditions`, and `observations` tables |
| **Analytics marts** | Builds ready-to-query summaries for utilization, volume, trends, and source coverage |
| **Built-in checks** | Runs dbt tests on IDs, relationships, and source-system values |

```text
FHIR / HL7 / CSV  →  Python loaders  →  raw tables  →  dbt  →  analytics marts
```

---

## Run the demo (start here)

**One command** for the full presenter walkthrough:

```bash
make walkthrough    # reset, pipeline, then demo output
make down           # stop containers when finished
```

Or run step by step:

```bash
make fresh    # clean slate: start stack, load data, transform, test, print counts
make demo     # show counts + final analytics tables
make down     # stop containers when finished
```

| Command | What happens |
|---------|----------------|
| `make walkthrough` | Runs `make fresh` then `make demo` — full end-to-end demo in one shot |
| `make fresh` | Resets volumes, runs the full pipeline (ingest → dbt → tests), prints row counts after load and at the end |
| `make demo` | Runs the full demo query set: raw counts, unified counts, source breakdown, and analytics marts (requires a running stack) |
| `make down` | Stops the Docker stack |

**Already have a running stack?** Use `make pipeline` instead of `make fresh` to re-run ingest and transforms without wiping data.

**Just want the charts/tables?** After a pipeline run:

```bash
make marts
```

---

## What you get

### Unified tables (staging)

Same shape regardless of source format:

- `patients`
- `encounters`
- `conditions`
- `observations`

### Analytics marts (the demo payoff)

| Mart | Answers |
|------|---------|
| `patient_summary` | Who has the most encounters and observations? |
| `encounter_counts` | How does encounter volume trend by month and class? |
| `observation_trends` | How do observation metrics change over time? |
| `records_by_source` | How many rows came from FHIR vs HL7 vs CSV per entity? |

`make demo` prints counts at each layer, then shows these marts.

---

## Demo flow (for presenters)

1. **`make walkthrough`** — one command: reset, load, transform, test, then show all demo output.
2. Or step through: **`make fresh`** (pipeline + counts), then **`make demo`** (marts).
3. **`make down`** — clean shutdown.

---

## Reference (optional commands)

Use these when you need finer control or troubleshooting—not for the default demo.

### Pipeline steps

```bash
make walkthrough  # full pipeline + demo output
make pipeline     # full flow without resetting volumes
make ingest       # load FHIR, HL7, and CSV only
make dbt          # run models and tests only
```

### Inspect results

```bash
make summary      # raw + staging + source counts
make raw          # raw ingestion table counts
make counts       # unified staging counts
make sources      # records by source system
make marts        # analytics marts only
```

### Stack maintenance

```bash
make up           # start containers
make reset        # stop and remove volumes (no pipeline)
make build        # rebuild ingestion image
make ps           # container status
make logs         # tail service logs
make help         # list all make targets
```

---

## Data quality

dbt tests cover:

- Required IDs on core entities
- Uniqueness on key tables
- Relationships between patients, encounters, conditions, and observations
- Accepted values for `records_by_source` (`entity`, `source_system`)

---

## Notes

- Runs entirely on your machine with Docker Compose.
- All data is **synthetic** sample data for demos.
- No cloud services, APIs, or authentication.
