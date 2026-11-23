{# Active contracts on Dec 31 with a positive December wage, at December prices of the last year.
   Contracts with zero wage (4-6% of the active ones) are excluded from wage statistics. #}
{% macro wage_base() %}
    select
        f.*,
        f.remuneracao_dezembro * d.fator_preco_final as remuneracao_real
    from {{ ref('fct_vinculos') }} as f
    join {{ ref('stg_ipca__deflator') }} as d using (ano)
    where f.ativo_3112 and f.remuneracao_dezembro > 0
{% endmacro %}
