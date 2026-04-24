with fhir as (
    select
        encounter_id,
        patient_id,
        encounter_class,
        encounter_status,
        start_time,
        end_time,
        'fhir' as source_system
    from {{ source('raw', 'fhir_encounters') }}
),
hl7 as (
    select
        encounter_id,
        patient_id,
        encounter_class,
        null::text as encounter_status,
        null::timestamptz as start_time,
        null::timestamptz as end_time,
        'hl7' as source_system
    from {{ source('raw', 'hl7_encounters') }}
),
csv as (
    select
        encounter_id,
        patient_id,
        encounter_class,
        encounter_status,
        start_time,
        end_time,
        'csv' as source_system
    from {{ source('raw', 'csv_encounters') }}
)
select * from fhir
union all
select * from hl7
union all
select * from csv
