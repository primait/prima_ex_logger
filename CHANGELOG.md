# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.5.1] - 2025-09-22

### Fixed

- Log correlation with opentelementry_api newer than 1.4.1

---

## [0.5.0] - 2024-06-18

### Changed

- **Breaking**: bump MSEV to 1.12

---

## [0.4.1] - 2024-03-11

### Fixed

- PrimaExLogger was raising error while handling `:flush` event

---

## [0.4.0] - 2023-05-17

### Added

- `:country` configuration option

## [0.3.1] - 2023-04-19

### Fixed

- Properly set the trace correlation metadata fields ([#55](https://github.com/primait/prima_ex_logger/pull/55)).

## [0.3.0] - 2022-09-22

### Changed

- [Breaking] Loglevel configuration was removed from this library. Global `:logger` level should be configured instead.
- [Breaking] opentelemetry-related metadata is now automatically transformed by `prima_ex_logger` into a DataDog-friendly
  format. The behaviour can be customised using the new `opentelemetry_metadata` option.

## [0.2.5] - 2022-06-16




[Unreleased]: https://github.com/primait/prima_ex_logger/compare/0.5.1...HEAD
[0.5.1]: https://github.com/primait/prima_ex_logger/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/primait/prima_ex_logger/compare/0.4.1...0.5.0
[0.4.1]: https://github.com/primait/prima_ex_logger/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/primait/prima_ex_logger/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/primait/prima_ex_logger/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/primait/prima_ex_logger/compare/0.2.5...0.3.0
[0.2.5]: https://github.com/primait/prima_ex_logger/releases/tag/0.2.5
