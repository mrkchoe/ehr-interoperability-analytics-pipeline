select
    date_trunc('day', observed_at)::date as observation_date,
    observation_code,
    avg(value_numeric) as avg_value,
    min(value_numeric) as min_value,
    max(value_numeric) as max_value,
    count(*) as measurement_count
from {{ ref('observations') }}
where value_numeric is not null
group by 1, 2
order by 1, 2
