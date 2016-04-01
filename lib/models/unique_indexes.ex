defmodule Migratrex.UniqueIndexes do
  use Migratrex.Model

  alias Migratrex.{PgClass,PgIndex,PgAttribute}

  # select
  #   t.relname::text as table_name,
  #   i.relname::text as index_name,
  #   a.attname::text as column_name
  # from
  #   pg_class t
  #   join pg_index ix on t.oid = ix.indrelid
  #   join pg_class i on ix.indexrelid = i.oid
  #   join pg_attribute a on a.attrelid = t.oid
  # where a.attnum = ANY(ix.indkey)
  #   and t.relkind = 'r'
  #   and ix.indisunique
  #   and a.attname != 'id'
  #   and t.relname = $1
  # order by
  #   t.relname,
  #   i.relname;
  def unique_indexes(table_name) do
    from t in PgClass,
      join: ix in PgIndex, on: t.oid == ix.indrelid,
      join: i  in PgClass, on: ix.indexrelid == i.oid,
      join: a  in PgAttribute, on: a.attrelid == t.oid,
     where: a.attnum in ix.indkey,
     where: t.relkind == "r",
     where: ix.indisunique == true,
     where: a.attname != "id",
     where: t.relname == ^table_name,
    select: %{table_name:  t.relname,
              index_name:  i.relname,
              column_name: a.attname,
             },
    order_by: [t.relname, i.relname]
  end
end
