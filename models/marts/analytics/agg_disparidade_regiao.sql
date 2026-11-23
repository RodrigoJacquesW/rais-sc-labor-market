-- Wage gaps by sex and by race/color in each intermediate region (medians, December wages).
-- Race/color only where it is informed; the coverage is reported next to the ratio.
with w as (
    select b.*, m.regiao_intermediaria, r.grupo as raca_grupo, r.informado as raca_informada
    from ({{ wage_base() }}) as b
    join {{ ref('dim_municipio') }} as m using (id_municipio)
    join {{ ref('dim_raca_cor') }} as r on b.raca_cor = r.codigo
),
medians as (
    select distinct
        ano, regiao_intermediaria,
        percentile_cont(if(sexo = '1', remuneracao_real, null), 0.5) over (partition by ano, regiao_intermediaria) as mediana_homens,
        percentile_cont(if(sexo = '2', remuneracao_real, null), 0.5) over (partition by ano, regiao_intermediaria) as mediana_mulheres,
        percentile_cont(if(raca_grupo = 'Branca', remuneracao_real, null), 0.5) over (partition by ano, regiao_intermediaria) as mediana_brancos,
        percentile_cont(if(raca_grupo = 'Preta ou parda', remuneracao_real, null), 0.5) over (partition by ano, regiao_intermediaria) as mediana_pretos_pardos
    from w
),
coverage as (
    select ano, regiao_intermediaria, count(*) as ativos, avg(if(raca_informada, 1, 0)) as cobertura_raca_cor,
           avg(if(raca_grupo = 'Preta ou parda', 1, 0)) / nullif(avg(if(raca_informada, 1, 0)), 0) as share_pretos_pardos_informados
    from w group by ano, regiao_intermediaria
)
select
    m.*,
    safe_divide(m.mediana_mulheres, m.mediana_homens)           as razao_mulheres_homens,
    safe_divide(m.mediana_pretos_pardos, m.mediana_brancos)     as razao_pretos_pardos_brancos,
    c.ativos,
    c.cobertura_raca_cor,
    c.share_pretos_pardos_informados
from medians as m
join coverage as c using (ano, regiao_intermediaria)
