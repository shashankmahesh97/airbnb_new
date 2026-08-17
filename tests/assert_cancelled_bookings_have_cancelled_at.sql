select
    booking_id,
    booking_status,
    cancelled_at
from {{ ref('silver_bookings') }}
where booking_status = 'cancelled'
  and cancelled_at is null