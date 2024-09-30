 
/*------------------------------------------------------------------------
   File        : BasicTableMatcher
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : claudiu.spac
   Created     : Fri Aug 30 15:28:14 EEST 2024
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using DbAnalysis.Matchers.ITableMatcher.
using Logger.BasicLogger from propath.

block-level on error undo, throw.

class DbAnalysis.Matchers.BasicTableMatcher implements ITableMatcher: 

  define public property TableNameMatch as character no-undo initial "*"
    get.
    set. 

  constructor public BasicTableMatcher (  ):
    super ().
  end constructor.

  constructor public BasicTableMatcher ( input NewTableNameMatch as character):
    super ().
    TableNameMatch = NewTableNameMatch.
  end constructor.

  method public logical Match(input DatabaseGuid as character, input TableName as character ):
    define buffer bufDb   for Db._Db.
    define buffer bufFile for Db._File.
    
    BasicLogger:Instance:LogDebug(substitute("Matching table [&1] using match string [&2]", TableName, TableNameMatch)).
    if not TableName matches TableNameMatch then 
    do:
      BasicLogger:Instance:LogDebug(substitute("Table [&1] doesn't match using match string [&2]", TableName, TableNameMatch)).
      return false.
    end.
    
    for first bufDb no-lock where
      bufDb._Db-Guid = DatabaseGuid,
      first bufFile no-lock where
      bufFile._File-Name = TableName:
    end.
    
    if available bufFile then
    do:
      BasicLogger:Instance:LogDebug(substitute("Table [&1] mathches match string [&2]", TableName, TableNameMatch)).
      return true.
    end.
    else
    do:
      BasicLogger:Instance:LogDebug(substitute("Table [&1] mathches match string [&2] but doesn't exist in the database", TableName, TableNameMatch)).
      return false.
    end.
    
    return true.
  end method.

  method override public character ToString():
    return substitute("Tables matching [&1]", TableNameMatch).
  end method.

end class.