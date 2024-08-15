# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2024-08-15

### Added

- `Tower.Event` `datetime` field with a `DateTime` value with microseconds precision.

### Removed

- `Tower.Event` `time` field.

### Changed

- `Tower.Event` `time` field replaced with `datetime` field.

## [0.2.0] - 2024-08-09

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

[0.3.0]: https://github.com/mimiquate/tower/compare/v0.2.0...v0.3.0/
[0.2.0]: https://github.com/mimiquate/tower/compare/v0.1.0...v0.2.0/
