{Includes/ttDatabase.i &1}
{Includes/ttTable.i &1}
{Includes/ttIndex.i &1}
{Includes/ttIndexField.i &1}

define {&1} dataset dsDatabaseConfig
  for ttDatabase, ttTable, ttIndex, ttIndexField
  data-relation DatabaseTable for ttDatabase, ttTable relation-fields(DatabaseGuid, DatabaseGuid) nested foreign-key-hidden
  data-relation TableIndex for ttTable, ttIndex relation-fields(TableGuid, TableGuid) nested foreign-key-hidden
  data-relation IndexField for ttIndex, ttIndexField relation-fields(IndexGuid, IndexGuid) nested foreign-key-hidden.