select
    condition_id,
    patient_id,
    encounter_id,
    condition_code,
    condition_text,
    clinical_status,
    onset_time,
    'fhir' as source_system
from {{ source('raw', 'fhir_conditions') }}
