DECLARE @closeDateMS Date;
SET @closeDateMS = (SELECT TOP 1 Audit_EndDate FROM GlobalVariables)

-----Vendor - Maintenance Solutions------
;WITH 
Q1 AS (
	SELECT  Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, Pk_MyEntityID, MyEntity, SUM(AmountCr - AmountDr) AS Balance
	FROM SolutionsDB.dbo.Audit
	GROUP BY Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, Pk_MyEntityID, MyEntity
	HAVING Pk_AccountID = 366	--366 = Vendor - Maintenance Solutions
)
SELECT Q1.Pk_SubAccountID, Q1.SubAccount, Q1.SubAccountCombID, Q1.Pk_AccountID, Q1.Account, Pk_MyEntityID, MyEntity, -(Balance) AS Balance,
		Account.Pk_AccountID AS Pk_AccountContra, Account.Account AS AccountContra, SubAccount.Pk_SubAccountID AS Pk_AccountSubContra, SubAccount.SubAccount AS AccountSubContra INTO #TempTblBalancesMS
FROM Q1 LEFT JOIN SubAccount ON Q1.SubAccountCombID = SubAccount.SubAccountCombID
		LEFT JOIN Account ON SubAccount.Fk_AccountID = Account.Pk_AccountID
WHERE Balance < 0 AND Account.Pk_AccountID = 8
ORDER BY Balance


--select * from #TempTblBalancesMS

--SourceDoc
INSERT INTO SourceDoc(Import_OldStatementType, Import_OldStatementPk, DocDate, Fk_SourceDocTypeID, Description, ImportQ)
SELECT 'SQLScript_CloseVendorMS_SD' AS Import_OldStatementType, Pk_SubAccountID AS Import_OldStatementPk, @closeDateMS AS DocDate, 10 AS Fk_SourceDocTypeID, 
		'Closing Entry' AS Description, 'SQLScript_CloseVendorMS_SD' AS ImportQ
FROM #TempTblBalancesMS


--LineItem
INSERT INTO LineItem(Fk_LineItemTypeID, Fk_SourceDocID, Description, Fk_SubAccount_Dr, Fk_SubAccount_Cr, Amount, GroupOnMonth, GroupOnYear, ImportQ)
SELECT 36 AS Fk_LineItemTypeID, Pk_SourceDocID AS Fk_SourceDocID, 'Closing Entry' AS Description, #TempTblBalancesMS.Pk_AccountSubContra AS Fk_SubAccount_Dr, #TempTblBalancesMS.Pk_SubAccountID AS Fk_SubAccount_Cr, 
		#TempTblBalancesMS.Balance AS Amount, MONTH(@closeDateMS) AS GroupOnMonth, YEAR(@closeDateMS) AS GroupOnYear, 'SQLScript_CloseVendorMS_LI' AS ImportQ
FROM #TempTblBalancesMS LEFT JOIN SourceDoc ON #TempTblBalancesMS.Pk_SubAccountID = SourceDoc.Import_OldStatementPk
WHERE SourceDoc.Import_OldStatementType = 'SQLScript_CloseVendorMS_SD'

DROP TABLE #TempTblBalancesMS