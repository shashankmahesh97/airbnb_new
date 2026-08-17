{{ config(materialized = 'table') }}

/*
    Note what is NOT here: email, phone, date_of_birth, card number.
    The dimension exposes age_band and country for segmentation, plus a hash
    for joining. Analysts get what they need to slice revenue; nobody
    downstream can identify an individual.
*/

with guests as (

    select
        {{ dbt_utils.generate_surrogate_key(['guest_id']) }} as guest_key,
        guest_id,
        email_hash,
        age_band,
        country                                             as guest_country,
        city                                                as guest_city,
        signup_date,
        payment_card_type,
        marketing_opt_in,
        datediff(day, signup_date, current_date())          as days_since_signup

    from {{ ref('silver_guests') }}

),

unknown_member as (

    select
        '-1'                        as guest_key,
        -1                          as guest_id,
        null                        as email_hash,
        'unknown'                   as age_band,
        'Unknown'                   as guest_country,
        'Unknown'                   as guest_city,
        cast('1900-01-01' as date)  as signup_date,
        'unknown'                   as payment_card_type,
        false                       as marketing_opt_in,
        0                           as days_since_signup

)

select * from guests
union all
select * from unknown_member
