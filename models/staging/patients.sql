with fhir as (
    select
        patient_id,
        given_name,
        family_name,
        gender,
        birth_date::date as birth_date,
        'fhir' as source_system
    from {{ source('raw', 'fhir_patients') }}
),
hl7 as (
    select
        patient_id,
        given_name,
        family_name,
        gender,
        to_date(nullif(birth_date, ''), 'YYYYMMDD') as birth_date,
        'hl7' as source_system
    from {{ source('raw', 'hl7_patients') }}
),
csv as (
    select
        patient_id,
        given_name,
        family_name,
        gender,
        birth_date::date as birth_date,
        'csv' as source_system
    from {{ source('raw', 'csv_patients') }}
)
select * from fhir
union all
select * from hl7
union all
select * from csv
