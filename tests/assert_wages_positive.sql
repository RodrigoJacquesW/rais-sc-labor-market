select * from {{ ref('agg_emprego_municipio') }}
where mediana_remuneracao_real <= 0 or media_remuneracao_real <= 0
