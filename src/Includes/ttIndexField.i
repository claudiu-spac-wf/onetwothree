define {&1} temp-table ttIndexField no-undo
  field IndexFieldGuid      as character
  field IndexGuid           as character
  field FieldName           as character
  field FieldOrder          as integer
  field IsLastOfUniqueIndex as logical
  field DataType            as character
  index idxIndexField is unique           IndexFieldGuid
  index idxFieldOfIndex is primary unique IndexGuid      FieldOrder FieldName.