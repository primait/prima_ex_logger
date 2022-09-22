# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2022-09-22

### Changed

- [Breaking] Loglevel configuration was removed from this library. Global `:logger` level should be configured instead.
- [Breaking] opentelemetry-related metadata is now automatically transformed by `prima_ex_logger` into a DataDog-friendly
  format. The behaviour can be customised using the new `opentelemetry_metadata` option.

## [0.2.5] - 2022-06-16

[Unreleased]: https://github.com/primait/lira/compare/0.3.0...HEAD
[0.3.0]: https://github.com/primait/lira/compare/0.2.5...0.3.0
[0.2.5]: https://github.com/primait/lira/releases/tag/0.2.5
