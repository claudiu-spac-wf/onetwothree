define {&1} temp-table ttDataPoint no-undo
  field IndexGuid                as character serialize-hidden
  field Depth                    as integer
  field AggregateCount           as int64
  field AggregateCountOccurences as int64
  field SplitByValueList         as character
  index idxIndexFieldAggregate is primary unique IndexGuid Depth AggregateCount.