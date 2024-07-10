/*
	CRIADO POR: ARTHUR REIS
	DATA: 06/06/2024

	SCRIPT GERADO PARA CRIAR UM RELATORIA DO CORREÇÃO DE IA. ONDE ELE VAI, ME TRAZER SE HÁ ALGUMA CORREÇÃO PENDENTE, A QTDE DE CORREÇÃO GERAL EM UM
	DETERMINADO PERIODO, QTDE DE PALAVRAS, PSEUDOPALAVRA E TEXTO.
*/

/*----------------------------------------*/
/*Bloco de código para retornar a tabela mais recente. */ 
/*Alterar os parâmetros da procedure e o nome das tabela temporárias, se necessário, conforme tabela que deseja retornar.*/

IF OBJECT_ID('tempdb..#PARAMETROS') IS NOT NULL DROP TABLE #PARAMETROS
GO
CREATE TABLE #PARAMETROS (CD_FONTE_REGISTRO VARCHAR(5) NOT NULL, CD_PROGRAMA_REGISTRO VARCHAR(5), CD_FORMULARIO VARCHAR(30) NOT NULL, CD_MUNICIPIO VARCHAR(50), CD_PROGRAMA_REGISTRO_DESTINO VARCHAR(5), DATA_INICIO VARCHAR(20), DATA_FIM VARCHAR(20));
INSERT INTO #PARAMETROS VALUES
(
'168' --Código fonto do programa.
,'1308' --Código do Subprograma. Informe NULL para não utilizar
,'M12.CONF1.001.F' --Código do formulário. -- não alterar
,'NULL' --Código do Município 
,NULL --Código do programa de destino. Informe NULL para não utilizar
,'2024-06-01 00:00:00'
,'2024-06-30 00:00:00'
);
IF OBJECT_ID('TEMPDB..#CD_AVALIACAO') IS NOT NULL DROP TABLE #CD_AVALIACAO
GO
CREATE TABLE #CD_AVALIACAO (CD_AVALIACAO VARCHAR(50) NOT NULL);
INSERT INTO #CD_AVALIACAO VALUES
('18531801');

IF OBJECT_ID('tempdb..#ESTADOS') IS NOT NULL DROP TABLE #ESTADOS 
GO
CREATE TABLE #ESTADOS (CD_ESTADO VARCHAR(20) NOT NULL);
INSERT INTO #ESTADOS VALUES  
-- ('16') --Amapá (AP)	
--,('52') --Goiás (GO)	
--,('21') --Maranhão (MA)	
--,('22') --Piauí (PI)	
--,('51') --Mato Grosso (MT)	
--,('25') --Paraíba (PB)	
--,('43')	--RIO GRANDE DO SUL
--,('27') --Alagoas
--,('28') --Sergipe
--,('35') --São Paulo
--,('15') --Pará (PA)	
--,('41') --Paraná (PR)	
--,('26') --Pernambuco (PE)
--,('17') --TOCANTINS
--,('29') --BAHIA
('24') --RIO GRANDE DO NORTE

DECLARE @FiltroTabela nvarchar(max) = 'CD_AVALIACAO IN (' + (SELECT STRING_AGG('''''' + CD_AVALIACAO + '''''',',') FROM #CD_AVALIACAO) + ')'
DECLARE @DataHoraMaiorOuIgual varchar(10) = CONVERT(varchar(10), GETDATE(), 103) --Formato final precisa ser: DD/MM/YYYY
DECLARE @cmd nvarchar(1000) = 'REPOSITORIO_PMCQD.dbo.opedpTabelaNome ''##TB_008'', ''dbo'', ''REPOSITORIO_mtd'', ' + (SELECT TOP 1 CD_PROGRAMA_REGISTRO FROM #PARAMETROS) + ', ''008'', ''' + @DataHoraMaiorOuIgual + ''', ''' + @FiltroTabela + ''''
EXEC sp_executesql @cmd
GO
IF OBJECT_ID('TEMPDB..#TB_008') IS NOT NULL DROP TABLE #TB_008
SELECT * INTO #TB_008 FROM ##TB_008
IF OBJECT_ID('TEMPDB..##TB_008') IS NOT NULL DROP TABLE ##TB_008


/*----------------------------------------*/

/*COMPARA A TABELA QUE FOI MANDADO OS AUDIOS COM A QUE FOI CORRIGIDO, PARA VER SER FOI TUDO CORRIGIDO*/
IF OBJECT_ID('TEMPDB..#SEQUENCIAL_COM_0') IS NOT NULL DROP TABLE #SEQUENCIAL_COM_0
SELECT NU_SEQUENCIAL AS CD_NU_SEQUENCIAL, RIGHT(CD_REGISTRO_CAED, CHARINDEX('-', REVERSE(CD_REGISTRO_CAED)) - 1) AS ultimo_sequencial_registro_caed
INTO #SEQUENCIAL_COM_0
FROM #TB_008  
WHERE CHARINDEX('-', REVERSE(CD_REGISTRO_CAED)) > 0 -- SE FOR MAIOR QUE ZERO QUER DIZ QUE O CARACTER '-' CONTEM NO CODIGO
	  AND RIGHT(CD_REGISTRO_CAED, CHARINDEX('-', REVERSE(CD_REGISTRO_CAED)) - 1) = '0'

/*----------------------------------------*/
IF OBJECT_ID('TEMPDB..#PPT') IS NOT NULL DROP TABLE #PPT
SELECT 
    SUBSTRING(
        cd_registro_caed, 
        CHARINDEX('-', cd_registro_caed) + 1, 
        CHARINDEX('-', cd_registro_caed, CHARINDEX('-', cd_registro_caed) + 1) - CHARINDEX('-', cd_registro_caed) - 1
    ) AS ValorDesejado,
	NU_SEQUENCIAL AS CD_NU_SEQUENCIAL
INTO #PPT
FROM #TB_008 WHERE CHARINDEX('-', REVERSE(CD_REGISTRO_CAED)) > 0 -- SE FOR MAIOR QUE ZERO QUER DIZ QUE O CARACTER '-' CONTEM NO CODIGO
	  AND RIGHT(CD_REGISTRO_CAED, CHARINDEX('-', REVERSE(CD_REGISTRO_CAED)) - 1) = '0'

IF OBJECT_ID('TEMPDB..#PALAVRA') IS NOT NULL DROP TABLE #PALAVRA
SELECT CD_CAMPO_001 AS PALAVRA
INTO #PALAVRA
FROM PARC_2024_ENTRADA.dbo.ARQ_IN_011_D_1308_20240618162307_000000086
WHERE CD_AVALIACAO IN (SELECT CD_AVALIACAO FROM #CD_AVALIACAO)

IF OBJECT_ID('TEMPDB..#PSEUDOPALAVRA') IS NOT NULL DROP TABLE #PSEUDOPALAVRA
SELECT CD_CAMPO_002 AS PSEUDOPALAVRA
INTO #PSEUDOPALAVRA
FROM PARC_2024_ENTRADA.dbo.ARQ_IN_011_D_1308_20240618162307_000000086
WHERE CD_AVALIACAO IN (SELECT CD_AVALIACAO FROM #CD_AVALIACAO)

IF OBJECT_ID('TEMPDB..#TEXTO') IS NOT NULL DROP TABLE #TEXTO
SELECT CD_CAMPO_003 AS TEXTO
INTO #TEXTO
FROM PARC_2024_ENTRADA.dbo.ARQ_IN_011_D_1308_20240618162307_000000086
WHERE CD_AVALIACAO IN (SELECT CD_AVALIACAO FROM #CD_AVALIACAO)

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*######--------------------------------------------------------------RELATORIOS-------------------------------------------------------------------##########*/
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------*/

/* -------------------------------------------------------------------------------------------------------------PARA VER SE HÁ ALGUMA CORREÇÃO PENDENTE DA IA*/
SELECT DISTINCT
	A.CD_REGISTRO_CAED, A.CD_ITEM, A.DT_SOLICITACAO
FROM 
	PARC_2024_ENTRADA.dbo.MANTER_1308_1853_PARC_AUDIOS_IA A -- AUDIOS QUE FORAM MANDADOS
LEFT JOIN #PPT B
	ON A.CD_REGISTRO_CAED = B.CD_NU_SEQUENCIAL
	AND A.CD_ITEM = B.ValorDesejado
WHERE 
A.DT_SOLICITACAO >= (SELECT DATA_INICIO FROM #PARAMETROS) AND -- CASO PRECISE DE BUSCAR POR ALGUMA DATA  
B.CD_NU_SEQUENCIAL IS NULL
ORDER BY A.DT_SOLICITACAO ASC

--CD_REGISTRO_CAED NOT IN(SELECT top 10 * from #PPT)
---- or cd_item NOT IN(SELECT ValorDesejado from #PPT)

/* -------------------------------------------------------------------------------------------------------------QTDE DE AUDIO POR DATA*/
SELECT DT_SOLICITACAO, COUNT(*) AS Quantidade_Audios_Enviados
FROM PARC_2024_ENTRADA.dbo.MANTER_1308_1853_PARC_AUDIOS_IA
WHERE DT_SOLICITACAO >= (SELECT DATA_INICIO FROM #PARAMETROS)
GROUP BY DT_SOLICITACAO
ORDER BY DT_SOLICITACAO;

/* -------------------------------------------------------------------------------------------------------------PARA VER O ULTIMO AUDIO MANDADO PARA CORREÇÃO E A QTDE*/
-- Consulta 1
SELECT 
    COUNT(dt_solicitação) AS QTDE_DE_AUDIOS,
    MAX(dt_solicitacao) AS DATA_ULTIMO_DIA_MANDADO_PARA_IA
FROM 
    PARC_2024_ENTRADA.dbo.MANTER_1308_1853_PARC_AUDIOS_IA
WHERE
    dt_solicitação >= (SELECT DATA_INICIO FROM #PARAMETROS) 
	AND 
	dt_solicitação <= (SELECT DATA_FIM FROM #PARAMETROS);

/* -------------------------------------------------------------------------------------------------------------PARA VER A QTDE DE PALAVRA, PSEUDOPALAVRA, TEXTO*/
SELECT 'PALAVRA' AS TIPO, COUNT(CD_ITEM) AS CONTAGEM
FROM PARC_2024_ENTRADA.dbo.MANTER_1308_1853_PARC_AUDIOS_IA 
WHERE CD_ITEM IN (SELECT PALAVRA FROM #PALAVRA)
AND dt_solicitação >= (SELECT DATA_INICIO FROM #PARAMETROS) 
AND dt_solicitação <= (SELECT DATA_FIM FROM #PARAMETROS)

UNION ALL

SELECT 'PSEUDOPALAVRA' AS TIPO, COUNT(CD_ITEM) AS CONTAGEM
FROM PARC_2024_ENTRADA.dbo.MANTER_1308_1853_PARC_AUDIOS_IA 
WHERE CD_ITEM IN (SELECT PSEUDOPALAVRA FROM #PSEUDOPALAVRA)
AND dt_solicitação >= (SELECT DATA_INICIO FROM #PARAMETROS) 
AND dt_solicitação <= (SELECT DATA_FIM FROM #PARAMETROS)

UNION ALL

SELECT 'TEXTO' AS TIPO, COUNT(CD_ITEM) AS CONTAGEM
FROM PARC_2024_ENTRADA.dbo.MANTER_1308_1853_PARC_AUDIOS_IA 
WHERE CD_ITEM IN (SELECT TEXTO FROM #TEXTO)
AND dt_solicitação >= (SELECT DATA_INICIO FROM #PARAMETROS) 
AND dt_solicitação <= (SELECT DATA_FIM FROM #PARAMETROS)




