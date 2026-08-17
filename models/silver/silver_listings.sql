{{ config(materialized = 'table') }}

with source as (

    select *
    from {{ ref('bronze_listings') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by listing_id
        order by updated_at desc
    ) = 1

),

cleaned as (

    select
        cast(listing_id      as number(38,0))     as listing_id,
        cast(host_id         as number(38,0))     as host_id,

        trim(listing_name)                        as listing_name,
        lower(trim(property_type))                as property_type,
        lower(trim(room_type))                    as room_type,

        initcap(trim(city))                       as city,
        initcap(trim(country))                    as country,
        lower(trim(region))                       as region,
        cast(latitude  as number(9,6))            as latitude,
        cast(longitude as number(9,6))            as longitude,

        cast(accommodates    as number(3,0))      as accommodates,
        cast(bedrooms        as number(3,0))      as bedrooms,
        cast(bathrooms       as number(3,0))      as bathrooms,
        cast(price_per_night as number(12,2))     as price_per_night,
        upper(trim(cast(currency as varchar(3)))) as currency,
        cast(minimum_nights  as number(3,0))      as minimum_nights,

        cast(instant_bookable as boolean)         as instant_bookable,
        cast(is_active        as boolean)         as is_active,

        cast(created_at as timestamp_ntz)         as created_at,
        cast(updated_at as timestamp_ntz)         as updated_at,
        current_timestamp()                       as dbt_loaded_at

    from deduplicated

)

select * from cleaned
