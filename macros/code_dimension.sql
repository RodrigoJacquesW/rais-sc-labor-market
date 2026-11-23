{# A small dimension (code -> label) built from the RAIS dictionary. #}
{% macro code_dimension(column, extra_columns='') %}
select
    codigo,
    descricao
    {% if extra_columns %}, {{ extra_columns }}{% endif %}
from {{ ref('stg_rais__dicionario') }}
where nome_coluna = '{{ column }}'
{% endmacro %}
