USE SolutionsDB
GO

DECLARE @startDate AS datetime --SET @startDate = CONVERT(datetime, '2019-03-01')	
    DECLARE @endDate AS datetime --SET @endDate = CONVERT(datetime, '2020-02-28')	
--set varialbes
SELECT TOP 1
    @startDate = Audit_StartDate,
    @endDate = Audit_EndDate
FROM GlobalVariables
--PRINT @startDate
--PRINT @endDate

--Clear LineItem Balances
UPDATE LineItem
SET Balance_Cr_Dynamic = NULL, Balance_Cr_Static = NULL, Balance_Dr_Dynamic = NULL, Balance_Dr_Static = NULL
--Update LineItem Balances
;WITH
Q1 AS(
	SELECT Pk_LineItemID, Account_Dr.Fk_AccountTypeID_Static AS Fk_AccountTypeID_Static_Dr, Account_Cr.Fk_AccountTypeID_Static AS Fk_AccountTypeID_Static_Cr,
			--Balance_Dr
				 --Case Asset
			CASE WHEN Account_Dr.Fk_AccountTypeID_Static = 0 THEN LineItem.Amount
				 --Case Not Asset
				 WHEN Account_Dr.Fk_AccountTypeID_Static != 0 THEN -(LineItem.Amount) END AS Balance_Dr,
			--Balance_Cr
				 --Case Asset
			CASE WHEN Account_Cr.Fk_AccountTypeID_Static = 0 THEN -(LineItem.Amount)
				 --Case Not Asset
				 WHEN Account_Cr.Fk_AccountTypeID_Static != 0 THEN LineItem.Amount END AS Balance_Cr
	FROM LineItem LEFT JOIN 
		 SourceDoc ON LineItem.Fk_SourceDocID = SourceDoc.Pk_SourceDocID LEFT JOIN
		 SubAccount AS SubAccount_Dr ON LineItem.Fk_SubAccount_Dr = SubAccount_Dr.Pk_SubAccountID LEFT JOIN
		 Account AS Account_Dr ON SubAccount_Dr.Fk_AccountID = Account_Dr.Pk_AccountID LEFT JOIN
		 SubAccount AS SubAccount_Cr ON LineItem.Fk_SubAccount_Cr = SubAccount_Cr.Pk_SubAccountID LEFT JOIN
		 Account AS Account_Cr ON SubAccount_Cr.Fk_AccountID = Account_Cr.Pk_AccountID
	WHERE DocDate <= @endDate
)
UPDATE LineItem
SET Balance_Dr_Static = Q1.Balance_Dr, LineItem.Fk_AccountTypeID_Static_Dr = Q1.Fk_AccountTypeID_Static_Dr, 
	Balance_Cr_Static = Q1.Balance_Cr, LineItem.Fk_AccountTypeID_Static_Cr = Q1.Fk_AccountTypeID_Static_Cr
FROM LineItem INNER JOIN
	 Q1 ON LineItem.Pk_LineItemID = Q1.Pk_LineItemID
/*
SELECT  SUM(Balance_Dr_Static) AS Balance_Dr_Static, SUM(Balance_Cr_Static) AS Balance_Cr_Static, 
		SUM(Balance_Dr_Dynamic) AS Balance_Dr_Dynamic, SUM(Balance_Cr_Dynamic) AS Balance_Cr_Dynamic
FROM LineItem
WHERE Fk_SubAccount_Dr = 13271 OR Fk_SubAccount_Cr = 13271
*/
--SELECT * FROM LineItem
--SELECT * FROM View_LineItemAmountDrCr

--Clear SubAccount Balances
UPDATE SubAccount
SET AmountDr = NULL, AmountCr = NULL, Balance_Static = NULL, Balance_Dynamic = NULL, Fk_AccountTypeID_Dynamic = NULL
--SELECT * FROM SubAccount

--Update SubAccount Balances
;WITH
Q1 AS(
	SELECT Fk_SubAccountID, Fk_AccountTypeID_Static, SUM(AmountDr) AS AmountDr_Static, SUM(AmountCr) AS AmountCr_Static, SUM(Balance_Static) AS Balance
	FROM View_LineItemAmountDrCr
	WHERE DocDate <= @endDate
	GROUP BY Fk_SubAccountID, Fk_AccountTypeID_Static
)
UPDATE SubAccount
SET SubAccount.Fk_AccountTypeID_Static = Q1.Fk_AccountTypeID_Static, SubAccount.AmountDr = Q1.AmountDr_Static, SubAccount.AmountCr = Q1.AmountCr_Static, 
SubAccount.Balance_Static = Q1.Balance
FROM Q1 INNER JOIN
	 SubAccount ON Q1.Fk_SubAccountID = SubAccount.Pk_SubAccountID
/*
SELECT * FROM SubAccount
WHERE Pk_SubAccountID = 13271
*/

--Update Dynamic SubAccount AccountTypes Accourding to Account Balances - Determine subAccount AccountTypes (Dynamic)
;WITH
Q1 AS(
	SELECT Pk_SubAccountID, SubAccount.AmountDr, SubAccount.AmountCr, SubAccount.Balance_Static, SubAccount.Fk_AccountTypeID_Static,
			--Case Asset
			CASE WHEN Account.Fk_AccountTypeID_Static = 0 AND SubAccount.Balance_Static < 0 THEN 2
				 --WHEN Account.Fk_AccountTypeID_Static = 0 AND SubAccount.Balance >= 0 THEN 0
			--Case Liability
				 --WHEN Account.Fk_AccountTypeID_Static = 2 AND SubAccount.Balance >= 0 THEN 2
				 WHEN Account.Fk_AccountTypeID_Static = 2 AND SubAccount.Balance_Static < 0 THEN 0
			--Case Equity Income
				 --WHEN Account.Fk_AccountTypeID_Static = 3 AND SubAccount.Balance >= 0 THEN 3
				 WHEN Account.Fk_AccountTypeID_Static = 3 AND SubAccount.Balance_Static < 0 THEN 4
			--Case Equity Expense
				 WHEN Account.Fk_AccountTypeID_Static = 4 AND SubAccount.Balance_Static > 0 THEN 3
				 --WHEN Account.Fk_AccountTypeID_Static = 4 AND SubAccount.Balance < 0 THEN 4
				 ELSE Account.Fk_AccountTypeID_Static END AS Fk_AccountTypeID_Dynamic
	FROM View_LineItemAmountDrCr INNER JOIN
			SubAccount ON View_LineItemAmountDrCr.Fk_SubAccountID = SubAccount.Pk_SubAccountID INNER JOIN
			Account ON SubAccount.Fk_AccountID = Account.Pk_AccountID --INNER JOIN
			--AccountTypeGroup ON Account.Fk_AccountTypeGroupID = AccountTypeGroup.Pk_AccountTypeGroupID
	WHERE SubAccount.FixedAccountTypeID = 0 AND DocDate <= @endDate
	GROUP BY Pk_SubAccountID, SubAccount.AmountDr, SubAccount.AmountCr, SubAccount.Balance_Static, 
			SubAccount.Fk_AccountTypeID_Static, Account.Fk_AccountTypeID_Static
), 

Q2 AS(
	SELECT Pk_SubAccountID, Fk_AccountTypeID_Dynamic,
			/*CASE WHEN Fk_AccountTypeID_Static!= Fk_AccountTypeID_Dynamic AND (Fk_AccountTypeID_Dynamic = 0) THEN   ABS(LineItem.Balance_Dr_Static)	--Asset DR +
			     WHEN Subaccount_Dr.Fk_AccountTypeID_Static != Subaccount_Dr.Fk_AccountTypeID_Dynamic AND (Subaccount_Dr.Fk_AccountTypeID_Dynamic = 2 OR Subaccount_Dr.Fk_AccountTypeID_Dynamic = 1 OR Subaccount_Dr.Fk_AccountTypeID_Dynamic = 3 OR Subaccount_Dr.Fk_AccountTypeID_Dynamic = 4) THEN -(ABS(LineItem.Balance_Dr_Static)) --Liability/Equity DR -
			     ELSE LineItem.Balance_Dr_Static END AS Balance_Dr_Dynamic,
			CASE WHEN Subaccount_Cr.Fk_AccountTypeID_Static != Subaccount_Cr.Fk_AccountTypeID_Dynamic AND (Subaccount_Cr.Fk_AccountTypeID_Dynamic = 0) THEN -(ABS(LineItem.Balance_Cr_Static))	--Asset CR -
			     WHEN Subaccount_Cr.Fk_AccountTypeID_Static != Subaccount_Cr.Fk_AccountTypeID_Dynamic AND (Subaccount_Cr.Fk_AccountTypeID_Dynamic = 2 OR Subaccount_Cr.Fk_AccountTypeID_Dynamic = 1 OR Subaccount_Cr.Fk_AccountTypeID_Dynamic = 3 OR Subaccount_Cr.Fk_AccountTypeID_Dynamic = 4) THEN   ABS(LineItem.Balance_Cr_Static) --Liability/Equity CR +
			     ELSE LineItem.Balance_Cr_Static END AS Balance_Cr_Dynamic8*/
			
			
			CASE WHEN Fk_AccountTypeID_Static != Fk_AccountTypeID_Dynamic /*AND Fk_AccountTypeID_Static != 3 AND Fk_AccountTypeID_Static != 4 AND Fk_AccountTypeID_Static != 1*/ THEN -(Balance_Static) 
				 ELSE Balance_Static END AS Balance_Dynamic
	FROM Q1
)
UPDATE SubAccount
Set SubAccount.Fk_AccountTypeID_Dynamic = Q2.Fk_AccountTypeID_Dynamic, SubAccount.Balance_Dynamic = Q2.Balance_Dynamic
FROM Q2 INNER JOIN
     SubAccount ON SubAccount.Pk_SubAccountID = Q2.Pk_SubAccountID
/*
SELECT * FROM SubAccount
WHERE Pk_SubAccountID = 13271
*/

--UPDATE LineItem Dynamic balances
--Dr
;WITH
Q1 AS (
	SELECT Pk_LineItemID, LineItem.Balance_Dr_Static, LineItem.Balance_Cr_Static,
			CASE WHEN Subaccount_Dr.Fk_AccountTypeID_Static != Subaccount_Dr.Fk_AccountTypeID_Dynamic AND (Subaccount_Dr.Fk_AccountTypeID_Dynamic = 0) THEN   ABS(LineItem.Balance_Dr_Static)	--Asset DR +
			     WHEN Subaccount_Dr.Fk_AccountTypeID_Static != Subaccount_Dr.Fk_AccountTypeID_Dynamic AND (Subaccount_Dr.Fk_AccountTypeID_Dynamic = 2 OR Subaccount_Dr.Fk_AccountTypeID_Dynamic = 1 OR Subaccount_Dr.Fk_AccountTypeID_Dynamic = 3 OR Subaccount_Dr.Fk_AccountTypeID_Dynamic = 4) THEN -(ABS(LineItem.Balance_Dr_Static)) --Liability/Equity DR -
			     ELSE LineItem.Balance_Dr_Static END AS Balance_Dr_Dynamic,
			CASE WHEN Subaccount_Cr.Fk_AccountTypeID_Static != Subaccount_Cr.Fk_AccountTypeID_Dynamic AND (Subaccount_Cr.Fk_AccountTypeID_Dynamic = 0) THEN -(ABS(LineItem.Balance_Cr_Static))	--Asset CR -
			     WHEN Subaccount_Cr.Fk_AccountTypeID_Static != Subaccount_Cr.Fk_AccountTypeID_Dynamic AND (Subaccount_Cr.Fk_AccountTypeID_Dynamic = 2 OR Subaccount_Cr.Fk_AccountTypeID_Dynamic = 1 OR Subaccount_Cr.Fk_AccountTypeID_Dynamic = 3 OR Subaccount_Cr.Fk_AccountTypeID_Dynamic = 4) THEN   ABS(LineItem.Balance_Cr_Static) --Liability/Equity CR +
			     ELSE LineItem.Balance_Cr_Static END AS Balance_Cr_Dynamic
	FROM LineItem INNER JOIN
		 SubAccount AS SubAccount_Dr ON LineItem.Fk_SubAccount_Dr = SubAccount_Dr.Pk_SubAccountID INNER JOIN
		 SubAccount AS SubAccount_Cr ON LineItem.Fk_SubAccount_Cr = SubAccount_Cr.Pk_SubAccountID
	--WHERE Fk_SubAccount_Dr = 13271 OR Fk_SubAccount_Cr = 13271
)
--SELECT SUM(Balance_Dr_Static) AS Balance_Dr_Static, SUM(Balance_Cr_Static) AS Balance_Cr_Static, 
--		SUM(Balance_Dr_Dynamic) AS Balance_Dr_Dynamic, SUM(Balance_Cr_Dynamic) AS Balance_Cr_Dynamic
--FROM Q1

UPDATE LineItem
SET LineItem.Balance_Dr_Dynamic = Q1.Balance_Dr_Dynamic, LineItem.Balance_Cr_Dynamic = Q1.Balance_Cr_Dynamic
FROM LineItem INNER JOIN
	 SourceDoc ON LineItem.Fk_SourceDocID = SourceDoc.Pk_SourceDocID INNER JOIN
	 Q1 ON LineItem.Pk_LineItemID = Q1.Pk_LineItemID
WHERE DocDate <= @endDate

--SELECT * FROM LineItem
/*
SELECT  SUM(Balance_Dr_Static) AS Balance_Dr_Static, SUM(Balance_Cr_Static) AS Balance_Cr_Static, 
		SUM(Balance_Dr_Dynamic) AS Balance_Dr_Dynamic, SUM(Balance_Cr_Dynamic) AS Balance_Cr_Dynamic
FROM LineItem
WHERE Fk_SubAccount_Dr = 13271 OR Fk_SubAccount_Cr = 13271
*/