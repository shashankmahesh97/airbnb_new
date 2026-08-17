{{ config(materialized = 'table') }}

with spine as (

    {{ dbt_utils.date_spine(
        datepart    = "day",
        start_date  = "cast('2023-01-01' as date)",
        end_date    = "cast('2027-01-01' as date)"
    ) }}

),

enriched as (

    select
        cast(date_day as date)                          as date_key,
        date_day                                        as calendar_date,

        year(date_day)                                  as calendar_year,
        quarter(date_day)                               as calendar_quarter,
        month(date_day)                                 as calendar_month,
        monthname(date_day)                             as month_name,
        day(date_day)                                   as day_of_month,
        dayofweek(date_day)                             as day_of_week,
        dayname(date_day)                               as day_name,
        weekofyear(date_day)                            as week_of_year,

        date_trunc('month', date_day)                   as month_start_date,
        last_day(date_day)                              as month_end_date,

        case when dayofweek(date_day) in (0, 6)
             then true else false end                   as is_weekend

    from spine

)

select * from enriched
