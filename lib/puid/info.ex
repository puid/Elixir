# MIT License
#
# Copyright (c) 2019-2023 Knoxen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

defmodule Puid.Info do
  @moduledoc """
  Information regarding Puid module parameterization

  The `Puid.Info` struct has the following fields:

  | Field | Description |
  | ----- | ----------- |
  | char_set | pre-defined `Puid.Chars` atom or :custom |
  | characters | source characters |
  | entropy_bits | entropy bits for generated **puid** |
  | entropy_bits_per_char | entropy bits per character for generated **puid**s |
  | ere | **puid** entropy string representation efficiency |
  | length | **puid** string length |
  | rand_bytes | entropy source function |

  ```elixir
  iex> defmodule(CustomId, do: use(Puid, total: 1.0e04, risk: 1.0e12, chars: "thequickbrownfxjmpsvlazydg"))
  iex> CustomId.info()
  %Puid.Info{
    char_set: :custom,
    characters: "thequickbrownfxjmpsvlazydg",
    entropy_bits: 65.81,
    entropy_bits_per_char: 4.7,
    ere: 0.59,
    length: 14,
    rand_bytes: &:crypto.strong_rand_bytes/1
  }
  ```
  """

  defstruct characters: Puid.Chars.charlist!(:safe64) |> to_string(),
            char_set: :safe64,
            entropy_bits: 128,
            entropy_bits_per_char: 0,
            ere: 0,
            length: 0,
            rand_bytes: nil
end
