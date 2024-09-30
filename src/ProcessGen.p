block-level on error undo, throw.

using DbAnalysis.Matchers.ITableMatcher from propath.
using DbAnalysis.Matchers.BasicTableMatcher from propath.
using DbAnalysis.DatabaseConfigBuilder from propath.
using DbAnalysis.Matchers.IIndexMatcher from propath.
using DbAnalysis.Matchers.BasicIndexMatcher from propath.
using Logger.BasicLogger from propath.
using Templates.StatGathererGenerator from propath.

{Includes/dsConfig.i}
{Includes/ttFileContent.i}

define input parameter ConfigFile   as character no-undo.
define input parameter OutputFolder as character no-undo.
define input parameter OutputMainStatGatherer as logical no-undo.
define input-output parameter DatabaseNames as character no-undo.

define variable DatabaseName as character no-undo.
define variable Continue     as logical   no-undo.
define variable BaseFilesDir as character no-undo.

run InitParameters(output Continue).
if not Continue then
  return.
  
  
run CreateOutputDirs(output Continue).
if not Continue then
  return.

run CopyBaseFiles.
run CreateStatGathererFiles.

procedure CreateStatGathererFiles:
  define variable FolderName   as character             no-undo.
  define variable Generator    as StatGathererGenerator no-undo.
  define variable TempLc       as longchar              no-undo.
  define variable FieldNames   as character             no-undo.
  define variable ClassName    as character             no-undo.
  define variable DatabaseGuid as character             no-undo.
  define variable RunStatsLc   as longchar              no-undo.
  define variable ix           as integer               no-undo.
   
  define buffer bufDb for Db._Db.
  
  assign
    RunStatsLc = "~{Includes/dsDataPoints.i~}~n~n"
    Generator  = new StatGathererGenerator().
    
  for first bufDb no-lock:
    DatabaseGuid = bufDb._Db-Guid.
  end.

  for each ttConfig where
    ttConfig.DatabaseGuid = DatabaseGuid
    break by ttConfig.TableName:
      
    if first-of(ttConfig.TableName) then
    do:
      FolderName = OutputFolder + "/" + DatabaseName + "/" + ttConfig.TableName.
      BasicLogger:Instance:LogInfo(substitute("Creating output dir [&1] for database [&2] and table [&3].", FolderName, DatabaseName, ttConfig.TableName)).
  
      os-create-dir value(FolderName).
    end.
    
    assign
      FieldNames = ""
      ClassName  = substitute("StatGatherer&1", ttConfig.IndexName)
      TempLc     = Generator:GenerateClassStart(ttConfig.TableName + "." + ClassName, ttConfig.TableName + "_" + ttConfig.IndexName).
      
    for each ttConfigField where
      ttConfigField.ConfigGuid = ttConfig.ConfigGuid
      break by ttConfigField.Order:
        
      assign
        FieldNames = trim(FieldNames + "," + ttConfigField.IndexField, ",")
        TempLc     = TempLc + Generator:GenerateLoopMethodSignature(ttConfigField.Order, ttConfig.TableName)
        TempLc     = TempLc + Generator:GenerateLoopMethodContent(ttConfigField.Order, ttConfig.TableName, FieldNames, ttConfigField.DataType, not last(ttConfigField.Order))
        TempLc     = TempLc + StatGathererGenerator:MethodEnd.
    end.
    
    assign
      TempLc = TempLc + Generator:GenerateConstructor(ClassName, ttConfig.TableName, ttConfig.IndexName, FieldNames, ttConfig.MaxRunTime)
      TempLc = TempLc + StatGathererGenerator:ClassEnd.
      
    copy-lob TempLc to file FolderName + "/" + ClassName + ".cls".
    
    assign
      RunStatsLc = RunStatsLc + "define variable o" + ttConfig.TableName + ClassName + " as " + ttConfig.TableName + "." + ClassName + " no-undo.~n"
      RunStatsLc = RunStatsLc + "o" + ttConfig.TableName + ClassName + " = new " + ttConfig.TableName + "." + ClassName + "().~n"
      RunStatsLc = RunStatsLc + "o" + ttConfig.TableName + ClassName + ":GatherStats(output dataset dsDataPoints append).~n"
      RunStatsLc = RunStatsLc + "dataset dsDataPoints:write-json('file','data_points_" + DatabaseName + ".json', yes, ?, no, yes).~n~n".
      
  end.
  
  RunStatsLc = RunStatsLc + "dataset dsDataPoints:write-json('file','data_points_" + DatabaseName + ".json', yes, ?, no, yes)".
  
  copy-lob RunStatsLc to file OutputFolder + "/" + DatabaseName + "/RunStatGatherers.p".
   
  if OutputMainStatGatherer then
  do:
    RunStatsLc = "".
    
    do ix = 1 to num-entries(DatabaseNames):
      RunStatsLc = RunStatsLc + "~nrun " + entry(ix, DatabaseNames) + "/RunstatGatherers.p".
    end.
    
    copy-lob RunStatsLc to file OutputFolder + "/RunStatGatherers.p".
  end.
end procedure.

procedure CopyBaseFiles:
  define variable FileContents as longchar no-undo.
  
  FileContents = "{Build/baseFileContents.json}".
  temp-table ttFileContent:read-json("longchar", FileContents).
  
  for each ttFileContent:
    run CopyFile(buffer ttFileContent).
  end.
end procedure.

procedure CopyFile:
  define parameter buffer bufttFileContent for ttFileContent.
  
  BasicLogger:Instance:LogInfo(substitute("Creating base file [&1]", bufttFileContent.FileRelativePath)).
  copy-lob bufttFileContent.FileContents to file BaseFilesDir + bufttFileContent.FileRelativePath.
end procedure.

procedure CreateOutputDirs:
  define output parameter Continue as logical no-undo.
  
  define variable FolderName as character no-undo.
  
  FolderName = OutputFolder + "/" + DatabaseName.
  BasicLogger:Instance:LogInfo(substitute("Creating output dir [&1] for database [&2].", FolderName, DatabaseName)).
  
  os-create-dir value(FolderName).
  if os-error <> 0 then
  do:
    BasicLogger:Instance:LogError(substitute("Could not create output dir [&1] for database [&2]. OS returned error code [&3].",
      FolderName,
      DatabaseName,
      os-error)).
    return.
  end.
  
  assign
    FolderName   = OutputFolder + "/" + DatabaseName + "/Base"
    BaseFilesDir = FolderName.
  BasicLogger:Instance:LogInfo(substitute("Creating base dir [&1] for database [&2].", FolderName, DatabaseName)).
  
  os-create-dir value(FolderName).
  if os-error <> 0 then
  do:
    BasicLogger:Instance:LogError(substitute("Could not create base dir [&1] for database [&2]. OS returned error code [&3].",
      FolderName,
      DatabaseName,
      os-error)).
    return.
  end.
  
  FolderName = OutputFolder + "/" + DatabaseName + "/Base/Includes".
  BasicLogger:Instance:LogInfo(substitute("Creating base includes dir [&1] for database [&2].", FolderName, DatabaseName)).
  
  os-create-dir value(FolderName).
  if os-error <> 0 then
  do:
    BasicLogger:Instance:LogError(substitute("Could not create base includes dir [&1] for database [&2]. OS returned error code [&3].",
      FolderName,
      DatabaseName,
      os-error)).
    return.
  end.
  
  
  Continue = true.
  
  
end procedure.

procedure InitParameters:
  define output parameter Continue as logical no-undo.
  
  assign
    DatabaseName  = ldbname("Db")
    DatabaseNames = trim(DatabaseNames + "," + DatabaseName, ",").
  
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

  dataset dsConfig:read-json("file", ConfigFile, "empty") no-error.

  if error-status:error then
  do:
    BasicLogger:Instance:LogError(substitute("An error occured while reading config file [&1]. Please make sure it is a valid config file, a JSON Schema is included with the script and the config file should validate against it. Error: [&2]", ConfigFile, error-status:get-message(1))).
    return.
  end.
  
  Continue = true.
end procedure.