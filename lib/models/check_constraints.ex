defmodule Migratrex.CheckConstraints do
  use Migratrex.Model

  alias Migratrex.{TableConstraints,ConstraintColumnUsage}

  def check_constraints(table_name) do
    from tc in TableConstraints,
      join: ccu in ConstraintColumnUsage, on: ccu.constraint_name == tc.constraint_name,
     where: tc.constraint_type == "CHECK",
     where: tc.table_name == ^table_name,
  distinct: true,
    select: %{constraint_name:     tc.constraint_name,
              column_name:         ccu.column_name,
              table_name:          tc.table_name,
             },
    order_by: tc.constraint_name
  end
end
