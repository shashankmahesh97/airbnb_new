{{ config(materialized = 'table') }}

with source as (

    select *
    from {{ ref('bronze_hosts') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by host_id
        order by updated_at desc
    ) = 1

),

cleaned as (

    select
        cast(host_id as number(38,0))           as host_id,

        initcap(trim(host_first_name))          as host_first_name,
        initcap(trim(host_last_name))           as host_last_name,

        lower(trim(host_email))                 as host_email,
        sha2(lower(trim(host_email)), 256)      as host_email_hash,
        trim(host_phone)                        as host_phone,

        cast(host_since as date)                as host_since,
        initcap(trim(host_city))                as host_city,
        initcap(trim(host_country))             as host_country,

        cast(is_superhost as boolean)           as is_superhost,
        cast(response_rate as number(3,0))      as response_rate,
        lower(trim(host_tier))                  as host_tier,

        cast(created_at as timestamp_ntz)       as created_at,
        cast(updated_at as timestamp_ntz)       as updated_at,
        current_timestamp()                     as dbt_loaded_at

    from deduplicated

)

select * from cleaned
