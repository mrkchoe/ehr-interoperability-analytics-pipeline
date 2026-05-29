\echo 'Patient summary'
select * from analytics.patient_summary order by encounter_count desc;

\echo 'Encounter counts'
select * from analytics.encounter_counts order by month_start, encounter_class;

\echo 'Observation trends'
select * from analytics.observation_trends order by observation_date, observation_code;
