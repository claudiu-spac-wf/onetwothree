define {&1} temp-table ttIndexData no-undo
  field IndexGuid      as character serialize-hidden
  field TableName      as character
  field IndexName      as character
  field IndexFields    as character
  field AverageRecords as decimal
  field MaxRecords     as int64
  field MinRecords     as int64.