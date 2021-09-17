--Backup the Audit table to the AuditBackup table
INSERT INTO AuditBackup
                  (ID, Pk_AuditID_0, Pk_AuditID_1, Pk_AuditID_2_1, Pk_AuditID_2_2, Pk_AuditID_3, Pk_LineItemID, Pk_LineItemTypeID, LineItemType, Pk_SourceDocID, DocDate, YearMonth, Year, Month, GroupOnYear, GroupOnMonth, 
                  PK_SourceDocTypeID, SourceDocType, SourceDocDescription, LineItemDescription, Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, AccountTypeGroupTrialBal, Pk_AccountTypeID, AccountType, 
                  Pk_MyEntityID, MyEntity, AmountDr, AmountCr, Balance, Balance_Cashflow, Pk_SubAccountID_Contra, SubAccount_Contra, SubAccountCombID_Contra, Pk_AccountID_Contra, Account_Contra, Pk_MyEntityID_Contra, MyEntity_Contra, 
                  CashflowItem, LineItemImportQ, SourceDocImportQ, RunningTotal_0, RunningTotal_1, RunningTotal_2_1, RunningTotal_2_2, RunningTotal_3)
SELECT ID, Pk_AuditID_0, Pk_AuditID_1, Pk_AuditID_2_1, Pk_AuditID_2_2, Pk_AuditID_3, Pk_LineItemID, Pk_LineItemTypeID, LineItemType, Pk_SourceDocID, DocDate, YearMonth, Year, Month, GroupOnYear, GroupOnMonth, 
                  PK_SourceDocTypeID, SourceDocType, SourceDocDescription, LineItemDescription, Pk_SubAccountID, SubAccount, SubAccountCombID, Pk_AccountID, Account, AccountTypeGroupTrialBal, Pk_AccountTypeID, AccountType, 
                  Pk_MyEntityID, MyEntity, AmountDr, AmountCr, Balance, Balance_Cashflow, Pk_SubAccountID_Contra, SubAccount_Contra, SubAccountCombID_Contra, Pk_AccountID_Contra, Account_Contra, Pk_MyEntityID_Contra, MyEntity_Contra, 
                  CashflowItem, LineItemImportQ, SourceDocImportQ, RunningTotal_0, RunningTotal_1, RunningTotal_2_1, RunningTotal_2_2, RunningTotal_3
FROM     Audit