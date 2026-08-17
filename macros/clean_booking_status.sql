{% macro clean_booking_status(column_name) %}

    case lower(trim({{ column_name }}))
        when 'completed' then 'completed'
        when 'confirmed' then 'confirmed'
        when 'cancelled' then 'cancelled'
        when 'canceled'  then 'cancelled'
        when 'pending'   then 'pending'
        else 'unknown'
    end

{% endmacro %}