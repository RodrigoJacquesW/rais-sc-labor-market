-- At most 0.1% of the active contracts may have a CNAE class missing from the directory.
select ano, countif(cnae_divisao is null) / count(*) as share_sem_cnae
from {{ ref('fct_vinculos') }}
where ativo_3112
group by ano
having countif(cnae_divisao is null) / count(*) > 0.001
