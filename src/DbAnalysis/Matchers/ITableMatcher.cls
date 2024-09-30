
/*------------------------------------------------------------------------
    File        : ITableMatcher
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : claudiu.spac
    Created     : Fri Aug 30 15:22:02 EEST 2024
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

interface DbAnalysis.Matchers.ITableMatcher:  
  
  /*------------------------------------------------------------------------------
   Purpose: Returns whether or not a table matches some criteria in order to know
            whether or not we want to include this table in the analysis.
   Notes:
  ------------------------------------------------------------------------------*/
  method public logical Match(input DatabaseGuid as character, input TableName as character).

  /*------------------------------------------------------------------------------
   Purpose: Returns a string representation of the matcher. Only needed for logging
            purposes so it should be readable.
   Notes:
  ------------------------------------------------------------------------------*/
  method public character ToString(  ).

end interface.