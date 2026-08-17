{{
    config(
        materialized         = 'incremental',
        unique_key           = 'booking_id',
        incremental_strategy = 'merge',
        on_schema_change     = 'sync_all_columns',
        cluster_by           = ['booking_date']
    )
}}

with bookings as (

    select *
    from {{ ref('silver_bookings') }}
    where is_valid_stay = true

    {% if is_incremental() %}
    and updated_at >= (
        select coalesce(max(updated_at), '1900-01-01'::timestamp_ntz)
               - interval '3 days'
        from {{ this }}
    )
    {% endif %}

),

fx as (

    select currency_code, rate_month, rate_to_usd
    from {{ ref('silver_fx_rates') }}

),

joined as (

    select
        b.booking_id,

        -- point-in-time join: the listing as it was on the booking date,
        -- not as it is today. This is why the snapshot exists.
        coalesce(dl.listing_key, '-1')          as listing_key,
        coalesce(dh.host_key,    '-1')          as host_key,
        coalesce(dg.guest_key,   '-1')          as guest_key,
        b.booking_date                          as date_key,

        b.listing_id,
        b.host_id,
        b.guest_id,

        b.booking_date,
        b.checkin_date,
        b.checkout_date,
        b.cancelled_at,

        b.booking_status,
        b.payment_method,
        b.channel,
        b.currency,

        b.nights_booked,
        b.gross_amount,
        b.discount_amount,
        b.cleaning_fee,
        b.service_fee,

        f.rate_to_usd,

        b.updated_at

    from bookings b

    left join {{ ref('dim_listing') }} dl
           on b.listing_id  = dl.listing_id
          and b.booking_date >= dl.valid_from
          and b.booking_date <  dl.valid_to

    left join {{ ref('dim_host') }} dh
           on b.host_id = dh.host_id

    left join {{ ref('dim_guest') }} dg
           on b.guest_id = dg.guest_id

    left join fx f
           on b.currency = f.currency_code
          and date_trunc('month', b.booking_date) = f.rate_month

),

measures as (

    select
        *,

        -- local currency
        (gross_amount - discount_amount + cleaning_fee + service_fee) as booking_value_local,

        -- USD, the reportable measure
        round((gross_amount    - discount_amount) * rate_to_usd, 2)   as accommodation_revenue_usd,
        round(cleaning_fee  * rate_to_usd, 2)                         as cleaning_fee_usd,
        round(service_fee   * rate_to_usd, 2)                         as service_fee_usd,
        round((gross_amount - discount_amount + cleaning_fee + service_fee)
              * rate_to_usd, 2)                                       as booking_value_usd,

        -- THE headline metric: revenue we actually recognise
        case
            when booking_status in ('completed', 'confirmed')
            then round((gross_amount - discount_amount + cleaning_fee + service_fee)
                       * rate_to_usd, 2)
            else 0
        end                                                           as net_revenue_usd,

        case when booking_status = 'cancelled' then 1 else 0 end      as is_cancelled,
        case when rate_to_usd is null then true else false end        as is_missing_fx_rate,

        current_timestamp()                                           as dbt_loaded_at

    from joined

)

select * from measures
