select * from analytics.patient_summary order by encounter_count desc;
select * from analytics.encounter_counts order by month_start, encounter_class;
select * from analytics.observation_trends order by observation_date, observation_code;
