USE SolutionsDB
GO

DELETE FROM Audit
DBCC CHECKIDENT (Audit, RESEED, 0)
GO

DECLARE @startDate AS datetime --SET @startDate = CONVERT(datetime, '2019-03-01')	
    DECLARE @endDate AS datetime --SET @endDate = CONVERT(datetime, '2020-02-28')	
DECLARE @description AS varchar(50) --SET @description = 'Opening Balance'
--set varialbes
SELECT TOP 1
    @startDate = Audit_StartDate,
    @endDate = Audit_EndDate,
	@description = Audit_DescrptOpenBal
FROM GlobalVariables
/*PRINT @startDate
PRINT @endDate
PRINT @description*/

INSERT INTO Audit
--Opening balance
SELECT 0 AS Pk_AuditID_0, 0 AS Pk_AuditID_1, 0 AS Pk_AuditID_2_1, 0 AS Pk_AuditID_2_2, 0 AS Pk_AuditID_3, - 1 AS Pk_LineItemID, - 1 AS Pk_LineItemTypeID, 
			@description AS LineItemType, - 1 AS Pk_SourceDocID, @startDate AS DocDate, 
			CONCAT(YEAR(@startDate), '-', CASE WHEN MONTH(@startDate) < 10 THEN '0' ELSE '' END, MONTH(@startDate)) AS YearMonth,
			YEAR(@startDate) AS Year, MONTH(@startDate) AS Month, YEAR(@startDate) AS GroupOnYear, MONTH(@startDate) AS GroupOnMonth1, 
            - 1 AS PK_SourceDocTypeID, @description AS SourceDocType, @description AS SourceDocDescription, @description AS LineItemDescription, 
			SubAccount.Pk_SubAccountID, SubAccount.SubAccount, SubAccount.SubAccountCombID, Account.Pk_AccountID, Account.Account, 
			CASE WHEN AccountType.Pk_AccountTypeID = 0 THEN 'Asset' ELSE 'Equity/Liability' END AS AccountTypeGroupTrialBal, AccountType.Pk_AccountTypeID, 
            AccountType.AccountType, Entity.Pk_EntityID AS Pk_MyEntityID, Entity.Name AS MyEntity, 
			SUM(View_LineItemAmountDrCr.AmountDr) AS AmountDr, SUM(View_LineItemAmountDrCr.AmountCr) AS AmountCr, SUM(View_LineItemAmountDrCr.Balance_Dynamic) AS Balance, 
			(SUM(View_LineItemAmountDrCr.AmountCr)-SUM(View_LineItemAmountDrCr.AmountDr)) AS Balance_Cashflow, -1 AS Pk_SubAccountID_Contra, '' AS SubAccount_Contra, 
			'' AS SubAccountCombID_Contra, - 1 AS Pk_AccountID_Contra, '' AS Account_Contra, - 1 AS Pk_MyEntityID_Contra, '' AS MyEntity_Contra, 
			LineItemType.CashflowEntry, @description AS LineItemImportQ, @description AS SourceDocImportQ, 
			0 AS RunningTotal_0,  0 AS RunningTotal_1,  0 AS RunningTotal_2_1,  0 AS RunningTotal_2_2,  0 AS RunningTotal_3
FROM View_LineItemAmountDrCr INNER JOIN
		 LineItemType ON View_LineItemAmountDrCr.Fk_LineItemTypeID = LineItemType.Pk_LineItemTypeID INNER JOIN
		 SubAccount ON View_LineItemAmountDrCr.Fk_SubAccountID = SubAccount.Pk_SubAccountID INNER JOIN
		 Account ON SubAccount.Fk_AccountID = Account.Pk_AccountID INNER JOIN
		 AccountType ON SubAccount.Fk_AccountTypeID_Dynamic = AccountType.Pk_AccountTypeID INNER JOIN
		 Entity ON Account.Fk_MyEntityID = Entity.Pk_EntityID
WHERE  View_LineItemAmountDrCr.DocDate < @startDate
GROUP BY Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, Pk_AccountTypeID, AccountType, 
		  Pk_EntityID, Entity.Name, LineItemType.CashflowEntry

UNION ALL

--Data Section (Non Opening balance)
SELECT 0 AS Pk_AuditID_1, 0 AS Pk_AuditID_1, 0 AS Pk_AuditID_2_1, 0 AS Pk_AuditID_2_2, 0 AS Pk_AuditID_3, View_LineItemAmountDrCr.Pk_LineItemID, LineItemType.Pk_LineItemTypeID, LineItemType.LineItemType, SourceDoc.Pk_SourceDocID, SourceDoc.DocDate, 
				  CONCAT(YEAR(SourceDoc.DocDate), '-', CASE WHEN MONTH(SourceDoc.DocDate) < 10 THEN '0' ELSE '' END, MONTH(SourceDoc.DocDate)) AS YearMonth,
				  YEAR(SourceDoc.DocDate) AS Year, MONTH(SourceDoc.DocDate) AS Month, 
                  View_LineItemAmountDrCr.GroupOnYear, View_LineItemAmountDrCr.GroupOnMonth, SourceDocType.PK_SourceDocTypeID, SourceDocType.SourceDocType, SourceDoc.Description AS SourceDocDescription, 
                  View_LineItemAmountDrCr.Description AS LineItemDescription, SubAccount.Pk_SubAccountID, SubAccount.SubAccount, SubAccount.SubAccountCombID, Account.Pk_AccountID, Account.Account, 
				  CASE WHEN AccountType.Pk_AccountTypeID = 0 THEN 'Asset' ELSE 'Equity/Liability' END AS AccountTypeGroupTrialBal, AccountType.Pk_AccountTypeID, 
                  AccountType.AccountType, Entity.Pk_EntityID AS Pk_MyEntity, Entity.Name AS MyEntity, View_LineItemAmountDrCr.AmountDr, View_LineItemAmountDrCr.AmountCr, 
				  View_LineItemAmountDrCr.Balance_Dynamic, (View_LineItemAmountDrCr.AmountCr-View_LineItemAmountDrCr.AmountDr) AS Balance_Cashflow, SubAccount2.Pk_SubAccountID AS Pk_SubAccountID_Contra, SubAccount2.SubAccount AS SubAccount_Contra, 
                  SubAccount2.SubAccountCombID AS SubAccountCombID_Contra, Account2.Pk_AccountID AS Pk_AccountID_Contra, Account2.Account AS Account_Contra, Entity2.Pk_EntityID AS Pk_MyEntityID_Contra, 
                  Entity2.Name AS MyEntity_Contra, LineItemType.CashflowEntry, View_LineItemAmountDrCr.ImportQ_LineItem AS LineItemImportQ, SourceDoc.ImportQ AS SourceDocImportQ, 0 AS RunningTotal_0,  0 AS RunningTotal_1,  0 AS RunningTotal_2_1,  0 AS RunningTotal_2_2,  0 AS RunningTotal_3
FROM     View_LineItemAmountDrCr INNER JOIN
                  LineItemType ON View_LineItemAmountDrCr.Fk_LineItemTypeID = LineItemType.Pk_LineItemTypeID INNER JOIN
                  SourceDoc ON View_LineItemAmountDrCr.Fk_SourceDocID = SourceDoc.Pk_SourceDocID INNER JOIN
                  SourceDocType ON SourceDoc.Fk_SourceDocTypeID = SourceDocType.PK_SourceDocTypeID INNER JOIN
				  SubAccount ON View_LineItemAmountDrCr.Fk_SubAccountID = SubAccount.Pk_SubAccountID INNER JOIN
                  AccountType ON SubAccount.Fk_AccountTypeID_Dynamic = AccountType.Pk_AccountTypeID INNER JOIN
				  Account ON SubAccount.Fk_AccountID = Account.Pk_AccountID INNER JOIN
				  Entity ON Account.Fk_MyEntityID = Entity.Pk_EntityID INNER JOIN
                  SubAccount AS SubAccount2 ON View_LineItemAmountDrCr.Fk_SubAccountContraID = SubAccount2.Pk_SubAccountID INNER JOIN
                  Account AS Account2 ON SubAccount2.Fk_AccountID = Account2.Pk_AccountID INNER JOIN
				  Entity AS Entity2 ON Account2.Fk_MyEntityID = Entity2.Pk_EntityID
WHERE  (SourceDoc.DocDate BETWEEN @startDate AND @endDate)
--ORDER BY MyEntity, AccountTypeGroupTrialBal, Account, SubAccount, DocDate, LineItemType, SourceDocType, Pk_LineItemID
--SELECT * FROM Audit

--Remove Dr R0.00 & Cr R0.00 rows (empty rows)
DELETE Audit 
WHERE AmountDr = 0 AND AmountCr = 0

/*
-----Running Totals--------
--Update Running Total_Account_0
UPDATE AUDIT
SET Audit.RunningTotal_0 = T.RunningTotal_0
FROM (SELECT Pk_MyEntityID, Pk_AccountID, Pk_SubAccountID, DocDate, Pk_AuditID_0, Balance,
				SUM(Balance) OVER(PARTITION BY Pk_MyEntityID, Pk_AccountID, Pk_SubAccountID ORDER BY Pk_MyEntityID, Pk_AccountID, Pk_SubAccountID, DocDate, Pk_AuditID_0 rows unbounded preceding) as RunningTotal_0
	  FROM Audit) AS T INNER JOIN 
	 Audit ON Audit.Pk_AuditID_0 = T.Pk_AuditID_0
*/

--Update Audit Pk's
;WITH 
Q1 AS (
	SELECT ID, 
		   SUM(1) OVER (ORDER BY MyEntity, AccountTypeGroupTrialBal, AccountType, Account, SubAccount, DocDate, LineItemType, SourceDocType, Pk_LineItemID rows unbounded preceding) as Pk_AuditID_0,
		   SUM(1) OVER (ORDER BY MyEntity, Account, AccountType, SubAccount, DocDate, LineItemType, SourceDocType, Pk_LineItemID rows unbounded preceding) as Pk_AuditID_1,
		   SUM(1) OVER (ORDER BY MyEntity, SubAccount, AccountType, Account, DocDate, LineItemType, SourceDocType, Pk_LineItemID rows unbounded preceding) as Pk_AuditID_2_1,		   
		   SUM(1) OVER (ORDER BY MyEntity, SubAccount, DocDate, AccountType, Account, LineItemType, SourceDocType, Pk_LineItemID rows unbounded preceding) as Pk_AuditID_2_2
		   --SUM(1) OVER (ORDER BY MyEntity, Account, AccountType, SubAccount, DocDate, LineItemType, SourceDocType, Pk_LineItemID rows unbounded preceding) as Pk_AuditID_3
	FROM Audit
)
UPDATE Audit
SET Audit.Pk_AuditID_0 = Q1.Pk_AuditID_0, Audit.Pk_AuditID_1 = Q1.Pk_AuditID_1, Audit.Pk_AuditID_2_1 = Q1.Pk_AuditID_2_1, Audit.Pk_AuditID_2_2 = Q1.Pk_AuditID_2_2
FROM Q1 INNER JOIN
	 Audit ON Q1.ID = Audit.ID

--Update Running Total_SubAccount
;WITH 
Q1 AS (
	SELECT ID,
		   SUM(Balance) OVER(PARTITION BY MyEntity, AccountTypeGroupTrialBal, AccountType, Account, SubAccount ORDER BY Pk_AuditID_0 rows unbounded preceding) as RunningTotal_0,
		   SUM(Balance) OVER(PARTITION BY MyEntity, Account, AccountType, SubAccount ORDER BY Pk_AuditID_1 rows unbounded preceding) as RunningTotal_1,
		   SUM(Balance) OVER(PARTITION BY MyEntity, SubAccount, AccountType, Account ORDER BY Pk_AuditID_2_1 rows unbounded preceding) as RunningTotal_2_1,
		   SUM(Balance) OVER(PARTITION BY MyEntity, SubAccount ORDER BY Pk_AuditID_2_2 rows unbounded preceding) as RunningTotal_2_2
		   --SUM(Balance) OVER(PARTITION BY MyEntity, AccountTypeGroupTrialBal, AccountType, Account, SubAccount ORDER BY Pk_AuditID_3 rows unbounded preceding) as RunningTotal_3
	FROM Audit
)
UPDATE Audit
SET Audit.RunningTotal_0 = Q1.RunningTotal_0, Audit.RunningTotal_1 = Q1.RunningTotal_1, Audit.RunningTotal_2_1 = Q1.RunningTotal_2_1, Audit.RunningTotal_2_2 = Q1.RunningTotal_2_2
FROM Q1 INNER JOIN 
	 Audit ON Audit.ID = Q1.ID


--Replace the description's null & '' values with a space (so that the excel pivot is more pretty:)
UPDATE Audit
SET Audit.LineItemDescription = CASE WHEN Audit.LineItemDescription IS NULL OR Audit.LineItemDescription = '' THEN ' ' ELSE Audit.LineItemDescription END,
	Audit.SourceDocDescription = CASE WHEN Audit.SourceDocDescription IS NULL OR Audit.SourceDocDescription = '' THEN ' ' ELSE Audit.SourceDocDescription END





/*
--Update Pk_AuditID_BySubAccount
UPDATE Audit
SET Pk_AuditID_1 = t.Pk_AuditID_BySubAccount
FROM (SELECT SUM(1) OVER (ORDER BY Pk_MyEntityID, Pk_SubAccountID, Pk_AccountID, DocDate, Pk_AuditID_ByAccount rows unbounded preceding) as Pk_AuditID_BySubAccount, Pk_AuditID_ByAccount
	  FROM Audit) AS t INNER JOIN
		Audit ON t.Pk_AuditID_ByAccount = Audit.Pk_AuditID_ByAccount

--Update Running Total_SubAccount
UPDATE Audit
SET Audit.RunningTotal_BySubAccount = T.RunningTotal_BySubAccount, Audit.Pk_AuditID_BySubAccount = T.Pk_AuditID_BySubAccount
FROM (SELECT Pk_AuditID_BySubAccount, Pk_MyEntityID, Pk_SubAccountID, Pk_AccountID, DocDate, Pk_LineItemID, Balance,
				SUM(Balance) OVER(PARTITION BY Pk_MyEntityID, Pk_SubAccountID, Pk_AccountID ORDER BY Pk_MyEntityID, Pk_SubAccountID, Pk_AccountID, DocDate, Pk_AuditID_BySubAccount rows unbounded preceding) as RunningTotal_BySubAccount
	  FROM Audit) AS T INNER JOIN 
	 Audit ON Audit.Pk_AuditID_BySubAccount = T.Pk_AuditID_BySubAccount

SELECT *
FROM Audit
*/