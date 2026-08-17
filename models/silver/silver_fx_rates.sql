{{ config(materialized = 'table') }}

with source as (

    select *
    from {{ ref('bronze_fx_rates') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by currency_code, rate_month
        order by rate_to_usd desc
    ) = 1

),

cleaned as (

    select
        upper(trim(cast(currency_code as varchar(3)))) as currency_code,
        cast(rate_month  as date)                      as rate_month,
        cast(rate_to_usd as number(18,8))              as rate_to_usd,
        current_timestamp()                            as dbt_loaded_at

    from deduplicated

)

select * from cleaned
