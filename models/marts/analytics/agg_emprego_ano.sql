-- State-level series: stock, flows, turnover and wages per year.
with flows as (
    select
        ano,
        count(*)                                        as vinculos,
        countif(ativo_3112)                             as ativos_3112,
        countif(estoque_inicial)                        as estoque_inicial,
        countif(admitido_no_ano)                        as admissoes,
        countif(desligado_no_ano)                       as desligamentos,
        countif(desligamento_rotatividade)              as desligamentos_rotatividade,
        countif(ativo_3112 and coalesce(remuneracao_dezembro, 0) = 0)  as ativos_sem_remuneracao
    from {{ ref('fct_vinculos') }}
    group by ano
),
wages as (
    select distinct
        ano,
        percentile_cont(remuneracao_real, 0.5) over (partition by ano)    as mediana_remuneracao_real,
        avg(remuneracao_real) over (partition by ano)                      as media_remuneracao_real,
        percentile_cont(remuneracao_dezembro, 0.5) over (partition by ano) as mediana_remuneracao_nominal
    from ({{ wage_base() }})
)
select
    f.*,
    f.admissoes - f.desligamentos                                                       as saldo,
    -- DIEESE: min(admissions, dismissals) / average stock
    safe_divide(least(f.admissoes, f.desligamentos), (f.estoque_inicial + f.ativos_3112) / 2)              as rotatividade,
    safe_divide(least(f.admissoes, f.desligamentos_rotatividade), (f.estoque_inicial + f.ativos_3112) / 2) as rotatividade_descontada,
    safe_divide(f.ativos_sem_remuneracao, f.ativos_3112)                               as share_ativos_sem_remuneracao,
    w.mediana_remuneracao_real,
    w.media_remuneracao_real,
    w.mediana_remuneracao_nominal
from flows as f
join wages as w using (ano)
