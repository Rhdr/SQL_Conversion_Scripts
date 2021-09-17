USE SolutionsDB
GO

--Cleanup Old Closing entries (Remove Source Doc Entries)
DELETE FROM LineItem
WHERE ImportQ = 'SQLScript_ClosingEntryPS349'
GO
DELETE FROM SourceDoc
WHERE ImportQ = 'SQLScript_ClosingEntryPS349'
GO

----Close equity to retained earnings for < than given date----
DECLARE @startDate AS datetime --SET @startDate = CONVERT(datetime, '2019-03-01')	
    DECLARE @endDate AS datetime --SET @endDate = CONVERT(datetime, '2020-02-28')
--set varialbes
SELECT TOP 1
    @startDate = Audit_StartDate,
    @endDate = Audit_EndDate
FROM GlobalVariables
--PRINT @startDate
--PRINT @endDate


--Create Temp tbl to hold the SubAccount Balances (for all myEntities)
;WITH 
Q1 AS --Q1 Filter out DocDate
(
	SELECT Fk_SubAccountID, DocDate, AmountDr, AmountCr, (AmountDr - AmountCr) AS Balance
	FROM View_LineItemAmountDrCr
	WHERE DocDate < @startDate
)

, Q2 AS  --Sum & Group SubAccounts
(
	SELECT Fk_SubAccountID, SUM(AmountDr) AS AmountDr, SUM(AmountCr) AS AmountCr, SUM(Balance) AS Balance
	FROM Q1
	GROUP BY Fk_SubAccountID
)

, Q3 AS --Filter out Retained Earnings & Setup ContraSubAccount 
(
	SELECT NEWID() AS TempID, Account.Fk_MyEntityID, Fk_AccountTypeGroupID, Pk_AccountID, Account, Pk_SubAccountID, SubAccount, 
					CASE 
						WHEN Account.Fk_MyEntityID = 1 THEN 111 
						WHEN Account.Fk_MyEntityID = 4 THEN 83
						WHEN Account.Fk_MyEntityID = 9 THEN 85
						ELSE -1 
					END AS Pk_SubAccountID_ContraRetainedEarnings, --Select the appropriate Retained earnings subAccount for MyEntiy(Each bussiness)
					Q2.AmountDr, Q2.AmountCr, Q2.Balance
	FROM Q2 INNER JOIN
			SubAccount ON Q2.Fk_SubAccountID = SubAccount.Pk_SubAccountID INNER JOIN
			Account ON SubAccount.Fk_AccountID = Account.Pk_AccountID
	WHERE Account.Fk_AccountTypeGroupID = 2 AND NOT Pk_AccountID = 255 AND NOT Pk_AccountID = 363 AND NOT Pk_AccountID = 433--only show equity and not retained earnings
)	

, Q4 AS --Determine which SubAccount to Dr and which to Cr
(
	SELECT TempID, Fk_MyEntityID, Balance,
		CASE WHEN Balance > 0 THEN Pk_SubAccountID_ContraRetainedEarnings ELSE Pk_SubAccountID END AS Dr_SubAccountID, 
		CASE WHEN Balance <=  0 THEN Pk_SubAccountID_ContraRetainedEarnings ELSE Pk_SubAccountID END AS Cr_SubAccountID,
		ABS(Balance) AS Amount
	FROM Q3
	--order by Fk_MyEntityID
)
--Insert With block into a temp table (so that is can be referenced multiple times)
SELECT * 
INTO #TempSubAccountTotals
FROM Q4
--SELECT * FROM #TempSubAccountTotals


---PS & MS Closings Balances
--Create SourceDoc	
INSERT INTO SourceDoc (Import_OldStatementType, Import_OldStatementPk, DocDate, Fk_SourceDocTypeID, Description, ImportQ)
SELECT Import_OldStatementType = CONCAT('SQLScript_ClosingEntryPS349_', TempID), Import_OldStatementPk = 0, DocDate = DATEADD(D, -1, @startDate), Fk_SourceDocTypeID = 10, Description = 'Closing Entry',
ImportQ = 'SQLScript_ClosingEntryPS349'
FROM #TempSubAccountTotals
--WHERE #TempSubAccountTotals.Fk_MyEntityID = 1


--Create LineItem (Based on SourceDoc0
INSERT INTO LineItem (Fk_LineItemTypeID, Fk_SourceDocID, Description, Fk_SubAccount_Dr, Fk_SubAccount_Cr, Amount, GroupOnYear, GroupOnMonth, ImportQ)
SELECT '349' AS Fk_LineItemTypeID, Pk_SourceDocID, Description, #TempSubAccountTotals.Dr_SubAccountID, #TempSubAccountTotals.Cr_SubAccountID, 
		Amount, YEAR(@startDate), MONTH(@startDate), 'SQLScript_ClosingEntryPS349' AS ImportQ
FROM SourceDoc INNER JOIN
	  #TempSubAccountTotals ON SourceDoc.Import_OldStatementType = CONCAT('SQLScript_ClosingEntryPS349_', #TempSubAccountTotals.TempID) 
WHERE SourceDoc.Import_OldStatementType LIKE 'SQLScript_ClosingEntryPS349%'
--WHERE #TempSubAccountTotals.Fk_MyEntityID = 1 AND SourceDoc.Import_OldStatementType LIKE 'SQLScript_ClosingEntryPS349%'

/*
SELECT * FROM SourceDoc
WHERE ImportQ = 'SQLScript_ClosingEntryPS349'

SELECT * FROM LineItem
WHERE ImportQ = 'SQLScript_ClosingEntryPS349'
*/


--Cleanup temp table
IF OBJECT_ID('tempdb..#TempSubAccountTotals') IS NOT NULL -- Check for table existence
	BEGIN
	DROP TABLE #TempSubAccountTotals;
	--PRINT 'Temp tabel(#TempSubAccountTotals) deleted'
	END
