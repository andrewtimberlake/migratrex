# Migratrex

A mix task that will generate models and tests based on existing database tables.

## Usage

  1. Add migratrex to your list of dependencies in `mix.exs`:
     ```elixir
        def deps do
          [{:migratrex, "~> 0.0.1"}]
        end
     ```

  2. If you want foreign key and check constraints included, make sure you use a user with superuser permissions for the run.

  3. Run `mix migratrex`

  4. When the build is finished, you can remove the dependency

## Database table
```psql
                                Table "public.users"
      Column       |            Type             |                     Modifiers
-------------------+-----------------------------+----------------------------------------------------
 id                | integer                     | not null default nextval('users_id_seq'::regclass)
 account_id        | integer                     |
 username          | character varying(50)       | not null
 email             | character varying(255)      | not null
 hashed_password   | character varying(255)      |
 created_at        | timestamp without time zone |
 updated_at        | timestamp without time zone |
Indexes:
    "users_pkey" PRIMARY KEY, btree (id)
    "uniq_username_per_account" UNIQUE CONSTRAINT, btree (account_id, username)
Check constraints:
    "some_check" CHECK (...)
Foreign-key constraints:
    "users_acount_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id)

```

## Example model file

```elixir
defmodule YourApp.User do
  use YourApp.Web, :model

  schema "users" do
    field :account_id, :integer
    field :username, :string
    field :email, :string
    field :hashed_password, :string
    field :active, :boolean

    timestamps inserted_at: :created_at
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w[account_id first_name last_name username email hashed_password active])
    |> validate_required(~w[account_id username email]a)
    |> validate_length(:username, max: 50)
    |> validate_length(:email, max: 255)
    |> validate_length(:hashed_password, max: 255)
    |> check_constraint(:username, name: :some_check)
    |> foreign_key_constraint(:account_id, name: :users_account_id_fkey)
  end
end
```

## Example test file
```elixir
defmodule YourApp.UserTest do
  use YourApp.ModelCase, async: true

  alias YourApp.User

  @valid_attrs %{account_id: 42, username: "aaa", email: "aaa"}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset requires attribute account_id" do
    changeset = Company.changeset(%Company{}, Map.delete(@valid_attrs, :account_id)
    assert [{:account_id, "can't be blank"}] == changeset.errors
  end

  test "changeset requires attribute username" do
    changeset = Company.changeset(%Company{}, Map.delete(@valid_attrs, :username)
    assert [{:username, "can't be blank"}] == changeset.errors
  end

  test "changeset requires attribute email" do
    changeset = Company.changeset(%Company{}, Map.delete(@valid_attrs, :email)
    assert [{:email, "can't be blank"}] == changeset.errors
  end

  test "changeset requires length of username to be at most 50" do
    changeset = User.changeset(%User{}, %{@valid_attrs | username => String.duplicate("x", 101)})
    assert [{:username, {"should be at most %{count} character(s)", [count: 50]}}] == changeset.errors
  end

  test "changeset requires length of email to be at most 255" do
    changeset = User.changeset(%User{}, %{@valid_attrs | email => String.duplicate("x", 256)})
    assert [{:email, {"should be at most %{count} character(s)", [count: 255]}}] == changeset.errors
  end

  test "changeset requires length of hashed_password to be at most 255" do
    changeset = User.changeset(%User{}, %{@valid_attrs | hashed_password => String.duplicate("x", 256)})
    assert [{:hashed_password, {"should be at most %{count} character(s)", [count: 255]}}] == changeset.errors
  end
end
```