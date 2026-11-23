select
    nome_coluna,
    chave                                   as codigo,
    valor                                   as descricao
from {{ source('rais', 'dicionario') }}
where id_tabela = 'microdados_vinculos'
