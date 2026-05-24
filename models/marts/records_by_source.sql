select 'patients' as entity, source_system, count(*) as record_count
from {{ ref('patients') }}
group by 1, 2

union all

select 'encounters' as entity, source_system, count(*) as record_count
from {{ ref('encounters') }}
group by 1, 2

union all

select 'conditions' as entity, source_system, count(*) as record_count
from {{ ref('conditions') }}
group by 1, 2

union all

select 'observations' as entity, source_system, count(*) as record_count
from {{ ref('observations') }}
group by 1, 2

order by 1, 2
