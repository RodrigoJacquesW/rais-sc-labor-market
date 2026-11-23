-- Stock identity: active on Dec 31 = employed on Jan 1 + admitted - dismissed.
-- Tolerance 0.5%: RAIS has a few contracts flagged inactive without a dismissal month.
select ano, estoque_inicial, admissoes, desligamentos, ativos_3112,
       estoque_inicial + admissoes - desligamentos as ativos_calculado
from {{ ref('agg_emprego_ano') }}
where abs((estoque_inicial + admissoes - desligamentos) - ativos_3112) > 0.005 * ativos_3112
