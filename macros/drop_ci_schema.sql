{% macro drop_ci_schema(schema_name) %}

    {% set sql %}
        drop schema if exists {{ target.database }}.{{ schema_name }} cascade;
    {% endset %}

    {% do run_query(sql) %}
    {{ log("Dropped CI schema " ~ target.database ~ "." ~ schema_name, info=True) }}

{% endmacro %}
