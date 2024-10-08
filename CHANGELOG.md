# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.1] - 2024-10-08

### Fixed

- Properly report (don't ignore) messages that should be reported per their log level that have the
`:logger` format of `{format, format_args}`, sometimes coming from Erlang/OTP code, when using log
functions that pass format and arguments instead of strings (see https://www.erlang.org/doc/apps/kernel/logger.html#log/3).

## [0.6.0] - 2024-10-04

### Added

- New utility to test `:tower` is well configured and working. Either by invoking mix task `mix tower.test` or
directly calling function `Tower.test/0`. It will generate a test exception and report it to whichever reporters
you have configured.

### Changed

- `Tower.EphemeralReporter` is now automatically started as a child of `Tower.Supervisor`. If you were including it as
a child of your application supervisor, you can safely remove it.
- `Tower.EphemeralReporter` now keeps only the 50 most recent events to be light on resource consumption, as initially
intened.
- `Tower.attach()` is now automatically called during `Tower` start. You no longer need to manually call it as part of
your application `start` function. Keeping it won't fail but it is a no-operation. You can safely remove it.

## [0.5.3] - 2024-09-24

### Added

- `Tower.ReportEventError` improved error message prints original exception message also. Helps when building and
debugging errors in reporters implementing `Tower.Reporter` behavior.

## [0.5.2] - 2024-09-16

### Added

- `Tower.is_normal_exit` function and guard for use when manually catching exits

### Fixed

- Bug/error in one reporter doesn't affect other reporters

## [0.5.1] - 2024-08-23

### Added

- Documentation improvements

## [0.5.0] - 2024-08-20

### Added

- Oban support
  - I.e: Automatic handling of errors occurring inside an Oban job perform.
- Bandit support
  - I.e: Automatic handling of errors occurring inside plug dispatch call when using `Bandit` adapter.

### Fixed

- Properly handle exits ocurring inside a plug dispatch call when using `Plug.Cowboy` adapter.

## [0.4.0] - 2024-08-16

### Added

- `Tower.Event` `plug_conn` field with a `Plug.Conn` if available during handling.

### Removed

- Drop support for elixir 1.13 and 1.14 which were not yet fully integrated with `:logger` handlers, which
is the main way `tower` handles errors. Keep elixir 1.15+ for now.

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

[0.6.1]: https://github.com/mimiquate/tower/compare/v0.6.0...v0.6.1/
[0.6.0]: https://github.com/mimiquate/tower/compare/v0.5.3...v0.6.0/
[0.5.3]: https://github.com/mimiquate/tower/compare/v0.5.2...v0.5.3/
[0.5.2]: https://github.com/mimiquate/tower/compare/v0.5.1...v0.5.2/
[0.5.1]: https://github.com/mimiquate/tower/compare/v0.5.0...v0.5.1/
[0.5.0]: https://github.com/mimiquate/tower/compare/v0.4.0...v0.5.0/
[0.4.0]: https://github.com/mimiquate/tower/compare/v0.3.0...v0.4.0/
[0.3.0]: https://github.com/mimiquate/tower/compare/v0.2.0...v0.3.0/
[0.2.0]: https://github.com/mimiquate/tower/compare/v0.1.0...v0.2.0/
