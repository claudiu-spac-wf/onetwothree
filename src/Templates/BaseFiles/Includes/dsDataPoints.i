{Includes/ttDataPoint.i &1}
{Includes/ttIndexData.i &1}

define {&1} dataset dsDataPoints
  for ttIndexData, ttDataPoint
  data-relation IndexData for ttIndexData, ttDataPoint relation-fields(IndexGuid, IndexGuid) nested foreign-key-hidden.