 
/*------------------------------------------------------------------------
   File        : DatabaseConfigBuilder
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : claudiu.spac
   Created     : Mon Sep 02 13:13:16 EEST 2024
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using DbAnalysis.Matchers.ITableMatcher from propath.
using DbAnalysis.Matchers.IIndexMatcher from propath.
using Logger.BasicLogger from propath.
using Logger.LoggingLevels from propath.

block-level on error undo, throw.

class DbAnalysis.DatabaseConfigBuilder: 
  {Includes/dsDatabaseConfig.i}
  {Includes/dsConfig.i}
  
  define public property OutputFilename as character no-undo initial "config.json"
    get. 
    set. 

  define public property TableMatchers as ITableMatcher no-undo extent
    get.
    set. 
    
  define public property IndexMatchers as IIndexMatcher no-undo extent
    get.
    set. 

  
  /*------------------------------------------------------------------------------
   Purpose: This builds a config temp-table that can then be used to generate the
            code that creates statistics.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void BuildConfig(  ):     
    define variable ix as integer no-undo.   
    BasicLogger:Instance:LogInfo("Building database config...").
    
    if BasicLogger:Instance:MinLogLevel <= LoggingLevels:debug then
    do:
      BasicLogger:Instance:LogDebug(substitute("Table matchers: [&1]", extent(TableMatchers))).
          
      BasicLogger:Instance:OpenGroup().
      do ix = 1 to extent(TableMatchers):
        BasicLogger:Instance:LogDebug(TableMatchers[ix]:ToString()).
      end.
      BasicLogger:Instance:CloseGroup().
      
      BasicLogger:Instance:LogDebug(substitute("Index matchers: [&1]", extent(IndexMatchers))).
          
      BasicLogger:Instance:OpenGroup().
      do ix = 1 to extent(IndexMatchers):
        BasicLogger:Instance:LogDebug(IndexMatchers[ix]:ToString()).
      end.
      BasicLogger:Instance:CloseGroup().
    end.
    
    BasicLogger:Instance:OpenGroup().

    for each Db._Db:
      BuildDatabaseConfig(buffer Db._Db).
    end.
    
    BasicLogger:Instance:CloseGroup().
    
    CleanupEmptyRecords().
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Builds the config for a given database.
   Notes:
  ------------------------------------------------------------------------------*/
  method protected void BuildDatabaseConfig(buffer bufDb for Db._Db):
    define buffer bufttDatabase for ttDatabase.
    define buffer bufFile       for Db._File.
    
    BasicLogger:Instance:LogInfo(substitute("Building config for database [&1]", ldbname(buffer bufDb))).
    
    create bufttDatabase.
    assign
      bufttDatabase.DatabaseGuid = bufDb._Db-Guid
      bufttDatabase.DatabaseName = ldbname(buffer bufDb).
        
        
    BasicLogger:Instance:OpenGroup().
    
    TableLoop:
    for each bufFile no-lock where
      bufFile._Db-Recid = recid(bufDb) and
      not bufFile._File-Name begins "_":
      BuildTableConfig(buffer bufttDatabase, buffer bufFile).
    end.
    
    BasicLogger:Instance:CloseGroup().
    
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Builds the config for a given index
   Notes:
  ------------------------------------------------------------------------------*/
  method public void BuildIndexConfig(buffer bufttTable for ttTable, buffer bufIndex for Db._Index):
    define variable ix           as integer       no-undo.
    define variable IndexMatcher as IIndexMatcher no-undo.
    define variable MatchFound   as logical       no-undo.
    
    define buffer bufttIndex for ttIndex.
    
    BasicLogger:Instance:LogDebug(substitute("Building config for index [&1]", bufIndex._Index-Name)).
    
    MatchFound = false.
    
    IndexMatcherBlock:
    do ix = 1 to extent(IndexMatchers):
      IndexMatcher = IndexMatchers[ix].
          
      if valid-object(IndexMatcher) and
        IndexMatcher:Match(bufttTable.DatabaseGuid, bufttTable.TableName, bufIndex._Index-Name) then
      do:
        MatchFound = true.
        leave IndexMatcherBlock.
      end.
    end.
    
    if MatchFound = false then
    do:
      BasicLogger:Instance:LogInfo("No index matcher matched so the index will be skipped.").
      return.
    end.
    
    create bufttIndex.
    assign
      bufttIndex.IndexGuid = hex-encode(message-digest("MD5", bufttTable.DatabaseGuid + " " + bufttTable.TableName + " " + bufIndex._Index-Name))
      bufttIndex.IndexName = bufIndex._Index-Name
      bufttIndex.TableGuid = bufttTable.TableGuid.
      
    BasicLogger:Instance:OpenGroup().
    
    BuildIndexFieldConfig(buffer bufttTable, buffer bufttIndex, buffer bufIndex).
    
    BasicLogger:Instance:CloseGroup().
    
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Builds the index fields config for a given index.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void BuildIndexFieldConfig(buffer bufttTable for ttTable, buffer bufttIndex for ttIndex, buffer bufIndex for Db._Index):
    define buffer bufttIndexField for ttIndexField.
    define buffer bufIndexField   for Db._Index-Field.
    define buffer bufField        for Db._Field.
    
    BasicLogger:Instance:LogDebug(substitute("Building config for index fields of index [&1]", bufttIndex.IndexName)).
    
    for each bufIndexField no-lock where
      bufIndexField._Index-Recid = recid(bufIndex),
      first bufField no-lock where
      recid(bufField) = bufIndexField._Field-recid
      by bufIndexField._Index-Seq:
      
      create bufttIndexField.
      assign
        bufttIndexField.DataType       = bufField._Data-Type
        bufttIndexField.FieldName      = bufField._Field-Name
        bufttIndexField.IndexFieldGuid = hex-encode(message-digest("MD5", bufttTable.DatabaseGuid + " " + bufttTable.TableName + " " + bufIndex._Index-Name + " " + bufttIndexField.FieldName))
        bufttIndexField.IndexGuid      = bufttIndex.IndexGuid
        bufttIndexField.fieldOrder     = bufIndexField._Index-Seq.
    end.
    
    if bufIndex._Unique and
      available(bufttIndexField) then
      bufttIndexField.IsLastOfUniqueIndex = true.
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Builds the config for a given table
   Notes:
  ------------------------------------------------------------------------------*/
  method public void BuildTableConfig(buffer bufttDatabase for ttDatabase, buffer bufFile for Db._File):
    define variable ix           as integer       no-undo.
    define variable TableMatcher as ITableMatcher no-undo.
    define variable MatchFound   as logical       no-undo.
    
    define buffer bufttTable for ttTable.
    define buffer bufIndex   for Db._Index.
    
    BasicLogger:Instance:LogInfo(substitute("Building config for tabe [&1]", bufFile._File-Name)).
    
    TableMatcherGroup:
    do ix = 1 to extent(TableMatchers):
      TableMatcher = TableMatchers[ix].
          
      if valid-object(TableMatcher) and
        TableMatcher:Match(bufttDatabase.DatabaseGuid, bufFile._File-Name) then
      do:
        MatchFound = true.
        leave TableMatcherGroup.
      end.
    end.
        
    if MatchFound = false then
    do:
      BasicLogger:Instance:LogInfo("No table matcher matched so the table will be skipped.").
      return.
    end.
    
    create bufttTable.
    assign
      bufttTable.DatabaseGuid = bufttDatabase.DatabaseGuid
      bufttTable.TableGuid    = hex-encode(message-digest("MD5", bufttTable.DatabaseGuid + " " + bufFile._File-Name))
      bufttTable.TableName    = bufFile._File-Name.
         
    BasicLogger:Instance:OpenGroup().
    
    IndexLoop:
    for each bufIndex no-lock where
      bufIndex._File-Recid = recid(bufFile) and
      bufIndex._WordIdx = ?:
            
      BuildIndexConfig(buffer bufttTable, buffer bufIndex).
    end.
    
    BasicLogger:Instance:CloseGroup().
    
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Cleans up empty records. Due to the way we store data it's possible to
            end up with databases with no tables, tables with no indexes, etc. so 
            we need to clean those up.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void CleanupEmptyRecords(  ):
    IndexLoop:
    for each ttIndex:
      for first ttIndexField where
        ttIndexField.IndexGuid = ttIndex.IndexGuid:
      end.
      
      if not available ttIndexField then
      do:
        BasicLogger:Instance:LogWarning(substitute("Cleaning empty index [&1] of table [&2]", ttIndex.IndexName, ttIndex.TableGuid)).
        delete ttIndex.
        next IndexLoop.
      end.
      
      if ttIndexField.IsLastOfUniqueIndex then
      do:
        BasicLogger:Instance:LogWarning(substitute("Cleaning index [&1] of table [&2] because it is an unique index containing a single field", ttIndex.IndexName, ttIndex.TableGuid)).
        delete ttIndex.
        next IndexLoop.
      end.

      for each ttIndexField where
        ttIndexField.IndexGuid = ttIndex.IndexGuid and
        ttIndexField.FieldName = "":
        if ttIndexField.FieldName = "" then
        do:
          BasicLogger:Instance:LogError(substitute("Cleaning index [&1] of table [&2] because it contained a field with an empty name", ttIndex.IndexName, ttIndex.TableGuid)).
          delete ttIndex.
          next IndexLoop.
        end.
      end.
    end.
    
    
    for each ttTable:
      for first ttIndex where
        ttIndex.TableGuid = ttTable.TableGuid:
      end.
      
      if not available ttIndex then
      do:
        BasicLogger:Instance:LogWarning(substitute("Cleaning empty table [&1] of database [&2]", ttTable.TableName, ttTable.DatabaseGuid)).
        delete ttTable.
      end.
    end.
    
    
    for each ttDatabase:
      for first ttTable where
        ttTable.DatabaseGuid = ttDatabase.DatabaseGuid:
      end.
      
      if not available ttTable then
      do:
        BasicLogger:Instance:LogWarning(substitute("Cleaning empty database [&1] [&2]", ttDatabase.DatabaseName, ttDatabase.DatabaseGuid)).
        delete ttDatabase.
      end.
    end.
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Exposes the dataset to the outside world. Useful because we want to 
            output data from multiple databases into a single config file.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void GetDataset( output dataset dsConfig):
    for each ttDatabase,
      each ttTable where
      ttTable.DatabaseGuid = ttDatabase.DatabaseGuid,
      each ttIndex where
      ttIndex.TableGuid = ttTable.TableGuid:
           
      create ttConfig.
      assign
        ttConfig.ConfigGuid   = guid
        ttConfig.DatabaseGuid = ttDatabase.DatabaseGuid
        ttConfig.DatabaseName = ttDatabase.DatabaseName
        ttConfig.IndexName    = ttIndex.IndexName
        ttConfig.TableName    = ttTable.TableName.
        
      for each ttIndexField where
        ttIndexField.IndexGuid = ttIndex.IndexGuid
        by ttIndexField.FieldOrder:
        
        create ttConfigField.
        assign
          ttConfigField.ConfigGuid  = ttConfig.ConfigGuid
          ttConfigField.DataType    = ttIndexField.DataType
          ttConfigField.IndexField  = ttIndexField.FieldName
          ttConfigField.Order       = ttIndexField.FieldOrder.
      end.
    end.
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Writes the created config to a file.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void WriteConfig( dataset dsConfig):
    
    BasicLogger:Instance:LogInfo(substitute("Outputting generated config file to [&1]", OutputFilename)).
    dataset dsConfig:write-json("FILE",OutputFilename, yes, ?, yes, yes).
  end method.
end class.