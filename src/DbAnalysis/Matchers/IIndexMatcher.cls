
/*------------------------------------------------------------------------
    File        : IIndexMatcher
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : claudiu.spac
    Created     : Fri Aug 30 15:24:02 EEST 2024
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

interface DbAnalysis.Matchers.IIndexMatcher:
  
  /*------------------------------------------------------------------------------
   Purpose: Returns whether or not an index matches some criteria in order to know
            whether or not we want to include this index in the analysis.
   Notes:
  ------------------------------------------------------------------------------*/
  method public logical Match(input DatabaseGuid as character, input TableName as character, input IndexName as character).
  
  /*------------------------------------------------------------------------------
   Purpose: Returns a string representation of the matcher. Only needed for logging
            purposes so it should be readable.
   Notes:
  ------------------------------------------------------------------------------*/
  method public character ToString(  ).
end interface.