 
/*------------------------------------------------------------------------
   File        : BasicIndexMatcher
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : claudiu.spac
   Created     : Mon Sep 02 11:39:57 EEST 2024
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using DbAnalysis.Matchers.IIndexMatcher.
using Logger.BasicLogger from propath.

block-level on error undo, throw.

class DbAnalysis.Matchers.BasicIndexMatcher implements IIndexMatcher: 
  
  define public property IndexNameMatch as character no-undo initial "*"
    get.
    set. 

  define public property MaxIndexFields as integer no-undo initial ?
    get.
    set. 

  define public property MinIndexFields as integer no-undo initial ?
    get.
    set. 

  constructor public BasicIndexMatcher (  ):
    super ().
  end constructor.

  constructor public BasicIndexMatcher (input MatchString as character, input MinFields as integer, input MaxFields as integer):
    super ().
    assign
      IndexNameMatch = MatchString
      MinIndexFields = MinFields
      MaxIndexFields = MaxFields.
  end constructor.


  method public logical Match( input DatabaseGuid as character, input TableName as character, input IndexName as character ):
    define buffer bufDb         for Db._Db.
    define buffer bufFile       for Db._File.
    define buffer bufIndex      for Db._Index.
    define buffer bufIndexField for Db._Index-Field.
    
    define variable IndexFieldNum as integer no-undo.
    
    BasicLogger:Instance:LogDebug(substitute("Matching index [&1] for table [&2] using match string [&3]", IndexName, TableName, IndexNameMatch)).
    if not IndexName matches IndexNameMatch then 
    do:
      BasicLogger:Instance:LogDebug(substitute("Index [&1] for table [&2] doesn't match using match string [&2]", IndexName, TableName, IndexNameMatch)).
      return false.
    end.
    
    for first bufDb no-lock where
      bufDb._Db-Guid = DatabaseGuid,
      first bufFile no-lock where
        bufFile._Db-Recid = recid(bufDb) and
        bufFile._File-Name = TableName,
      first bufIndex no-lock where
        bufIndex._File-Recid = recid(bufFile):
      BasicLogger:Instance:LogDebug(substitute("Index [&1] for table [&2] mathches match string [&3]", IndexName, TableName, IndexNameMatch)).
    end.
    
    if not available bufIndex then
    do:
      BasicLogger:Instance:LogDebug(substitute("Index [&1] for table [&2] mathches match string [&3] but doesn't exist in the database", IndexName, TableName, IndexNameMatch)).
      return false.
    end.
    
    if MinIndexFields <> ? or
      MaxIndexFields <> ? then
      for each bufIndexField no-lock where
        bufIndexField._Index-Recid = recid(bufIndex):
        IndexFieldNum = IndexFieldNum + 1.
      end.
    else
      return true.
    
    if (MinIndexFields <> ? and IndexFieldNum < MinIndexFields) or 
      (MaxIndexFields <> ? and IndexFieldNum > MaxIndexFields) then
    do:
      BasicLogger:Instance:LogDebug(substitute("Index [&1] for table [&2] mathches match string [&3] but doesn't meed index field count requirements [&4 <= &5 <=&6]", 
        IndexName, TableName, IndexNameMatch,
        MinIndexFields, IndexFieldNum, MaxIndexFields)).
      return false.
    end.
    
    return true.

  end method.

  method override public character ToString():
    return substitute("Indexes matching [&1] with fields numbering between [&2] and [&3]",
      IndexNameMatch,
      MinIndexFields,
      MaxIndexFields).
  end method.
end class.