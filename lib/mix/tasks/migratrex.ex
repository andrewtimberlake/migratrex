defmodule Mix.Tasks.Migratrex do
  use Mix.Task
  import Mix.Ecto

  alias Migratrex.{Tables,Columns,CheckConstraints,ForeignKeys,Utils}

  @shortdoc "Build models and tests from an existing database"

  @moduledoc """
  Build models and tests from an existing database

  ## Examples
      mix convertex
      mix convertex -r Custom.Repo

  ## Command line options
    * `-r`, `--repo` - the repo to migrate (defaults to `YourApp.Repo`)
  """

  @doc false
  def run(args) do
    repos = parse_repo(args)


    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      {:ok, _pid} = ensure_started(repo, [])

      namespace = Utils.get_namespace(repo)

      table_names = Tables.table_names |> repo.all
      Enum.each(table_names, fn(table_name) ->
        build_model_and_test(repo, namespace, table_name)
      end)
    end
  end

  defp build_model_and_test(repo, namespace, table_name) do
    models_directory = File.cwd!() |> Path.join("web/models")
    tests_directory = File.cwd!() |> Path.join("test/models")
    singularized_name = Utils.singularize(table_name)
    module_name = "#{Utils.capitalize(singularized_name)}"

    columns = Columns.columns(table_name) |> repo.all
    foreign_keys = ForeignKeys.foreign_keys(table_name) |> repo.all
    check_constraints = CheckConstraints.check_constraints(table_name) |> repo.all

    model_path = Path.join(models_directory, "#{singularized_name}.ex")
    build_model(model_path, table_name, namespace, module_name, columns, foreign_keys, check_constraints)
    test_path = Path.join(tests_directory, "#{singularized_name}_test.exs")
    build_test(test_path, namespace, module_name, columns)
  end

  defp build_model(model_path, table_name, namespace, module_name, columns, foreign_keys, check_constraints) do
    {:ok, file} = File.open(model_path, [:write])
    file
    |> write_line("defmodule #{namespace}.#{module_name} do")
    |> write_line("  use #{namespace}.Web, :model")
    |> write_line("")
    |> write_line("  schema \"#{table_name}\" do")
    |> add_fields(columns)
    |> add_timestamps(columns)
    |> write_line("  end")
    |> write_line("")
    |> add_changeset(columns, foreign_keys, check_constraints)
    |> write_line("end")
    File.close(file)
  end

  defp build_test(test_path, namespace, module_name, columns) do
    {:ok, file} = File.open(test_path, [:write])
    file
    |> write_line("defmodule #{namespace}.#{module_name}Test do")
    |> write_line("  use #{namespace}.ModelCase, async: true")
    |> write_line("")
    |> write_line("  alias #{namespace}.#{module_name}")
    |> write_line("")
    |> add_valid_attrs(columns)
    |> write_line("")
    |> add_valid_changeset_test(module_name)
    |> add_required_attributes_tests(module_name, columns)
    |> add_valid_lengths_tests(module_name, columns)
    |> write_line("end")
    File.close(file)
  end

  defp add_valid_attrs(file, columns) do
    valid_attrs = columns
    |> Enum.filter(&(&1.is_nullable == "NO" and &1.column_default == nil))
    |> Enum.map(fn(col) ->
      "#{col.column_name}: #{column_default(col)}"
    end)
    |> Enum.join(", ")
    write_line(file, "  @valid_attrs %{#{valid_attrs}}")
    file
  end

  defp add_valid_changeset_test(file, module_name) do
    file
    |> write_line("  test \"changeset with valid attributes\" do")
    |> write_line("    changeset = #{module_name}.changeset(%#{module_name}{}, @valid_attrs)")
    |> write_line("    assert changeset.valid?")
    |> write_line("  end")
  end

  defp add_required_attributes_tests(file, module_name, columns) do
    columns
    |> Enum.filter(&(&1.is_nullable == "NO" and &1.column_default == nil))
    |> Enum.each(fn(col) ->
      file
      |> write_line("")
      |> write_line("  test \"changeset requires attribute #{col.column_name}\" do")
      |> write_line("    changeset = #{module_name}.changeset(%#{module_name}{}, Map.delete(@valid_attrs, :#{col.column_name})")
      |> write_line("    assert [{:#{col.column_name}, \"can't be blank\"}] == changeset.errors")
      |> write_line("  end")
    end)
    file
  end

  defp add_valid_lengths_tests(file, module_name, columns) do
    columns
    |> Enum.filter(&(&1.character_maximum_length))
    |> Enum.each(fn(col) ->
      file
      |> write_line("")
      |> write_line("  test \"changeset requires attribute #{col.column_name}\" do")
      |> write_line("    changeset = #{module_name}.changeset(%#{module_name}{}, %{@valid_attrs | #{col.column_name} => String.duplicate(\"x\", #{col.character_maximum_length + 1})})")
      |> write_line("    assert [{unquote(attr), {\"should be at most %{count} character(s)\", [count: #{col.character_maximum_length}]}}] == changeset.errors")
      |> write_line("  end")
    end)
    file
  end

  @default_values %{
    ":string" => "\"aaa\"",
    ":integer" => "42",
    ":binary_id" => "Ecto.UUID.generate()",
    "Ecto.Date" => "Ecto.Date.utc()",
    "Ecto.DateTime" => "Ecto.DateTime.utc()",
    ":float" => "4.2"
  }
  defp column_default(column) do
    @default_values[field_type(column.data_type)]
  end

  defp add_changeset(file, columns, foreign_keys, check_constraints) do
    file
    |> write_line("  def changeset(model, params \\\\ :empty) do")
    |> write_line("    model")
    |> add_cast(columns)
    |> add_required(columns)
    |> add_validate_length(columns)
    |> add_check_constraints(check_constraints)
    |> add_foreign_keys(foreign_keys)
    |> write_line("  end")
  end

  defp add_cast(file, columns) do
    column_names = columns
    |> Enum.filter(&(! &1.column_name in ["id", "created_at", "inserted_at", "updated_at"]))
    |> Enum.map(&(&1.column_name))
    write_line(file, "    |> cast(params, ~w[#{Enum.join(column_names, " ")}])")
    file
  end

  defp add_required(file, columns) do
    required_column_names = columns
    |> Enum.filter(&(&1.is_nullable == "NO" and &1.column_default == nil))
    |> Enum.map(&(&1.column_name))
    write_line(file, "    |> validate_required(~w[#{Enum.join(required_column_names, " ")}]a)")
    file
  end

  defp add_validate_length(file, columns) do
    columns
    |> Enum.filter(&(&1.character_maximum_length))
    |> Enum.each(fn(col) ->
      write_line(file, "    |> validate_length(:#{col.column_name}, max: #{col.character_maximum_length})")
    end)

    file
  end

  defp add_foreign_keys(file, foreign_keys) do
    foreign_keys
    |> Enum.each(fn(fk) ->
      write_line(file, "    |> foreign_key_constraint(:#{fk.column_name}, name: :#{fk.constraint_name})")
    end)

    file
  end

  defp add_check_constraints(file, check_constraints) do
    check_constraints
    |> Enum.each(fn(chk) ->
      write_line(file, "    |> check_constraint(:#{chk.column_name}, name: :#{chk.constraint_name})")
    end)

    file
  end

  defp add_fields(file, columns) do
    Enum.each(columns, fn(col) ->
      unless col.column_name in ["id", "created_at", "updated_at"] do
        write_line(file, "    field :#{col.column_name}, #{field_type(col.data_type)}")
      end
    end)

    file
  end

  defp add_timestamps(file, columns) do
    timestamp_cols = columns
    |> Enum.filter(fn(col) -> col.column_name in ["created_at", "updated_at", "inserted_at"] end)
    |> Enum.map(fn(col) -> col.column_name end)

    timestamp_opts = timestamp_cols
    |> Enum.map(fn(col_name) ->
      case col_name do
        "created_at" -> "inserted_at: :created_at"
        "updated_at" -> nil
        _ -> col_name
      end
    end)
    |> Enum.filter(&(&1))

    timestamp_opts = unless "updated_at" in timestamp_cols do
      ["updated_at: nil" | timestamp_opts]
    else
      timestamp_opts
    end
    timestamp_opts = unless "created_at" in timestamp_cols do
      ["created_at: nil" | timestamp_opts]
    else
      timestamp_opts
    end

    if length(timestamp_cols) > 0 do
      write_line(file, "")
      write_line(file, "    timestamps #{Enum.join(timestamp_opts, ", ")}")
    end

    file
  end

  @field_types %{
    "array"                       => "{:array, unknown}",
    "bigint"                      => ":integer",
    "boolean"                     => ":boolean",
    "character varying"           => ":string",
    "date"                        => "Ecto.Date",
    "double precision"            => ":float",
    "integer"                     => ":integer",
    "jsonb"                       => ":map",
    "numeric"                     => ":float",
    "text"                        => ":string",
    "timestamp without time zone" => "Ecto.DateTime",
    "timestamp with time zone"    => "Ecto.DateTime",
    "uuid"                        => ":binary_id",
  }
  defp field_type(type), do: @field_types[String.downcase(type)] || "unknown"

  defp write_line(device, data) do
    :ok = IO.puts(device, data)
    device
  end
end

defmodule Migratrex.Utils do
  def singularize(word) do
    word
    |> String.replace(~r/ses$/, "ss") # double "s" which is removed at the end (hack)
    |> String.replace(~r/ches$/, "ch")
    |> String.replace(~r/ies$/, "y")
    |> String.replace(~r/s$/, "")
  end

  def capitalize(word) do
    word
    |> String.split(~r/_/)
    |> Enum.map(fn(<< first ::utf8 >> <> rest) ->
      String.upcase(<< first >>) <> rest
    end)
  end

  def get_namespace(repo), do: to_string(repo) |> String.replace(~r/Elixir\.(.+)\.Repo/, "\\1")
end
