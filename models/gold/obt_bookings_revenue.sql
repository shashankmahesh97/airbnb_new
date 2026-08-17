{{ config(materialized = 'table') }}

/*
    One big table for the BI layer, built ON TOP of the star schema rather than
    instead of it. The star stays the source of truth and keeps the model
    maintainable; this flattens it so the dashboard runs single-table scans with
    no joins at query time.

    Trade-off: storage duplication and a rebuild whenever a dimension changes.
    Accepted because the BI tool is read-heavy and latency matters more than
    storage here.
*/

select
    f.booking_id,

    -- dates
    f.booking_date,
    d.calendar_year,
    d.calendar_quarter,
    d.month_start_date,
    d.month_name,
    d.is_weekend,

    -- listing (as it was on the booking date)
    l.listing_id,
    l.listing_name,
    l.property_type,
    l.room_type,
    l.city          as listing_city,
    l.country       as listing_country,

    -- host
    h.host_id,
    h.host_full_name,
    h.host_country,
    h.is_superhost,
    h.host_tier,

    -- guest
    g.guest_id,
    g.age_band,
    g.guest_country,

    -- booking attributes
    f.booking_status,
    f.channel,
    f.payment_method,
    f.currency,
    f.nights_booked,

    -- measures
    f.accommodation_revenue_usd,
    f.cleaning_fee_usd,
    f.service_fee_usd,
    f.booking_value_usd,
    f.net_revenue_usd,
    f.is_cancelled

from {{ ref('fct_bookings') }} f
left join {{ ref('dim_listing') }} l on f.listing_key = l.listing_key
left join {{ ref('dim_host')    }} h on f.host_key    = h.host_key
left join {{ ref('dim_guest')   }} g on f.guest_key   = g.guest_key
left join {{ ref('dim_date')    }} d on f.date_key    = d.date_key
