using Logger.LoggingLevels from propath.
using Logger.BasicLogger from propath.
using DbAnalysis.DatabaseConfigBuilder from propath.
using DbAnalysis.Matchers.ITableMatcher from propath.
using DbAnalysis.Matchers.BasicTableMatcher from propath.
using DbAnalysis.Matchers.BasicIndexMatcher from propath.
using DbAnalysis.Matchers.IIndexMatcher from propath.

define variable ExecCommand as character no-undo.
define variable LogLevel    as character no-undo.
define variable LogFilename as character no-undo.

&scoped-define KnownParameters ""

{Includes/ScriptFunctions.i}
{Includes/dsConfig.i}

assign
  ExecCommand = entry(1, session:parameter)
  LogLevel    = entry(2, session:parameter)
  LogFilename = entry(3, session:parameter)
  no-error.
  
if error-status:error or 
  lookup(ExecCommand,"cfg,gen,run") = 0 or 
  lookup(LogLevel,"error,warning,info,debug") = 0 then
do:
  message "An error occured when running this procedure." +
    "Make sure that you are running this procedure from the associated python script," +
    " or that you are setting the right parameters up."
    view-as alert-box.
  return.
end.

run InitLogging.
run ProcessCommand.

procedure InitLogging:
  define variable LoggingLevel as LoggingLevels no-undo.
  
  LoggingLevel = LoggingLevels:info.
  
  case LogLevel:
    when "error" then 
      LoggingLevel = LoggingLevels:error.
    when "warning" then 
      LoggingLevel = LoggingLevels:warning.
    when "info" then 
      LoggingLevel = LoggingLevels:info.
    when "debug" then 
      LoggingLevel = LoggingLevels:debug.
  end case.
  
  message "Setting log level to" LoggingLevel.
  message "Logging will be output to" if LogFilename > "" then LogFilename else "stdout".
  assign
    BasicLogger:Instance:MinLogLevel = LoggingLevel
    BasicLogger:Instance:LogFilename = LogFilename.
end procedure.

procedure ProcessCommand:
  
  
  case ExecCommand:
    when "cfg" then run ProcessCfg.
     
    when "gen" then run ProcessGen.
      
    when "run" then run ProcessRun.
  end case.
  
end procedure.

procedure ProcessCfg:
  
  define variable IndexMatchers as character no-undo.
  define variable TableMatchers as character no-undo.
  define variable ix            as integer   no-undo.
  define variable OutputFile    as character no-undo.
  
  assign
    TableMatchers = trim(GetParameterValue("TableMatchers"))
    IndexMatchers = trim(GetParameterValue("IndexMatchers"))
    OutputFile    = GetParameterValue("Output").
  
  do ix = 1 to num-dbs:
    delete alias Db.
    create alias Db for database value(ldbname(ix)) no-error.
    
    run ProcessCfg.p(TableMatchers, IndexMatchers, OutputFile, ix = num-dbs, input-output dataset dsConfig).
  end.
  
end procedure.

procedure ProcessGen:
  define variable ix            as integer   no-undo.
  define variable OutputFolder  as character no-undo.
  define variable ConfigFile    as character no-undo.
  define variable DatabaseNames as character no-undo.
  
  assign
    OutputFolder = GetParameterValue("Output")
    ConfigFile   = GetParameterValue("ConfigFile").
  
  do ix = 1 to num-dbs:
    delete alias Db.
    create alias Db for database value(ldbname(ix)) no-error.
    
    run ProcessGen.p(ConfigFile, OutputFolder, ix = num-dbs, input-output DatabaseNames).
  end.
  
end procedure.

procedure ProcessRun:
  define variable ix            as integer   no-undo.
  define variable OutputFolder  as character no-undo.
  define variable DatabaseNames as character no-undo.
  define variable BasePropath   as character no-undo.
  
  assign
    BasePropath  = propath
    OutputFolder = GetParameterValue("GeneratedCodeFolder").
  
  do ix = 1 to num-dbs:
    delete alias Db.
    create alias Db for database value(ldbname(ix)) no-error.
    
    assign
      propath = OutputFolder + "\" + ldbname(ix) + "\Base"
      propath = propath + "," + OutputFolder + "\" + ldbname(ix)
      propath = propath + "," + OutputFolder
      propath = propath + "," + BasePropath.
    
    run ProcessRun.p(OutputFolder).
  end.
  
end procedure.