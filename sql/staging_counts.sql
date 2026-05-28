select 'patients' as model_name, count(*) from analytics.patients
union all select 'encounters', count(*) from analytics.encounters
union all select 'conditions', count(*) from analytics.conditions
union all select 'observations', count(*) from analytics.observations
order by 1;
