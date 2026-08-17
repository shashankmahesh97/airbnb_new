{{ config(severity = 'warn') }}

with rates as (

    select
        count_if(not is_valid_stay) / nullif(count(*), 0) as invalid_rate
    from {{ ref('silver_bookings') }}

)

select invalid_rate
from rates
where invalid_rate > 0.01