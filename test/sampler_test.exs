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
defmodule Puid.Test.EntropySampler do
  use ExUnit.Case, async: true

  test "invalid sampler option" do
    assert_raise Puid.Error, fn ->
      defmodule(InvalidEntropySamplerId,
        do: use(Puid, chars: :alphanum_lower, sampler: :unknown)
      )
    end
  end

  test "sampler is opt-in and default behavior is unchanged" do
    defmodule(BitShiftSamplerBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00, 0xC8, 0x2D>>)
    )

    defmodule(IntervalSamplerBytes,
      do: use(Puid.Util.FixedBytes, bytes: <<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00, 0xC8, 0x2D>>)
    )

    defmodule(BitShiftSamplerId,
      do:
        use(Puid,
          bits: 12,
          chars: :alphanum_lower,
          rand_bytes: &BitShiftSamplerBytes.rand_bytes/1
        )
    )

    defmodule(IntervalSamplerId,
      do:
        use(Puid,
          bits: 12,
          chars: :alphanum_lower,
          rand_bytes: &IntervalSamplerBytes.rand_bytes/1,
          sampler: :interval
        )
    )

    assert BitShiftSamplerId.generate() == "s9p"
    assert IntervalSamplerId.generate() == "45b"

    assert elem(BitShiftSamplerBytes.state(), 0) == 4
    assert elem(IntervalSamplerBytes.state(), 0) == 3
  end

  test "interval sampler consumes fewer source bytes on the same stream" do
    bytes = :binary.copy(<<0xD2, 0xE3, 0xE9, 0xFA, 0x19, 0x00, 0xC8, 0x2D>>, 512)

    defmodule(BitShiftUsageBytes, do: use(Puid.Util.FixedBytes, bytes: bytes))
    defmodule(IntervalUsageBytes, do: use(Puid.Util.FixedBytes, bytes: bytes))

    defmodule(BitShiftUsageId,
      do:
        use(Puid, bits: 256, chars: :alphanum_lower, rand_bytes: &BitShiftUsageBytes.rand_bytes/1)
    )

    defmodule(IntervalUsageId,
      do:
        use(Puid,
          bits: 256,
          chars: :alphanum_lower,
          rand_bytes: &IntervalUsageBytes.rand_bytes/1,
          sampler: :interval
        )
    )

    _ = BitShiftUsageId.generate()
    _ = IntervalUsageId.generate()

    assert elem(BitShiftUsageBytes.state(), 0) == 50
    assert elem(IntervalUsageBytes.state(), 0) == 38
    assert elem(IntervalUsageBytes.state(), 0) < elem(BitShiftUsageBytes.state(), 0)
  end
end
