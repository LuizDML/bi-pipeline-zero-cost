SELECT
	m.portador,
	m.cc,
	m.cheque,
	m.titulo,
	m.data_,
	CASE 
		WHEN m.DataOriginal IS NULL THEN m.data_
		ELSE m.DataOriginal 
	END AS DataOriginal,
	m.clifor,
	m.cgc,
	m.AFavor,
	m.unidade,
	m.setor AS CodSetor,
	s.Setor,
	m.Conta AS CodCateg,
	m.Catego,
	m.SubConta AS CodSubCateg,
	m.SubCatego,
	m.Tipo_Lancto,
	m.Baixa,
	m.valor,
	m.Romaneio,
	m.nf
FROM [Banco].[dbo].[movimento_bancario] AS m
INNER JOIN [Banco].[dbo].[setor] AS s ON (s.conta = m.Setor) AND (s.tipo = m.Tipo_Lancto)
WHERE data_ > '2015-01-01 00:00:00.000'

