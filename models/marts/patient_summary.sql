select
    p.patient_id,
    p.given_name,
    p.family_name,
    p.gender,
    p.birth_date,
    count(distinct e.encounter_id) as encounter_count,
    count(distinct o.observation_id) as observation_count,
    min(o.observed_at) as first_observation_at,
    max(o.observed_at) as latest_observation_at
from {{ ref('patients') }} p
left join {{ ref('encounters') }} e on p.patient_id = e.patient_id
left join {{ ref('observations') }} o on p.patient_id = o.patient_id
group by 1, 2, 3, 4, 5
