--DROP TABLE IF EXISTS VendasUnpivot;

WITH DadosUnpivot AS (
    SELECT 
  		loja,
  		pedido,
  		romaneio,
  		dtpedido AS dt_pedido,
  		cliente,
  		colecao,
  		linha AS id_linha,
  		modelo,
  		cor AS id_cor,
  		tam,
  		qte,
  		preco AS pr_cad,
  		pvenda AS pr_venda,
  		pvenda * qte AS tpvenda,
  		frete,
  		custo AS pr_custo,
  		baixa,
		dataentregue as dt_entregue,
  		tipo AS mostruario
    FROM 
        (SELECT 
			loja,
			pedido,
			romaneio,
			DtPedido,
			Cliente,
			colecao,
			linha,
			modelo,
			cor,
			t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12,
			qte1, qte2, qte3, qte4, qte5, qte6, qte7, qte8, qte9, qte10, qte11, qte12,
			Preco,
			PVenda,
			frete,
			custo,
			baixa,
			DataEntregue,
			tipo
        FROM [Banco].[dbo].[descritivos_pedidos]) AS SourceTable
		  UNPIVOT
		  (
			  Tam FOR Tamanho IN (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12)
		  ) AS UnpivotTam
		  UNPIVOT
		  (
			  qte FOR Quantidade IN (qte1, qte2, qte3, qte4, qte5, qte6, qte7, qte8, qte9, qte10, qte11, qte12)
		  ) AS UnpivotQt
		WHERE 
  		-- troca o formato de gravar a grade toda e as quantidade para gravar um tamanho por linha
  		REPLACE(Tamanho, 't', '') = REPLACE(Quantidade, 'qte', '')
          AND Tam IS NOT NULL
          AND Qte > 0
)

-- Criando a nova tabela ou inserindo os dados
SELECT d.loja, 
		d.pedido, 
		d.romaneio, 
		dt_pedido, 
		d.cliente AS CNPJ, 
		cli.CLIENTE AS Razao, cli.NomePais, cli.Regiao, cli.uf, cli.cidade, cli.ddd, cli.fones, cli.email, cli.TipoCredito, cli.tipo,
		pd.Repres1, rp.NomeRepres1, 
		COALESCE(pd.comRepres1, 0) AS comRepres1, 
		COALESCE(pd.Repres2, 0) AS Repres2,
		COALESCE(pd.comRepres2, 0) AS comRepres2,
		pd.Vendedor, 
		COALESCE(pd.ComVend, 0) AS ComVend,
		CASE 
			WHEN pd.OrigemPedido IS NULL THEN 'Vendas'
			WHEN pd.OrigemPedido = 538976288 THEN 'Vendas' 
			WHEN pd.OrigemPedido = 0 THEN 'Vendas'
			WHEN pd.OrigemPedido = 2 THEN 'App Pedidos'
			WHEN pd.OrigemPedido = 3 THEN 'Loja Virtual'
			WHEN pd.OrigemPedido = 5 THEN 'App Catalogo'
			ELSE 'Softvest' END AS OrigemPedido,
		mostruario, colecao, 
		d.modelo, p.nome, id_cor, c.nome_cor, p.grade, 
		tam, qte, pr_cad, pr_venda, TPVenda, 
		CASE WHEN frete IS NULL THEN 0.00 ELSE frete END AS frete, 
		COALESCE(pr_custo, 0.00) AS pr_custo,  
		COALESCE(dt_entregue, DATEADD(MONTH, 2, GETDATE())) AS dt_entregue, 
		CASE
			WHEN BAIXA = 'S' THEN ro.DtRomaneio
			ELSE d.dt_entregue
		END AS DtRomaneio,
		baixa, 
		COALESCE(qte * pr_custo, 0.00) AS TPCusto,
		'V' AS Marca

FROM DadosUnpivot AS d

INNER JOIN (
    SELECT
        Modelo,
        Nome,
        grade
    FROM [Banco].[dbo].[cad_produtos]
    WHERE loja = 2
) AS p 
    ON d.Modelo = p.Modelo

INNER JOIN (
	SELECT DISTINCT
		nome AS nome_cor,
		Cor
	FROM [Banco].[dbo].[cad_cores]) AS c ON c.cor = d.id_cor

INNER JOIN (
	SELECT 
		cgc,
		cliente,
		CIDADE,
		uf,
		NomePais,
		Regiao,
		ddd, 
		FONES,
		Email,
		TipoCredito,
		TIPO
	FROM [Banco].[dbo].[cad_clientes]) AS cli ON d.cliente = cli.CGC

INNER JOIN (
	SELECT
		loja,
		Pedido,
		Represen AS Repres1,
		comissao AS comRepres1,
		Represen2 AS Repres2,
		comissao2 AS comRepres2,
		vendedor,
		ComVend,
		OrigemPedido
	FROM [Banco].[dbo].[cabecalho_pedido]) AS pd ON (pd.pedido = d.pedido) AND (pd.loja = d.loja)

INNER JOIN (
	SELECT 
		numero,
		nome AS NomeRepres1
	FROM [Banco].[dbo].[cad_representante]) AS rp ON (pd.Repres1 = rp.numero)

INNER JOIN (
	SELECT
		dtromaneio,
		loja,
		spedido,
		Romaneio
	FROM [Banco].[dbo].[cabecalho_romaneio]) AS ro ON (ro.spedido = d.pedido) AND (ro.loja = d.loja) AND (ro.romaneio = d.Romaneio)

WHERE d.dt_pedido > '2015-01-01'

UNION ALL

SELECT 
	ld.Loja,
	99999 AS Pedido,
	ld.romaneio, 
	dtromaneio AS dt_pedido, 
	ld.cliente AS CNPJ, 
	cli.Cliente AS Razao,
	cli.NomePais, 
	cli.Regiao, 
	cli.uf, 
	cli.cidade, 
	cli.ddd,
	cli.fones,
	cli.email,
	cli.TipoCredito, 
	cli.TIPO,
	lr.Repres1, 
	rp.NomeRepres1,
	COALESCE(lr.comRepres1, 0) AS comRepres1,
	COALESCE(lr.Repres2,  0) AS Repres2,
	COALESCE(lr.comRepres2, 0) AS comRepres2,
	lr.Vendedor,
	COALESCE(lr.comvend, 0) AS ComVend,
	'Loja' AS OrigemPedido, 
	'N' AS mostruario, 
	colecao, 
	ld.modelo, 
	p.nome, 
	ld.cor AS id_cor, 
	c.nome_cor, 
	p.grade, 
	T1 AS tam, 
	tqte AS qte, 
	preco AS pr_cad, 
	pvenda AS pr_venda, 
	TPVenda,
	CASE WHEN frete IS NULL THEN 0.00 ELSE frete END AS frete, 
	COALESCE(custo, 0.00) AS pr_custo, 
	DtRomaneio AS dt_entregue,
	DtRomaneio, --está redundante, mas é necessário por conta do descritivo
	'S' AS baixa,
	COALESCE(tqte * custo, 0.00) AS TPCusto,
	Marca
	
FROM [Banco].[dbo].[descritivos_loja] AS ld

INNER JOIN (
    SELECT
        Modelo,
        Nome,
        grade
    FROM [Banco].[dbo].[cad_produtos]
    WHERE loja = 2
) AS p 
    ON ld.Modelo = p.Modelo

INNER JOIN (
	SELECT DISTINCT
		nome AS nome_cor,
		Cor
	FROM [Banco].[dbo].[cad_cores]) AS c ON c.cor = ld.cor

INNER JOIN (
	SELECT 
		cgc,
		CLIENTE,
		CIDADE,
		uf,
		NomePais,
		Regiao,
		ddd, 
		FONES,
		Email,
		TipoCredito,
		TIPO
	FROM [Banco].[dbo].[cad_clientes]) AS cli ON ld.cliente = cli.CGC

INNER JOIN (
	SELECT
		Loja,
		Romaneio,
		Represen AS Repres1,
		comissao AS comRepres1,
		Represen2 AS Repres2,
		comissao2 AS comRepres2,
		Vendedor,
		comVend,
		OrigemPedido
	FROM [Banco].[dbo].[cabecalho_romaneio_loja]) AS lr ON (lr.Romaneio = ld.Romaneio) AND (lr.loja = ld.loja)

INNER JOIN (
	SELECT 
		numero,
		nome AS NomeRepres1
	FROM [Banco].[dbo].[cad_representante]) AS rp ON (lr.Repres1 = rp.numero)

WHERE DtRomaneio > '2015-01-01'

