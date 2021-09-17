--closing entries
--RemoveOld
DELETE FROM LineItem
WHERE ImportQ = 'dbo_Audit_Closing_LineItem'
DELETE FROM SourceDoc
WHERE ImportQ = 'dbo_Audit_Closing_SourceDoc'

DELETE FROM LineItem
WHERE ImportQ = 'SQLScript_CloseVendorMS_LI'
DELETE FROM SourceDoc
WHERE ImportQ = 'SQLScript_CloseVendorMS_SD'

DELETE FROM LineItem
WHERE ImportQ = 'SQLScript_CloseVendorPS_LI'
DELETE FROM SourceDoc
WHERE ImportQ = 'SQLScript_CloseVendorPS_SD'

