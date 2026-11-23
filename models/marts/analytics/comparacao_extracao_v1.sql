-- How the CSV extract used in the first version compares with the complete RAIS.
select
    o.ano,
    o.vinculos                  as vinculos_rais,
    e.vinculos                  as vinculos_extracao_v1,
    o.ativos_3112               as ativos_rais,
    e.ativos_3112               as ativos_extracao_v1,
    round(e.ativos_3112 / o.ativos_3112, 3)     as cobertura_ativos,
    round(e.admissoes / o.admissoes, 3)         as cobertura_admissoes
from {{ ref('agg_emprego_ano') }} as o
join {{ ref('extracao_v1') }} as e using (ano)
