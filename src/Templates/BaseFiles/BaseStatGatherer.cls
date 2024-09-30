using Progress.Lang.*.

block-level on error undo, throw.

class BaseStatGatherer abstract: 
  {Includes/dsDataPoints.i "protected"}
  
  define public property IndexFields as character no-undo 
    get.
    set. 

  define public property TableName as character no-undo 
    get.
    set. 

  define public property IndexName as character no-undo 
    get.
    set. 
  
  define public property MaxRunTime as integer no-undo
    get.
    set.
    
  constructor public BaseStatGatherer (input TableName as character, input IndexName as character, input IndexFields as character, input MaxRunTime as integer):
    assign
      this-object:TableName   = TableName
      this-object:IndexName   = IndexName
      this-object:IndexFields = IndexFields
      this-object:MaxRunTime  = MaxRunTime.
    
  end constructor.
  
  method public void BeforeGatherStats(  ):
    return.
  end method.
  
  method public void AfterGatherStats():
    define variable FieldCount  as integer no-undo.
    define variable RecordCount as int64   no-undo.
    define variable Divider     as int64   no-undo.
    
    create ttIndexData.
    assign
      ttIndexData.IndexGuid   = guid
      ttIndexData.TableName   = TableName
      ttIndexData.IndexName   = IndexName
      ttIndexData.IndexFields = IndexFields
      FieldCount              = num-entries(IndexFields).
      
    for each ttDataPoint:
      ttDataPoint.IndexGuid = ttIndexData.IndexGuid.
      
      if ttDataPoint.Depth = FieldCount then
      do:
        assign
          Divider                = Divider + ttDataPoint.AggregateCountOccurences
          RecordCount            = RecordCount + ttDataPoint.AggregateCount * ttDataPoint.AggregateCountOccurences
          ttIndexData.MaxRecords = max(ttIndexData.MaxRecords, ttDataPoint.AggregateCount)
          ttIndexData.MinRecords = if ttIndexData.MinRecords = 0 then 
                                     ttDataPoint.AggregateCount 
                                   else
                                     min(ttIndexData.MinRecords, ttDataPoint.AggregateCount).
      end.
    end.
    
    ttIndexData.AverageRecords = RecordCount / Divider.
    return.
  end method.

  method public void CreateDataPoint(input IndexGuid as character, input Depth as integer, input AggregateCount as int64, input SplitByString as character):
    for first ttDataPoint where
      ttDataPoint.IndexGuid = IndexGuid and
      ttDataPoint.Depth = Depth and
      ttDataPoint.AggregateCount = AggregateCount:
      
      ttDataPoint.AggregateCountOccurences = ttDataPoint.AggregateCountOccurences + 1.
      
      if num-entries(ttDataPoint.SplitByValueList) < 100 and length(ttDataPoint.SplitByValueList) < 32000 - length(SplitByString) - 100 then
        ttDataPoint.SplitByValueList = ttDataPoint.SplitByValueList + chr(31) + SplitByString.
    end.
    
    if not available ttDataPoint then
    do:
      create ttDataPoint.
      assign
        ttDataPoint.IndexGuid                = IndexGuid
        ttDataPoint.Depth                    = Depth
        ttDataPoint.AggregateCount           = AggregateCount
        ttDataPoint.AggregateCountOccurences = 1
        ttDataPoint.SplitByValueList         = SplitByString.
    end.
  end method.

  method public void GatherStats(output dataset dsDataPoints):
    do on error undo, leave stop-after MaxRunTime:
      BeforeGatherStats().
      LoopRecords_1().
      
      catch e as Progress.Lang.StopAfter :
      end catch.
    end.
    
    AfterGatherStats().
    
  end method.
  
  method public abstract void LoopRecords_1(  ).
end class.