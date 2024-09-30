 
/*------------------------------------------------------------------------
   File        : StatGathererGenerator
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : claudiu.spac
   Created     : Tue Sep 03 14:24:46 EEST 2024
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Templates.StatGathererGenerator from propath.

block-level on error undo, throw.

class Templates.StatGathererGenerator: 
  
  define public static property MethodEnd as character no-undo initial "~nend method.~n~n"
    get.
    protected set. 
    
  define public static property ClassEnd as character no-undo initial "~nend class.~n~n"
    get.
    protected set. 

  method public longchar GenerateClassStart(input ClassName as character, input IndexGuid as character):
    define variable OutputText as longchar no-undo.
    
    assign
      OutputText = "using Progress.Lang.*.~nblock-level on error undo, throw.~n~nclass " + ClassName + " inherits BaseStatGatherer:~n"
      OutputText = OutputText + "define protected variable IndexGuid as character no-undo initial '" + IndexGuid + "'.~n~n".
    
    return OutputText.
  end method.
  
  method public longchar GenerateConstructor(input ClassName as character,input TableName as character, input IndexName as character, input IndexFields as character, input MaxRunTime as integer):
    define variable OutputText as longchar no-undo.
    
    assign
      OutputText = "constructor public " + ClassName +  "(): ~n"
      OutputText = OutputText + 'super("' + TableName + '","' + IndexName + '","' + IndexFields + '",' + string(MaxRunTime) + ').~n'
      OutputText = OutputText + 'end.~n~n'.
      
    return OutputText.
  end method.
  
  method public longchar GenerateLoopMethodSignature(input Depth as integer, input TableName as character):
    define variable OutputText as longchar no-undo.
    define variable ix         as integer  no-undo.
    
    OutputText = "method public " + (if Depth = 1 then "override " else "") + "void LoopRecords_" + string(Depth) + "(".
    
    if Depth > 1 then
      OutputText = OutputText + "buffer buf" + string(Depth - 1) + TableName + " for Db." + TableName.
    
    OutputText = OutputText + "):~n".
    return OutputText.
  end method.

  method public longchar GenerateLoopMethodContent(input Depth as integer, input TableName as character, input FieldNames as character, input DataType as character, input QueryString as character, input CallNextLoop as logical):
    define variable OutputText         as longchar  no-undo.
    define variable CurrentBufferName  as character no-undo.
    define variable ix                 as integer   no-undo.
    define variable CurrentBufferField as character no-undo.
    define variable PreviousBufferName as character no-undo.
    define variable AggregateBuffer    as character no-undo.
    define variable AggregateField     as character no-undo.
    
    assign
      CurrentBufferName  = "buf" + string(Depth) + TableName
      PreviousBufferName = "buf" + string(Depth - 1) + TableName
      AggregateBuffer    = "bufAgg" + TableName
      AggregateField     = AggregateBuffer + "." + entry(num-entries(FieldNames), FieldNames)
      CurrentBufferField = CurrentBufferName + "." + entry(num-entries(FieldNames), FieldNames)
      OutputText         = "define buffer " + CurrentBufferName + " for Db." + TableName + ".~n"
      OutputText         = outputText + "define buffer " + AggregateBuffer + " for Db." + TableName + ".~n"
      OutputText         = OutputText + "define variable AggregateValue as int64 no-undo.~n"
      OutputText         = OutputText + "define variable SplitByValue as " + DataType + " no-undo.~n~n".
    
    if Depth = 1 then
    do:
      assign
        OutputText = OutputText + "for each " + CurrentBufferName + " no-lock ~n".

        if QueryString > "" then
          OutputText = OutputText + "where " + substitute(QueryString, CurrentBufferName) + "~n".

        assign
          OutputText = OutputText + "by " + CurrentBufferField + " descending:~nleave.~nend.~n~n"
        
          OutputText = OutputText + "do while available " + CurrentBufferName + ":~n"
          OutputText = OutputText + "SplitByValue = " + CurrentBufferField + ".~n"
        
          OutputText = OutputText + "do on error undo, throw:~n"
          OutputText = OutputText + "aggregate AggregateValue = count(" + AggregateField + ") for " + AggregateBuffer + " where ~n".

          if QueryString > "" then
            OutputText = OutputText + substitute(QueryString, AggregateBuffer) + " and ~n".
        
          OutputText = OutputText + AggregateField + " = SplitByValue.~n~n".
        
    end.
    else
    do:
      assign
        OutputText = OutputText + "for each " + CurrentBufferName + " no-lock where ~n".
      
      if QueryString > "" then
        OutputText = OutputText + substitute(QueryString, CurrentBufferName) + " and~n".

      do ix = 1 to num-entries(FieldNames) - 1:
        OutputText = OutputText + CurrentBufferName + "." + entry(ix, FieldNames) + " = " + PreviousBufferName + "." + entry(ix, FieldNames) + 
          (if ix = num-entries(FieldNames) - 1 then "" else " and") + "~n".
      end.
      
      assign
        OutputText = OutputText + "by " + CurrentBufferField + " descending:~nleave.~nend.~n~n"
      
        OutputText = OutputText + "do while available " + CurrentBufferName + ":~n"
        OutputText = OutputText + "SplitByValue = " + CurrentBufferField + ".~n"
        
        OutputText = OutputText + "do on error undo, return:~n"
        
        OutputText = OutputText + "aggregate AggregateValue = count(" + AggregateField + ") for " + AggregateBuffer + " where ~n".
      
      if QueryString > "" then
        OutputText = OutputText + substitute(QueryString, AggregateBuffer) + " and ~n".

      do ix = 1 to num-entries(FieldNames) - 1:
        OutputText = OutputText + AggregateBuffer + "." + entry(ix, FieldNames) + " = " + PreviousBufferName + "." + entry(ix, FieldNames) + " and" + "~n".
      end.
      
      assign
        OutputText = OutputText + AggregateField + " = SplitByValue.~n~n".
    end.
    
    assign
      OutputText = OutputText + "catch e1 as Progress.Lang.Error: end catch.~n"
      OutputText = OutputText + "catch e2 as Progress.Lang.Stop: end catch.~n"
      OutputText = OutputText + "end.~n~n"
      OutputText = OutputText + "CreateDataPoint(IndexGuid, " + string(Depth) + " , AggregateValue,string(SplitByValue)). ~n".
    
    if CallNextLoop then
      OutputText = OutputText + "LoopRecords_" + string(Depth + 1) + "(buffer " + CurrentBufferName + ").~n".
    
    
    OutputText = OutputText + "~nfor each " + CurrentBufferName + " no-lock where ~n".
    
    if QueryString > "" then
        OutputText = OutputText + substitute(QueryString, CurrentBufferName) + " and ~n".

    if Depth > 1 then
      do ix = 1 to num-entries(FieldNames) - 1:
        OutputText = OutputText + CurrentBufferName + "." + entry(ix, FieldNames) + " = " + PreviousBufferName + "." + entry(ix, FieldNames) + " and" + "~n".
      end.
    
    assign
      OutputText = OutputText + CurrentBufferField + " < SplitByValue~n"
      OutputText = OutputText + "by " + CurrentBufferField + " descending:~nleave.~nend."
      OutputText = OutputText + "~nend.".
      
    return OutputText.
  end method.
end class.