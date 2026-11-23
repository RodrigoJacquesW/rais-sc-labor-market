-- Per municipality and year: stock, flows and wages (median is immune to the outliers of port cities).
with flows as (
    select
        ano, id_municipio,
        countif(ativo_3112)                 as ativos_3112,
        countif(estoque_inicial)            as estoque_inicial,
        countif(admitido_no_ano)            as admissoes,
        countif(desligado_no_ano)           as desligamentos
    from {{ ref('fct_vinculos') }}
    group by ano, id_municipio
),
wages as (
    select distinct
        ano, id_municipio,
        percentile_cont(remuneracao_real, 0.5) over (partition by ano, id_municipio)  as mediana_remuneracao_real,
        avg(remuneracao_real) over (partition by ano, id_municipio)                    as media_remuneracao_real
    from ({{ wage_base() }})
)
select
    f.*,
    f.admissoes - f.desligamentos       as saldo,
    w.mediana_remuneracao_real,
    w.media_remuneracao_real,
    m.municipio,
    m.regiao_imediata,
    m.regiao_intermediaria
from flows as f
left join wages as w using (ano, id_municipio)
join {{ ref('dim_municipio') }} as m using (id_municipio)
