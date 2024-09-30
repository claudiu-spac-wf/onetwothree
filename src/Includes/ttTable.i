define {&1} temp-table ttTable no-undo
  field TableGuid    as character
  field DatabaseGuid as character
  field TableName    as character
  index idxTableGuid is unique             TableGuid
  index idxDatabaseTable is primary unique DatabaseGuid TableName.