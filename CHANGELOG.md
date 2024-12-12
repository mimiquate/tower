# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.3] - 2024-12-12

### Added

- Ability to include contents of Logger.metadata in exception report by explicitly listing keys with `config :tower, logger_metadata: [...]`

## [0.7.3] - 2024-11-25

### Fixed

- Small workaround specific to `TowerErrorTracker` reporter package, to fix reporting of `ErrorTracker.set_context`.

## [0.7.2] - 2024-11-19

### Fixed

- Fixes (by removing) unnecessary compile-time dependency on plug from inside Tower.LoggerHandler

## [0.7.1] - 2024-11-19

### Fixed

- Fixes an error inside Tower when reporting non normalized exceptions (e.g. `:badarith`) when using Bandit

## [0.7.0] - 2024-11-19

### Fixed

- Properly report uncaught throw as a `:throw` event (instead of `:exit`) when using Bandit.

### Changed

- Updates optional dependency on `bandit` version requirement from `"~> 1.5.0"` to `"~> 1.6"`.

## [0.6.5] - 2024-11-18

### Added

- `Tower.Event` includes new field called `by` that states what was the source of the event.

### Fixed

- Declares optional dependency on bandit (with proper version range requiremente) to make sure tower is running with a compatible version of bandit.

## [0.6.4] - 2024-11-11

### Fixed

- Properly don't report non-5xx (e.g. 400 bad request) status code exceptions when using Bandit.

## [0.6.3] - 2024-10-24

### Fixed

- Properly report runtime exceptions in Phoenix controller actions when using `Bandit.PhoenixAdapter` in `Phoenix.Endpoint`.

## [0.6.2] - 2024-10-16

### Changed

- Renamed functions:
  - `Tower.handle_exception/2,3` to `Tower.report_exception/2,3`
  - `Tower.handle_exit/2,3` to `Tower.report_exit/2,3`
  - `Tower.handle_throw/2,3` to `Tower.report_throw/2,3`
  - `Tower.handle_caught/3,4` to `Tower.report/3,4`

Non-breaking change. Original functions still work, but deprecated.

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

[0.7.4]: https://github.com/mimiquate/tower/compare/v0.7.3...v0.7.4/
[0.7.3]: https://github.com/mimiquate/tower/compare/v0.7.2...v0.7.3/
[0.7.2]: https://github.com/mimiquate/tower/compare/v0.7.1...v0.7.2/
[0.7.1]: https://github.com/mimiquate/tower/compare/v0.7.0...v0.7.1/
[0.7.0]: https://github.com/mimiquate/tower/compare/v0.6.5...v0.7.0/
[0.6.5]: https://github.com/mimiquate/tower/compare/v0.6.4...v0.6.5/
[0.6.4]: https://github.com/mimiquate/tower/compare/v0.6.3...v0.6.4/
[0.6.3]: https://github.com/mimiquate/tower/compare/v0.6.2...v0.6.3/
[0.6.2]: https://github.com/mimiquate/tower/compare/v0.6.1...v0.6.2/
[0.6.1]: https://github.com/mimiquate/tower/compare/v0.6.0...v0.6.1/
[0.6.0]: https://github.com/mimiquate/tower/compare/v0.5.3...v0.6.0/
[0.5.3]: https://github.com/mimiquate/tower/compare/v0.5.2...v0.5.3/
[0.5.2]: https://github.com/mimiquate/tower/compare/v0.5.1...v0.5.2/
[0.5.1]: https://github.com/mimiquate/tower/compare/v0.5.0...v0.5.1/
[0.5.0]: https://github.com/mimiquate/tower/compare/v0.4.0...v0.5.0/
[0.4.0]: https://github.com/mimiquate/tower/compare/v0.3.0...v0.4.0/
[0.3.0]: https://github.com/mimiquate/tower/compare/v0.2.0...v0.3.0/
[0.2.0]: https://github.com/mimiquate/tower/compare/v0.1.0...v0.2.0/
