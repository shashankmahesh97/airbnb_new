{% macro drop_ci_schema(schema_name) %}

    {#
        Models build into layered schemas: pr_1_bronze, pr_1_silver, pr_1_gold,
        pr_1_snapshots. Dropping only pr_1 would leave the rest behind, so every
        suffix generate_schema_name can produce is dropped here.
    #}

    {% set suffixes = ['', '_bronze', '_silver', '_gold', '_snapshots', '_staging'] %}

    {% for suffix in suffixes %}
        {% set sql %}
            drop schema if exists {{ target.database }}.{{ schema_name }}{{ suffix }} cascade;
        {% endset %}
        {% do run_query(sql) %}
        {{ log("Dropped schema " ~ target.database ~ "." ~ schema_name ~ suffix, info=True) }}
    {% endfor %}

{% endmacro %}
