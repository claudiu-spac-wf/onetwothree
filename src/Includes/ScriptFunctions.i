

function GetParameterValue returns character (input LookupName as character):
  define variable ix             as integer   no-undo.
  define variable ParameterEntry as character no-undo.
  define variable ParameterName  as character no-undo.
  define variable ParameterValue as character no-undo.
  
  ParameterLoop:
  do ix = 4 to num-entries(session:parameter):
    ParameterEntry = entry(ix, session:parameter).
    
    if num-entries(ParameterEntry, "=") <> 2 or
      entry(1, ParameterEntry) = "" then
    do:
      BasicLogger:Instance:LogError(substitute("Incorrect parameter name=value pair found: [&1]", parameterEntry)).
      next ParameterLoop.
    end.
    
    assign
      ParameterName  = entry(1, ParameterEntry, "=")
      ParameterValue = entry(2, ParameterEntry, "=").
    
    if ParameterName = LookupName then
      return ParameterValue.
  end.
  
  return "".
end function.

