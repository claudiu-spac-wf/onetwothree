define {&1} temp-table ttConfig no-undo
  field ConfigGuid   as character
  field DatabaseGuid as character
  field DatabaseName as character
  field TableName    as character
  field IndexName    as character
  field MaxRunTime   as integer initial 20.
  
define {&1} temp-table ttConfigField no-undo
  field ConfigGuid as character serialize-hidden
  field Order      as integer
  field IndexField as character
  field DataType   as character.
  
  
define dataset dsConfig for ttConfig, ttConfigField
  data-relation ConfigFields for ttConfig, ttConfigField relation-fields(ConfigGuid, ConfigGuid) nested foreign-key-hidden.