define {&1} temp-table ttDatabase no-undo
  field DatabaseGuid as character
  field DatabaseName as character
  index idxDatabaseGuid is unique         DatabaseGuid
  index idxDatabaseName is primary unique DatabaseName.