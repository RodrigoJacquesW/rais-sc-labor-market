select
    id_municipio,
    id_municipio_6,
    nome                                    as municipio,
    id_regiao_imediata,
    nome_regiao_imediata                    as regiao_imediata,
    id_regiao_intermediaria,
    nome_regiao_intermediaria               as regiao_intermediaria,
    capital_uf = 1                          as is_capital
from {{ source('diretorios', 'municipio') }}
where sigla_uf = '{{ var("uf") }}'
