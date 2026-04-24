with fhir as (
    select
        observation_id,
        patient_id,
        encounter_id,
        observation_code,
        observation_text,
        value_numeric,
        unit,
        observed_at,
        'fhir' as source_system
    from {{ source('raw', 'fhir_observations') }}
),
hl7 as (
    select
        observation_id,
        patient_id,
        encounter_id,
        observation_code,
        observation_text,
        nullif(value_text, '')::numeric as value_numeric,
        unit,
        to_timestamp(nullif(observed_at, ''), 'YYYYMMDDHH24MI') as observed_at,
        'hl7' as source_system
    from {{ source('raw', 'hl7_observations') }}
),
csv as (
    select
        observation_id,
        patient_id,
        encounter_id,
        observation_code,
        observation_text,
        value_numeric,
        unit,
        observed_at,
        'csv' as source_system
    from {{ source('raw', 'csv_observations') }}
)
select * from fhir
union all
select * from hl7
union all
select * from csv
