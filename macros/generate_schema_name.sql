{# Datasets named rais_sc_staging, rais_sc_core, rais_sc_analytics (instead of dbt's default concatenation rules). #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}{{ target.schema }}{%- else -%}{{ target.schema }}_{{ custom_schema_name | trim }}{%- endif -%}
{%- endmacro %}
