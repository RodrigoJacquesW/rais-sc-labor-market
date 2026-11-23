-- Factor that brings a December wage of each year to December prices of the last year.
with dez as (
    select ano, indice
    from {{ source('ipca', 'mes_brasil') }}
    where mes = 12 and ano between {{ var("first_year") }} and {{ var("last_year") }}
)
select
    ano,
    indice,
    (select indice from dez where ano = {{ var("last_year") }}) / indice   as fator_preco_final
from dez
