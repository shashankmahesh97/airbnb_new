{{ config(materialized = 'table') }}

with snapshot_versions as (

    select
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
        dbt_valid_from,
        dbt_valid_to,

        row_number() over (
            partition by listing_id
            order by dbt_valid_from
        ) as version_number

    from {{ ref('listings_snapshot') }}

),

versions as (

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

        /*
            The first version of each listing is backdated to 1900-01-01.
            Otherwise dbt_valid_from is when the snapshot first ran, so any
            booking predating that falls outside every date range and loses
            its attribution.
        */
        case
            when version_number = 1 then cast('1900-01-01' as date)
            else cast(dbt_valid_from as date)
        end                                                     as valid_from,

        cast(coalesce(dbt_valid_to, '9999-12-31') as date)      as valid_to,
        case when dbt_valid_to is null then true else false end as is_current

    from snapshot_versions

),

unknown_member as (

    select
        '-1'                       as listing_key,
        -1                         as listing_id,
        -1                         as host_id,
        'Unknown listing'          as listing_name,
        'unknown'                  as property_type,
        'unknown'                  as room_type,
        'Unknown'                  as city,
        'Unknown'                  as country,
        cast(0 as number(12,2))    as price_per_night,
        'USD'                      as currency,
        false                      as is_active,
        cast('1900-01-01' as date) as valid_from,
        cast('9999-12-31' as date) as valid_to,
        true                       as is_current

)

select * from versions
union all
select * from unknown_member
