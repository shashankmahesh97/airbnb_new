{{ config(materialized = 'table') }}

with source as (

    select *
    from {{ ref('bronze_guests') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by guest_id
        order by updated_at desc
    ) = 1

),

cleaned as (

    select
        cast(guest_id as number(38,0))          as guest_id,

        initcap(trim(first_name))               as first_name,
        initcap(trim(last_name))                as last_name,

        lower(trim(email))                      as email,
        sha2(lower(trim(email)), 256)           as email_hash,
        trim(phone)                             as phone,

        cast(date_of_birth as date)             as date_of_birth,
        case
            when date_of_birth is null then 'unknown'
            when datediff(year, cast(date_of_birth as date), current_date()) < 25 then '18-24'
            when datediff(year, cast(date_of_birth as date), current_date()) < 35 then '25-34'
            when datediff(year, cast(date_of_birth as date), current_date()) < 45 then '35-44'
            when datediff(year, cast(date_of_birth as date), current_date()) < 55 then '45-54'
            else '55+'
        end                                     as age_band,

        right(trim(payment_card_number), 4)     as card_last_four,
        sha2(trim(payment_card_number), 256)    as card_hash,
        lower(trim(payment_card_type))          as payment_card_type,

        initcap(trim(country))                  as country,
        initcap(trim(city))                     as city,
        cast(signup_date as date)               as signup_date,
        cast(marketing_opt_in as boolean)       as marketing_opt_in,

        cast(created_at as timestamp_ntz)       as created_at,
        cast(updated_at as timestamp_ntz)       as updated_at,
        current_timestamp()                     as dbt_loaded_at

    from deduplicated

)

select * from cleaned
