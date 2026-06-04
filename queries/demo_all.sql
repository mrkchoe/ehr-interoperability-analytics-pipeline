\echo 'Raw ingestion table counts'
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

\echo 'Unified staging model counts'
select 'patients' as model_name, count(*) from analytics.patients
union all select 'encounters', count(*) from analytics.encounters
union all select 'conditions', count(*) from analytics.conditions
union all select 'observations', count(*) from analytics.observations
order by 1;

\echo 'Records by source system'
select * from analytics.records_by_source
order by entity, source_system;

\echo 'Patient summary'
select * from analytics.patient_summary order by encounter_count desc;

\echo 'Encounter counts'
select * from analytics.encounter_counts order by month_start, encounter_class;

\echo 'Observation trends'
select * from analytics.observation_trends order by observation_date, observation_code;
