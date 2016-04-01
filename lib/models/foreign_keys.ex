defmodule Migratrex.ForeignKeys do
  use Migratrex.Model

  alias Migratrex.{TableConstraints,KeyColumnUsage,ConstraintColumnUsage}

  # SELECT
  #   tc.constraint_name, tc.table_name, kcu.column_name,
  #   ccu.table_name AS foreign_table_name,
  #   ccu.column_name AS foreign_column_name
  # FROM
  #   information_schema.table_constraints AS tc
  #   JOIN information_schema.key_column_usage AS kcu
  #   ON tc.constraint_name = kcu.constraint_name
  #   JOIN information_schema.constraint_column_usage AS ccu
  #   ON ccu.constraint_name = tc.constraint_name
  #   WHERE constraint_type = 'FOREIGN KEY' AND tc.table_name='mytable';


  # SELECT t0."constraint_name", t0."table_name", k1."column_name", c2."table_name", c2."column_name"
  # FROM "information_schema"."table_constraints" AS t0
  # INNER JOIN "information_schema"."key_column_usage" AS k1 ON t0."constraint_name" = k1."constraint_name"
  # INNER JOIN "information_schema"."constraint_column_usage" AS c2 ON c2."constraint_name" = t0."constraint_name"
  # WHERE (t0."constraint_name" = 'FOREIGN KEY') AND (t0."table_name" = $1) ["accounts"] OK query=9.8ms queue=0.1ms

  def foreign_keys(table_name) do
    from tc in TableConstraints,
      join: kcu in KeyColumnUsage, on: tc.constraint_name == kcu.constraint_name,
      join: ccu in ConstraintColumnUsage, on: ccu.constraint_name == tc.constraint_name,
     where: tc.constraint_type == "FOREIGN KEY",
     where: tc.table_name == ^table_name,
    select: %{constraint_name:     tc.constraint_name,
              table_name:          tc.table_name,
              column_name:         kcu.column_name,
              foreign_table_name:  ccu.table_name,
              foreign_column_name: ccu.column_name,
             },
    order_by: tc.constraint_name
  end
end
