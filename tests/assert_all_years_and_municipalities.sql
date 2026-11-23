-- Every year in range must have contracts in every one of the 295 municipalities of SC.
select ano, count(distinct id_municipio) as municipios
from {{ ref('agg_emprego_municipio') }}
group by ano
having count(distinct id_municipio) != 295
union all
select y, 0 from unnest(generate_array({{ var("first_year") }}, {{ var("last_year") }})) as y
where y not in (select ano from {{ ref('agg_emprego_ano') }})
