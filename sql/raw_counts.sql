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
