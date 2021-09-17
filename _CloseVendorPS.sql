DECLARE @closeDatePS Date;
SET @closeDatePS = (SELECT TOP 1 Audit_EndDate FROM GlobalVariables)

-----Vendor - Property Solutions------
;WITH 
Q1 AS (
	SELECT  Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, Pk_MyEntityID, MyEntity, SUM(AmountCr - AmountDr) AS Balance
	FROM SolutionsDB.dbo.Audit
	GROUP BY Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, Pk_MyEntityID, MyEntity
	HAVING Pk_AccountID = 8	--8 = Vendor - Property Solutions
)
SELECT Q1.Pk_SubAccountID, Q1.SubAccount, Q1.SubAccountCombID, Q1.Pk_AccountID, Q1.Account, Pk_MyEntityID, MyEntity, -(Balance) AS Balance,
		Account.Pk_AccountID AS Pk_AccountContra, Account.Account AS AccountContra, SubAccount.Pk_SubAccountID AS Pk_AccountSubContra, SubAccount.SubAccount AS AccountSubContra INTO #TempTblBalancesPS
FROM Q1 LEFT JOIN SubAccount ON Q1.SubAccountCombID = SubAccount.SubAccountCombID
		LEFT JOIN Account ON SubAccount.Fk_AccountID = Account.Pk_AccountID
WHERE Balance < 0 AND Account.Pk_AccountID = 366
ORDER BY Balance


--select * from #TempTblBalancesPS

--SourceDoc
INSERT INTO SourceDoc(Import_OldStatementType, Import_OldStatementPk, DocDate, Fk_SourceDocTypeID, Description, ImportQ)
SELECT 'SQLScript_CloseVendorPS_SD' AS Import_OldStatementType, Pk_SubAccountID AS Import_OldStatementPk, @closeDatePS AS DocDate, 10 AS Fk_SourceDocTypeID, 
		'Closing Entry' AS Description, 'SQLScript_CloseVendorPS_SD' AS ImportQ
FROM #TempTblBalancesPS


--LineItem
INSERT INTO LineItem(Fk_LineItemTypeID, Fk_SourceDocID, Description, Fk_SubAccount_Dr, Fk_SubAccount_Cr, Amount, GroupOnMonth, GroupOnYear, ImportQ)
SELECT 36 AS Fk_LineItemTypeID, Pk_SourceDocID AS Fk_SourceDocID, 'Closing Entry' AS Description, #TempTblBalancesPS.Pk_AccountSubContra AS Fk_SubAccount_Dr, #TempTblBalancesPS.Pk_SubAccountID AS Fk_SubAccount_Cr, 
		#TempTblBalancesPS.Balance AS Amount, MONTH(@closeDatePS) AS GroupOnMonth, YEAR(@closeDatePS) AS GroupOnYear, 'SQLScript_CloseVendorPS_LI' AS ImportQ
FROM #TempTblBalancesPS LEFT JOIN SourceDoc ON #TempTblBalancesPS.Pk_SubAccountID = SourceDoc.Import_OldStatementPk
WHERE SourceDoc.Import_OldStatementType = 'SQLScript_CloseVendorPS_SD'

DROP TABLE #TempTblBalancesPS

