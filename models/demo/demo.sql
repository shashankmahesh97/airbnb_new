select listing_id, price_per_night, dbt_valid_from, dbt_valid_to
from snapshots.listings_snapshot
where listing_id = 1042
order by dbt_valid_from;