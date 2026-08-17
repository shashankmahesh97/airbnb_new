{{ config(materialized = 'table') }}

with hosts as (

    select
        {{ dbt_utils.generate_surrogate_key(['host_id']) }} as host_key,
        host_id,
        host_first_name || ' ' || host_last_name           as host_full_name,
        host_email_hash,
        host_since,
        host_city,
        host_country,
        is_superhost,
        response_rate,
        host_tier,
        datediff(year, host_since, current_date())         as years_hosting

    from {{ ref('silver_hosts') }}

),

unknown_member as (

    select
        '-1'                        as host_key,
        -1                          as host_id,
        'Unknown host'              as host_full_name,
        null                        as host_email_hash,
        cast('1900-01-01' as date)  as host_since,
        'Unknown'                   as host_city,
        'Unknown'                   as host_country,
        false                       as is_superhost,
        cast(0 as number(3,0))      as response_rate,
        'unknown'                   as host_tier,
        0                           as years_hosting

)

select * from hosts
union all
select * from unknown_member
