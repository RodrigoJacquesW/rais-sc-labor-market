{{ code_dimension('grau_instrucao_apos_2005', "
    safe_cast(codigo as int64) as ordem,
    case
        when codigo in ('1', '2', '3', '4', '5') then 'Até fundamental'
        when codigo in ('6', '7') then 'Médio'
        when codigo in ('8') then 'Superior incompleto'
        when codigo in ('9', '10', '11') then 'Superior completo'
        else 'Não informada'
    end as nivel
") }}
