select
    date_trunc('month', coalesce(start_time, timestamp '1900-01-01'))::date as month_start,
    encounter_class,
    count(*) as encounter_count
from {{ ref('encounters') }}
group by 1, 2
order by 1, 2
