{{ config(
    partition_by={'field': 'ano', 'data_type': 'int64', 'range': {'start': 2000, 'end': 2031, 'interval': 1}},
    cluster_by=['id_municipio', 'cnae_divisao']
) }}

-- Grain: one employment contract (vínculo) per year, as in RAIS. Kept at this grain (not
-- aggregated) so medians and percentiles stay possible: an average can be rebuilt from
-- sums and counts, a median cannot.
select
    v.ano,
    v.id_municipio,
    v.cnae_classe,
    c.cnae_divisao,
    v.sexo,
    v.raca_cor,
    v.escolaridade,
    v.faixa_etaria,
    v.idade,
    v.tipo_vinculo,
    v.ativo_3112,
    v.mes_admissao,
    v.mes_desligamento,
    v.motivo_desligamento,
    v.mes_admissao is null                                  as estoque_inicial,      -- employed on Jan 1
    v.mes_admissao is not null                              as admitido_no_ano,
    v.mes_desligamento is not null                          as desligado_no_ano,
    -- DIEESE "rotatividade descontada": dismissals that are not employer turnover are
    -- removed (employee's request, transfers, deaths, retirements)
    v.mes_desligamento is not null
        and coalesce(v.motivo_desligamento, 0) not in (21, 22, 30, 31, 32, 33, 34,
                                                       60, 62, 63, 64,
                                                       70, 71, 72, 73, 74, 75, 76, 78, 79, 80)
                                                            as desligamento_rotatividade,
    v.remuneracao_media,
    v.remuneracao_dezembro,
    v.horas_contratadas
from {{ ref('stg_rais__vinculos') }} as v
left join {{ ref('dim_cnae') }} as c
    on v.cnae_classe = c.cnae_classe
