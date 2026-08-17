{% snapshot listings_snapshot %}

{{
    config(
        target_database = target.database,
        target_schema   = target.schema ~ '_snapshots',
        unique_key      = 'listing_id',
        strategy        = 'timestamp',
        updated_at      = 'updated_at',
        invalidate_hard_deletes = true
    )
}}

select
    cast(listing_id      as number(38,0)) as listing_id,
    cast(host_id         as number(38,0)) as host_id,
    trim(listing_name)                    as listing_name,
    lower(trim(property_type))            as property_type,
    lower(trim(room_type))                as room_type,
    initcap(trim(city))                   as city,
    initcap(trim(country))                as country,
    cast(price_per_night as number(12,2)) as price_per_night,
    upper(trim(currency))                 as currency,
    cast(is_active as boolean)            as is_active,
    cast(updated_at as timestamp_ntz)     as updated_at
from {{ ref('bronze_listings') }}
qualify row_number() over (
    partition by listing_id
    order by updated_at desc
) = 1

{% endsnapshot %}
