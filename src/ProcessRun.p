block-level on error undo, throw.

using Logger.BasicLogger from propath.

define input parameter OutputFolder as character no-undo.

define variable DatabaseName as character no-undo.
define variable Continue     as logical   no-undo.
define variable BaseFilesDir as character no-undo.

run InitParameters(output Continue).
if not Continue then
  return.
  
run value(OutputFolder + "/" + DatabaseName + "/RunStatGatherers.p").


procedure InitParameters:
  define output parameter Continue as logical no-undo.
  
  assign
    DatabaseName = ldbname("Db").
  
  file-info:file-name = OutputFolder.

  if file-info:full-pathname = ? then
  do:
    BasicLogger:Instance:LogError("Incorrect output directory given. Please make sure that the directory exists.").
    return.
  end.

  if file-info:file-type <> "DRW" then
  do:
    BasicLogger:Instance:LogError(substitute("Incorrect output directory given. Please make sure that it is a directory and you have read/write permissions for it. Current file-type: [&1]", file-info:file-type)).
    return.
  end.
  
  Continue = true.
end procedure.