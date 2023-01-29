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
defmodule Puid.Test.File.Data do
  use ExUnit.Case, async: true

  @tag :alphanum
  test "test alphanum file data" do
    Puid.Test.Data.test("alphanum")
  end

  @tag :alpha_10_lower
  test "test alpha 10 lower file data" do
    Puid.Test.Data.test("alpha_10_lower")
  end

  @tag :dingosky
  test "test dingosky file data" do
    Puid.Test.Data.test("dingosky")
  end

  @tag :safe32
  test "test safe32 file data" do
    Puid.Test.Data.test("safe32")
  end

  @tag :unicode
  test "test unicode file data " do
    Puid.Test.Data.test("unicode")
  end
end
