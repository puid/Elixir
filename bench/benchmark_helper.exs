defmodule BenchmarkHelper do
  @moduledoc """
  Common utilities for benchmark scripts
  """

  @doc """
  Times the execution of a function and prints the result with a label
  Returns the time in seconds
  """
  def time(function, label) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
    |> IO.inspect(label: label)
  end

  @doc """
  Formats the performance comparison between two times
  """
  def format_performance(time1, time2) when time1 < time2 do
    ratio = time2 / time1

    :io_lib.format("Puid is ~.2fx slower", [ratio])
    |> IO.iodata_to_binary()
  end

  def format_performance(time1, time2) do
    ratio = time1 / time2

    :io_lib.format("Puid is ~.2fx faster", [ratio])
    |> IO.iodata_to_binary()
  end

  @doc """
  Generates a metrics comparison table

  Takes library name, character counts and metrics for both libraries
  """
  def metrics_table(
        lib_name,
        lib_chars,
        lib_ere,
        lib_ete,
        puid_chars,
        puid_ere,
        puid_ete,
        trials,
        lib_time,
        puid_time
      ) do
    IO.puts("## Metrics Comparison")
    IO.puts("")

    IO.puts("  ERE: Entropy Representation Efficiency")
    IO.puts("  ETE: Entropy Transform Efficiency")
    IO.puts("  Perf: #{trials} trials")
    IO.puts("")

    lib_name_width = Kernel.max(String.length(lib_name), 13)

    IO.puts("  #{pad("Metric", 12)} #{pad(lib_name, lib_name_width)} #{pad("Puid", 6)} Comment")

    IO.puts(
      "  #{String.duplicate("-", 12)} #{String.duplicate("-", lib_name_width)} #{String.duplicate("-", 6)} #{String.duplicate("-", 25)}"
    )

    chars_comment = format_comment("Characters", lib_chars, puid_chars, :lower_better)
    ere_comment = format_comment("ERE", lib_ere, puid_ere, :higher_better)
    ete_comment = format_comment("ETE", lib_ete, puid_ete, :higher_better)
    perf_comment = format_comment("Perf", lib_time, puid_time, :lower_better)

    IO.puts(
      "  #{pad("Characters", 12)} #{pad(to_string(lib_chars), lib_name_width)} #{pad(to_string(puid_chars), 6)} #{chars_comment}"
    )

    IO.puts(
      "  #{pad("ERE", 12)} #{pad(to_string(lib_ere), lib_name_width)} #{pad(to_string(puid_ere), 6)} #{ere_comment}"
    )

    IO.puts(
      "  #{pad("ETE", 12)} #{pad(to_string(lib_ete), lib_name_width)} #{pad(to_string(puid_ete), 6)} #{ete_comment}"
    )

    lib_time_str = :io_lib.format("~.3f", [lib_time]) |> IO.iodata_to_binary()
    puid_time_str = :io_lib.format("~.3f", [puid_time]) |> IO.iodata_to_binary()

    IO.puts(
      "  #{pad("Perf (sec)", 12)} #{pad(lib_time_str, lib_name_width)} #{pad(puid_time_str, 6)} #{perf_comment}"
    )

    IO.puts("")
  end

  defp format_comment(metric, lib_val, puid_val, direction) do
    cond do
      lib_val == puid_val ->
        "Same"

      metric == "Characters" ->
        if puid_val < lib_val do
          percent = Float.round((1 - puid_val / lib_val) * 100, 1)
          "Puid is #{percent}% shorter"
        else
          percent = Float.round((puid_val / lib_val - 1) * 100, 1)
          "Puid is #{percent}% longer"
        end

      metric == "Perf" ->
        if puid_val < lib_val do
          ratio = Float.round(lib_val / puid_val, 2)
          "Puid is #{ratio}x faster"
        else
          ratio = Float.round(puid_val / lib_val, 2)
          "Puid is #{ratio}x slower"
        end

      direction == :higher_better ->
        if puid_val > lib_val do
          ratio = Float.round(puid_val / lib_val, 2)
          "Puid is #{ratio}x better"
        else
          ratio = Float.round(lib_val / puid_val, 2)
          "Puid is #{ratio}x worse"
        end

      true ->
        "Same"
    end
  end

  defp pad(string, width) do
    String.pad_trailing(string, width)
  end
end
