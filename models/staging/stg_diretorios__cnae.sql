-- CNAE 2 at class level (5 digits, as in RAIS) with its division and section.
-- The directory has one class whose division name comes twice, once with a line break:
-- whitespace is normalized and the class is the grain.
select
    replace(replace(classe, '.', ''), '-', '')                          as cnae_classe,
    any_value(trim(regexp_replace(descricao_classe, r'\s+', ' ')))      as descricao_classe,
    any_value(divisao)                                                  as cnae_divisao,
    any_value(trim(regexp_replace(descricao_divisao, r'\s+', ' ')))     as descricao_divisao,
    any_value(secao)                                                    as cnae_secao,
    any_value(trim(regexp_replace(descricao_secao, r'\s+', ' ')))       as descricao_secao
from {{ source('diretorios', 'cnae_2') }}
group by 1
