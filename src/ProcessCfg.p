block-level on error undo, throw.

using DbAnalysis.Matchers.ITableMatcher from propath.
using DbAnalysis.Matchers.BasicTableMatcher from propath.
using DbAnalysis.DatabaseConfigBuilder from propath.
using DbAnalysis.Matchers.IIndexMatcher from propath.
using DbAnalysis.Matchers.BasicIndexMatcher from propath.
using Logger.BasicLogger from propath.

{Includes/dsConfig.i}


function CreateTableMatchersFromString returns ITableMatcher extent (input TableMatchersString as character) forward.
function CreateIndexMatchersFromString returns IIndexMatcher extent (input IndexMatchersString as character) forward.

define input parameter TableMatchers as character no-undo.
define input parameter IndexMatchers as character no-undo.
define input parameter OutputFile    as character no-undo.
define input parameter WriteOutput   as logical   no-undo.
define input-output parameter dataset for dsConfig.

define variable DatabaseConfigBuilder as DatabaseConfigBuilder no-undo.

assign
  DatabaseConfigBuilder                = new DatabaseConfigBuilder()
  DatabaseConfigBuilder:OutputFilename = OutputFile
  DatabaseConfigBuilder:TableMatchers  = CreateTableMatchersFromString(TableMatchers)
  DatabaseConfigBuilder:IndexMatchers  = CreateIndexMatchersFromString(IndexMatchers).
  
DatabaseConfigBuilder:BuildConfig().
DatabaseConfigBuilder:GetDataset(dataset dsConfig append).

if WriteOutput then
  DatabaseConfigBuilder:WriteConfig(dataset dsConfig).
  
function CreateTableMatchersFromString returns ITableMatcher extent (input TableMatchersString as character):
  define variable MatcherString as character     no-undo.
  define variable ix            as integer       no-undo.
  define variable Matchers      as ITableMatcher no-undo extent 50.
  define variable FinalMatchers as ITableMatcher no-undo extent.
  define variable MatcherCount  as integer       no-undo.  
    
  if TableMatchersString = "" or
    TableMatchersString = ? then
  do:
    extent(FinalMatchers) = 1.
    FinalMatchers[1] = new BasicTableMatcher().
    return FinalMatchers.
  end.
  
  do ix = 1 to num-entries(TableMatchersString):
    MatcherString = entry(ix, TableMatchersString).
    
    if MatcherString = "" then
      next.
    
    assign
      MatcherCount           = MatcherCount + 1
      Matchers[MatcherCount] = new BasicTableMatcher(MatcherString).
  end.
  
  extent(FinalMatchers) = MatcherCount.
  
  do ix = 1 to MatcherCount:
    FinalMatchers[ix] = Matchers[ix].
  end.
  
  return FinalMatchers.
  
end function.


function CreateIndexMatchersFromString returns IIndexMatcher extent (input IndexMatchersString as character):
  
  define variable MatcherString as character     no-undo.
  define variable ix            as integer       no-undo.
  define variable Matchers      as IIndexMatcher no-undo extent 50.
  define variable FinalMatchers as IIndexMatcher no-undo extent.
  define variable MatcherCount  as integer       no-undo.  
  define variable MinFields     as integer       no-undo.
  define variable MaxFields     as integer       no-undo.
  
  if IndexMatchersString = "" or
    IndexMatchersString = ? then
  do:
    extent(FinalMatchers) = 1.
    FinalMatchers[1] = new BasicIndexMatcher().
    return FinalMatchers.
  end.
  
  MatcherLoop:
  do ix = 1 to num-entries(IndexMatchersString):
    MatcherString = entry(ix, IndexMatchersString).
    
    if MatcherString = "" then
      next.
    
    if num-entries(MatcherString, ":") = 1 then
      assign
        MatcherString = MatcherString
        MinFields     = ?
        MaxFields     = ?
        no-error.
    else if num-entries(MatcherString, ":") = 2 then
        assign
          MinFields     = int(entry(2, MatcherString, ":"))
          MaxFields     = ?
          MatcherString = entry(1, MatcherString, ":")
          no-error.
      else if num-entries(MatcherString, ":") = 3 then
          assign
            MinFields     = int(entry(2, MatcherString, ":"))
            MaxFields     = int(entry(3, MatcherString, ":"))
            MatcherString = entry(1, MatcherString, ":")
            no-error.
        else MatcherString = ?.
        
    if MatcherString = ? or (MinFields <> ? and MaxFields <> ? and MinFields > MaxFields) then
    do:
      BasicLogger:Instance:LogError(substitute("Malformed index match string given: [1]. Expects MatchString[:MinFields[:MaxFields]] format.", MatcherString)).
      next MatcherLoop.
    end.
    
    assign
      MatcherCount           = MatcherCount + 1
      Matchers[MatcherCount] = new BasicIndexMatcher(MatcherString, MinFields, MaxFields).
  end.
  
  extent(FinalMatchers) = MatcherCount.
  
  do ix = 1 to MatcherCount:
    FinalMatchers[ix] = Matchers[ix].
  end.
  
  return FinalMatchers.
  
end function.