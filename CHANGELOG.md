# Changelog

## v2.0.6 (2023-01-06)

### code point validation

- Reject utf8 code points between tilde and inverse bang
- General code cleanup regarding code point validation

## v2.0.5 (2022-12-19)

### Further prevention of issue #12

- Further prevention of macro generated `encode` function dialyzer warnings.
  - All combinations of pairs/single/unchunked encoding chunk sizes are now covered.
- This change does not effect functionality.

## v2.0.4 (2022-12-10)

### Fix issue #12

- Prevent macro generated `encode` function from encoding bit chunks known to be `<<>>`. Prior code resulted in dialyzer warnings.
- This change does not effect functionality.

## v2.0.3 (2022-08-21)

### Fix

- Fix FixBytes test helper. Only effects deterministic "random" bytes testing.
- This change does not effect functionality.

### Add

- Add cross-repo data for testing. This allows for easier, systematic histogram testing.
- Check for invalid ascii in `Puid.Chars.charlist/1` and `Puid.Chars.charlist!/1` calls

## v2.0.2 (2022-07-07)

### Fix

- Issue #10: Error 1st argument not a bitstring raised when just defining

### Testing

- Added tests for above fix
- Reworked fixed bytes mock entropy source
- Added **MODULE**.Bits.reset/1 to facilitate fixed bytes testing

## v2.0.1 (2022-07-01)

### Tests

- Added test for 100% coverage.

## v2.0.0 (2022-06-30)

### Added

- ASCII encoding optimization
  - Use cross-product character pairs to encode larger bit chunks
  - Encode remaining bits via single character strategy
- Unicode and/or ASCII-Unicode mix encoding optimization
  - Encode bits via single character strategy
- Optimize bit filtering in selection of random indexes
  - Minimize bit shifting for out-of-range index slices
- Store unused source entropy bits between `puid` generation calls per `Puid` module
- Speed and efficiency are independent of pre-defined vs custom characters, including Unicode
- Simplify module creation API
  - `chars` option can be a pre-defined atom, a string or a charlist
- Pre-defined :symbol characters
- Add chi square tests of random ID character histograms
- CHANGELOG

### Changes

- Remove `CryptoRand` dependency
  - Functionality superseded by new, in-project optimizations
- Update timing tests
- README

### Breaking Changes

- Removed `charset` option for pre-defined characters
  - Use the `chars` option instead
- Removed pre-defined `printable_ascii`
  - Replaced by `safe_ascii` (no backslash, backtick, single-quote or double-quote)
- Reverse argument order for `Puid.Entropy` utility functions
  - Allows idiomatic Elixir use. Note these functions are rarely used directly.

### Deprecated

- Removed deprecated functions
  - `Puid.Entropy.bits_for_length/2`
  - `Puid.Entropy.bits_for_length!/2`

## v1.1.2 (2021-09-15)

### Added

- Resolve Elixir 1.11 compilation warnings

### Changes

- Project file structure

### Fixes

- Correct `Error.reason()` in function specs

## v1.1.1 (2020-01-15)

### Deprecated

- `Puid.Entropy.bits_for_length/2`
- `Puid.Entropy.bits_for_length!/2`

## v1.1.0 (2020-01-14)

### Added

- Refactor
  - `Puid.Entropy.bits_for_length/2` -> `Puid.Entropy.bits_for_len/2`
  - `Puid.Entropy.bits_for_length!/2` -> `Puid.Entropy.bits_for_len!/2`

### Changes

- Timing tests
- README

## v1.0.0 (2019-05-02)

Initial release
