{{ config(materialized = 'table') }}

with versions as (

    select
        {{ dbt_utils.generate_surrogate_key(['listing_id', 'dbt_valid_from']) }} as listing_key,

        listing_id,
        host_id,
        listing_name,
        property_type,
        room_type,
        city,
        country,
        price_per_night,
        currency,
        is_active,

        cast(dbt_valid_from as date)                            as valid_from,
        cast(coalesce(dbt_valid_to, '9999-12-31') as date)      as valid_to,
        case when dbt_valid_to is null then true else false end as is_current

    from {{ ref('listings_snapshot') }}

),

unknown_member as (

    select
        '-1'                    as listing_key,
        -1                      as listing_id,
        -1                      as host_id,
        'Unknown listing'       as listing_name,
        'unknown'               as property_type,
        'unknown'               as room_type,
        'Unknown'               as city,
        'Unknown'               as country,
        cast(0 as number(12,2)) as price_per_night,
        'USD'                   as currency,
        false                   as is_active,
        cast('1900-01-01' as date) as valid_from,
        cast('9999-12-31' as date) as valid_to,
        true                    as is_current

)

select * from versions
union all
select * from unknown_member
