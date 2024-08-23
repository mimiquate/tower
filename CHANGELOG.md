# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.5.0] - 2024-08-20

### Added

- Oban support
  - I.e: Automatic handling of errors occurring inside an Oban job perform.
- Bandit support
  - I.e: Automatic handling of errors occurring inside plug dispatch call when using `Bandit` adapter.

### Fixed

- Properly handle exits ocurring inside a plug dispatch call when using `Plug.Cowboy` adapter.

## [v0.4.0] - 2024-08-16

### Added

- `Tower.Event` `plug_conn` field with a `Plug.Conn` if available during handling.

### Removed

- Drop support for elixir 1.13 and 1.14 which were not yet fully integrated with `:logger` handlers, which
is the main way `tower` handles errors. Keep elixir 1.15+ for now.

## [v0.3.0] - 2024-08-15

### Added

- `Tower.Event` `datetime` field with a `DateTime` value with microseconds precision.

### Removed

- `Tower.Event` `time` field.

### Changed

- `Tower.Event` `time` field replaced with `datetime` field.

## [v0.2.0] - 2024-08-09

### Added

- New `Tower.Event` struct to represent and encapsulate any exception, exit, throw or message.
- New `time` field of `Tower.Event` struct, including the timestamp with microseconds precision.
- New `id` field of `Tower.Event` struct, including a timed-based sortable unique value (UUIDv7).
- Ablility to manually handle/report exceptions, exits and throws
  - `Tower.handle_exception/2,3`
  - `Tower.handle_exit/2,3`
  - `Tower.handle_throw/2,3`
- `metadata` field supporting user reported metadata
- `Tower.handle_caught/3,4` for easier handling of `catch kind, reason`
- `Tower.equal_or_greater_level?/2` to aid reporters in comparing log level, e.g. supporting per-reporter reporting level.

### Changed

- Reporters (those implementing `Tower.Reporter` behaviour) can now handle events with just one callback: `report_event/1`, in replacement of `report_exception/2,3`, `report_exit/2,3`, `report_throw/2,3` and `report_message/2,3` callbacks.

[v0.5.0]: https://github.com/mimiquate/tower/compare/v0.4.0...v0.5.0/
[v0.4.0]: https://github.com/mimiquate/tower/compare/v0.3.0...v0.4.0/
[v0.3.0]: https://github.com/mimiquate/tower/compare/v0.2.0...v0.3.0/
[v0.2.0]: https://github.com/mimiquate/tower/compare/v0.1.0...v0.2.0/
