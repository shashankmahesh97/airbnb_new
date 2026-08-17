{{ config(materialized = 'table') }}

with source as (

    select *
    from {{ ref('bronze_reviews') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by review_id
        order by updated_at desc
    ) = 1

),

cleaned as (

    select
        cast(review_id  as number(38,0))        as review_id,
        cast(booking_id as varchar(36))         as booking_id,
        cast(listing_id as number(38,0))        as listing_id,
        cast(guest_id   as number(38,0))        as guest_id,

        cast(review_date as date)               as review_date,

        cast(rating_overall     as number(3,1)) as rating_overall,
        cast(rating_cleanliness as number(3,1)) as rating_cleanliness,
        cast(rating_location    as number(3,1)) as rating_location,

        trim(review_comment)                    as review_comment,

        cast(created_at as timestamp_ntz)       as created_at,
        cast(updated_at as timestamp_ntz)       as updated_at,
        current_timestamp()                     as dbt_loaded_at

    from deduplicated

)

select * from cleaned
