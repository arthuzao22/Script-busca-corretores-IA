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
CREATE TABLE #PARAMETROS (CD_FONTE_REGISTRO VARCHAR(5) NOT NULL, CD_PROGRAMA_REGISTRO VARCHAR(5), CD_FORMULARIO VARCHAR(30) NOT NULL, CD_MUNICIPIO VARCHAR(50), CD_PROGRAMA_REGISTRO_DESTINO VARCHAR(5));
INSERT INTO #PARAMETROS VALUES
(
'168' --Código fonto do programa.
,'1308' --Código do Subprograma. Informe NULL para não utilizar
,'M12.CONF1.001.F' --Código do formulário. -- não alterar
,'NULL' --Código do Município 
,NULL --Código do programa de destino. Informe NULL para não utilizar
);
IF OBJECT_ID('TEMPDB..#CD_AVALIACAO') IS NOT NULL DROP TABLE #CD_AVALIACAO
GO
CREATE TABLE #CD_AVALIACAO (CD_AVALIACAO VARCHAR(50) NOT NULL);
INSERT INTO #CD_AVALIACAO VALUES
('18531801');

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

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*######--------------------------------------------------------------RELATORIOS-------------------------------------------------------------------##########*/
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------*/

/* -------------------------------------------------------------------------------------------------------------PARA VER SE HÁ ALGUMA CORREÇÃO PENDENTE DA IA*/
SELECT 
	CD_REGISTRO_CAED
FROM 
	REPOSITORIO_PMCQD.csv.MANTER_1308_1853_PARC_AUDIOS_IA -- AUDIOS QUE FORAM MANDADOS
WHERE 
	CD_REGISTRO_CAED NOT IN(SELECT CD_NU_SEQUENCIAL from #SEQUENCIAL_COM_0);

/* -------------------------------------------------------------------------------------------------------------PARA VER O ULTIMO AUDIO MANDADO PARA CORREÇÃO E A QTDE*/
DECLARE @data_inicio DATETIME;
DECLARE @data_fim DATETIME;
-- MUDAR O PERIODO QUE VOCE QUER SABER DA QTDE DE AUDIOS FORAM ENVIADOS
SET @data_inicio = '2024-06-01 00:00:00';
SET @data_fim = '2024-06-30 23:59:59';
select 
	count(dt_solicitação) as QTDE_DE_AUDIOS,
	max(dt_solicitacao) as DATA_ULTIMO_DIA_MANDADO_PARA_IA
from 
	REPOSITORIO_PMCQD.csv.MANTER_1308_1853_PARC_AUDIOS_IA
WHERE
	dt_solicitação > @data_inicio AND dt_solicitação < @data_fim 

/* -------------------------------------------------------------------------------------------------------------PARA VER PALAVRAS, PSEUDOPALAVRAS E TEXTO*/
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
GO
-- FALTA RELACIONAR O 011 PARA SABER QTS PALAVARAS PSEUDO E TEXTO TEMOS 
SELECT * FROM
REPOSITORIO_MTD.[dbo].[MANTER_ARQ_IN_011_D_1308_20240315162710_000000086]
WHERE CD_AVALIACAO IN (SELECT CD_AVALIACAO FROM #CD_AVALIACAO)