--closing entries
----RemoveOld
--DELETE FROM LineItem
--WHERE ImportQ = 'dbo_Audit_Closing_LineItem'
--DELETE FROM SourceDoc
--WHERE ImportQ = 'dbo_Audit_Closing_SourceDoc'

--InsertNew
--SourceDoc
INSERT INTO SourceDoc ( Import_OldStatementType, Import_OldStatementPkStr, Import_OldStatementPk, DocDate, Fk_SourceDocTypeID, Description, ImportQ, Fk_SourceDocID_Parent )
SELECT 'dbo_Audit_Closing', 0, Audit_Closing_LineItem.Pk_LineItemID, DocDate, Fk_SourceDocTypeID, Audit_Closing_SourceDoc.Description, 'dbo_Audit_Closing_SourceDoc', Fk_SourceDocID_Parent
FROM Audit_Closing_SourceDoc INNER JOIN Audit_Closing_LineItem ON Audit_Closing_SourceDoc.Pk_SourceDocID = Audit_Closing_LineItem.Fk_SourceDocID

--LineItem
INSERT INTO LineItem( Fk_LineItemTypeID, Fk_SourceDocID, Description, Fk_SubAccount_Dr, Fk_SubAccount_Cr, Amount, GroupOnMonth, GroupOnYear, ImportQ )
SELECT Fk_LineItemTypeID, Pk_SourceDocID, Audit_Closing_LineItem.Description, Fk_SubAccount_Dr, Fk_SubAccount_Cr, Amount, GroupOnMonth, GroupOnYear, 'dbo_Audit_Closing_LineItem'
FROM SourceDoc LEFT JOIN Audit_Closing_LineItem ON SourceDoc.Import_OldStatementPk = Audit_Closing_LineItem.Pk_LineItemID
WHERE Import_OldStatementType = 'dbo_Audit_Closing'
