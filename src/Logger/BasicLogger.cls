 
/*------------------------------------------------------------------------
   File        : SimpleLogger
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : claudiu.spac
   Created     : Fri Aug 30 15:32:51 EEST 2024
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Logger.BasicLogger from propath.
using Logger.LoggingLevels from propath.

block-level on error undo, throw.

class Logger.BasicLogger:
  define private stream LoggerOutput.
  
  define public static property Instance as BasicLogger no-undo 
    get():
      if valid-object(Instance) then
        return Instance.
        
      Instance = new BasicLogger(LoggingLevels:info, "").
      return Instance.
    end.
    protected set. 

  define public property LoggingGroupLevel as integer no-undo initial 0
    get.
    set. 

  define public property MinLogLevel as LoggingLevels no-undo
    get.
    set.
    
  define public property LogFilename as character no-undo
    get.
    set(input NewLogFilename as character):
      output stream LoggerOutput close.
      
      if NewLogFilename > "" then
      do:
        if LogFilename > "" then
          output stream LoggerOutput close.
          
        output stream LoggerOutput to value(NewLogFilename) append.
      end.
      
      LogFilename = NewLogFilename.
    end.
  
  /*------------------------------------------------------------------------------
   Purpose: Creates a basic logger that can be used all over the place in order
            to simplify loggig. This can be extended as needed, as most of the time
            we will just want to output the messages to a log file.
   Notes:
  ------------------------------------------------------------------------------*/
  constructor public BasicLogger (input NewMinLogLevel as LoggingLevels, input NewLogFilename as character):
    super ().
  
    assign
      MinLogLevel = NewMinLogLevel
      LogFilename = NewLogFilename.
  end constructor.
  
  constructor public BasicLogger ():
    super ().
  
    assign
      MinLogLevel = LoggingLevels:info
      LogFilename = "".
  end constructor.
  
  /*------------------------------------------------------------------------------
   Purpose: Opens up a logging group. This only affects the way log lines are written
            in that they are prefixed with a number of hyphens.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void OpenGroup():
    LoggingGroupLevel = LoggingGroupLevel + 1.
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Closes a logging group. This only affects the way log lines are written
            in that they are prefixed with a number of hyphens.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void CloseGroup():
    LoggingGroupLevel = max(LoggingGroupLevel - 1, 0).
  end method.
  
  method public void LogError(input LogMessage as character):
    LogMessage(LoggingLevels:error, input LogMessage).
  end method.
  
  method public void LogWarning(input LogMessage as character):
    LogMessage(LoggingLevels:warning, input LogMessage).
  end method.
  
  method public void LogInfo(input LogMessage as character):
    LogMessage(LoggingLevels:info, input LogMessage).
  end method.
  
  method public void LogDebug(input LogMessage as character):
    LogMessage(LoggingLevels:debug, input LogMessage).
  end method.

  /*------------------------------------------------------------------------------
   Purpose: Logs a given message at the given logging level.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void LogMessage(input LogLevel as LoggingLevels, input LogMessage as character):
    
    if LogLevel < MinLogLevel then
      return.
      
    WriteLogMessage(input LogLevel, input LogMessage).
  end method.  

  /*------------------------------------------------------------------------------
   Purpose: Writes the given log message. This is what you'll want to override if 
            logging needs to do anything different i.e. send the message to an API
            endpoint or just message LogMessage.
   Notes:
  ------------------------------------------------------------------------------*/
  method protected void WriteLogMessage( input LogLevel as LoggingLevels, input LogMessage as character ):    
    if LogFilename = "" or LogFilename = ? then
      message 
        iso-date(now) " "
        string(LogLevel:ToString() + ":", "xxxxxxxxx") 
        fill("  ", LoggingGroupLevel) 
        LogMessage.
    else
      put stream LoggerOutput unformatted 
        iso-date(now) " "
        string(LogLevel:ToString() + ":", "xxxxxxxxx") 
        fill("  ", LoggingGroupLevel)
        LogMessage
        skip.
  end method.
  
  /*------------------------------------------------------------------------------
   Purpose: Closes the logging currently taking place by setting the LogFilename 
            blank so any subsequent log messages go to the terminal.
   Notes:
  ------------------------------------------------------------------------------*/
  method public void CloseLog():
    LogFilename = "".
  end method.
  
  
end class.