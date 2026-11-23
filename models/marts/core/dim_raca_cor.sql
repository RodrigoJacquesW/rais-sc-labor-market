{{ code_dimension('raca_cor', "
    codigo in ('1', '2', '4', '6', '8') as informado,
    case codigo
        when '2' then 'Branca'
        when '4' then 'Preta ou parda'
        when '8' then 'Preta ou parda'
        when '1' then 'Indígena ou amarela'
        when '6' then 'Indígena ou amarela'
        else 'Não informada'
    end as grupo
") }}
