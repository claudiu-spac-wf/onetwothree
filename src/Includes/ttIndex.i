define {&1} temp-table ttIndex no-undo
  field IndexGuid as character
  field TableGuid as character
  field IndexName as character
  index idxIndexGuid is unique IndexGuid
  index idxIndexName is primary unique TableGuid IndexName.