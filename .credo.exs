%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "mix.exs"],
        excluded: ["_build/", "deps/", "test/"]
      },
      strict: true,
      parse_timeout: 20000,
      checks: [
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
        {Credo.Check.Refactor.LongQuoteBlocks, false},
        {Credo.Check.Warning.UnusedRegexOperation, []},
        {Credo.Check.Warning.UnusedKeywordOperation, []},
        {Credo.Check.Warning.UnusedEnumOperation, []},
        {Credo.Check.Warning.UnsafeToAtom, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.TagFIXME, false},
        {Credo.Check.Design.TagTODO, false}
      ]
    }
  ]
}

