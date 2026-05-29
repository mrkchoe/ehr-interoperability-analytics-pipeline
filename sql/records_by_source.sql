\echo 'Records by source system'
select * from analytics.records_by_source
order by entity, source_system;
