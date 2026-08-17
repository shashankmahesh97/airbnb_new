-- Every booking must convert to USD. A missing rate silently under-reports
-- revenue, so this errors rather than warns.

select
    booking_id,
    currency,
    booking_date
from {{ ref('fct_bookings') }}
where is_missing_fx_rate = true