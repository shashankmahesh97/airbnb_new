{{
    config(
        materialized         = 'incremental',
        unique_key           = 'booking_id',
        incremental_strategy = 'merge',
        on_schema_change     = 'sync_all_columns',
        cluster_by           = ['booking_date']
    )
}}

with source as (

    select *
    from {{ ref('bronze_bookings') }}

    {% if is_incremental() %}
    where updated_at >= (
        select coalesce(max(updated_at), '1900-01-01'::timestamp_ntz)
               - interval '3 days'
        from {{ this }}
    )
    {% endif %}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by booking_id
        order by updated_at desc, created_at desc, gross_amount desc
    ) = 1

),

cleaned as (

    select
        cast(booking_id      as varchar(36))      as booking_id,
        cast(listing_id      as number(38,0))     as listing_id,
        cast(guest_id        as number(38,0))     as guest_id,
        cast(host_id         as number(38,0))     as host_id,

        cast(booking_date    as date)             as booking_date,
        cast(checkin_date    as date)             as checkin_date,
        cast(checkout_date   as date)             as checkout_date,
        cast(cancelled_at    as date)             as cancelled_at,

        cast(nights_booked   as number(5,0))      as nights_booked,
        cast(price_per_night as number(12,2))     as price_per_night,
        cast(gross_amount    as number(12,2))     as gross_amount,
        cast(discount_amount as number(12,2))     as discount_amount,
        cast(cleaning_fee    as number(12,2))     as cleaning_fee,
        cast(service_fee     as number(12,2))     as service_fee,

        upper(trim(cast(currency as varchar(3)))) as currency,
        {{ clean_booking_status('booking_status') }} as booking_status,
        lower(trim(payment_method))               as payment_method,
        lower(trim(channel))                      as channel,

        case
            when cast(nights_booked as number) <= 0                       then false
            when cast(gross_amount as number) <= 0                        then false
            when cast(checkout_date as date) < cast(checkin_date as date) then false
            else true
        end                                       as is_valid_stay,

        cast(created_at      as timestamp_ntz)    as created_at,
        cast(updated_at      as timestamp_ntz)    as updated_at,
        current_timestamp()                       as dbt_loaded_at

    from deduplicated

)

select * from cleaned
