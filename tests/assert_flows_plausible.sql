-- Guards against a coding change in the source (from 2023 Base dos Dados codes "admitted in a
-- previous year" as 0 instead of null): with the wrong code, the initial stock becomes 0 and
-- every contract counts as an admission, and the stock identity still closes. Most contracts
-- active at year end were already employed on Jan 1.
select ano, estoque_inicial, admissoes, vinculos, ativos_3112
from {{ ref('agg_emprego_ano') }}
where estoque_inicial < 0.5 * ativos_3112
   or admissoes >= vinculos
