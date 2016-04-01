# Migratrex

A mix task that will generate models and tests based on existing database tables.

## Usage

  1. Add migratrex to your list of dependencies in `mix.exs`:

        def deps do
          [{:migratrex, "~> 0.0.1"}]
        end

  2. Run `mix migratrex`

  3. When the build is finished, you can remove the dependency
