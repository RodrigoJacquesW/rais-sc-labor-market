-- Employment contracts in the state and years of interest. Partition pruning on `ano` and
-- clustering on `sigla_uf` keep the scan small (~0.1 GB per year for these columns).
select
    ano,
    id_municipio,
    cnae_2                                                  as cnae_classe,
    vinculo_ativo_3112 = '1'                                as ativo_3112,
    nullif(mes_admissao, 0)                                 as mes_admissao,  -- previous year: null until 2022, 0 from 2023
    nullif(mes_desligamento, 0)                             as mes_desligamento,
    safe_cast(motivo_desligamento as int64)                 as motivo_desligamento,
    sexo,
    raca_cor,
    grau_instrucao_apos_2005                                as escolaridade,
    faixa_etaria,
    idade,
    tipo_vinculo,
    valor_remuneracao_media                                 as remuneracao_media,
    valor_remuneracao_dezembro                              as remuneracao_dezembro,
    quantidade_horas_contratadas                            as horas_contratadas
from {{ source('rais', 'microdados_vinculos') }}
where sigla_uf = '{{ var("uf") }}'
  and ano between {{ var("first_year") }} and {{ var("last_year") }}
