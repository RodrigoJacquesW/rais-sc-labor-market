-- Wages per CNAE division. Mean / median ratio shows how concentrated wages are inside a sector:
-- ranking by mean or by median can invert the order.
with w as (select * from ({{ wage_base() }}))
select distinct
    w.ano,
    w.cnae_divisao,
    c.descricao_divisao,
    c.cnae_secao,
    c.descricao_secao,
    count(*) over (partition by w.ano, w.cnae_divisao)                                as ativos_com_remuneracao,
    avg(w.remuneracao_real) over (partition by w.ano, w.cnae_divisao)                 as media_remuneracao_real,
    percentile_cont(w.remuneracao_real, 0.5) over (partition by w.ano, w.cnae_divisao) as mediana_remuneracao_real
from w
left join (select distinct cnae_divisao, descricao_divisao, cnae_secao, descricao_secao from {{ ref('dim_cnae') }}) as c
    using (cnae_divisao)
