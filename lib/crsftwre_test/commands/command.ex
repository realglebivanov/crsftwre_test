defmodule CrsftwreTest.Commands.Command do
  @moduledoc false

  @type t :: %__MODULE__{
          name: String.t(),
          command: String.t(),
          requires: [String.t()]
        }

  @enforce_keys [:name, :command, :requires]
  defstruct @enforce_keys
end
