# 🏰 Tower

[![ci](https://github.com/mimiquate/tower/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mimiquate/tower/actions?query=branch%3Amain)
[![Hex.pm](https://img.shields.io/hexpm/v/tower.svg)](https://hex.pm/packages/tower)
[![Documentation](https://img.shields.io/badge/Documentation-purple.svg)](https://hexdocs.pm/tower)

Tower is a flexible error tracker for elixir applications.

It **listens** for **errors** in an elixir application **and informs** about them to
the configured list of **reporters** (one or many).

Any captured errors by `Tower` will be passed along to the list of
configured reporters, which can be set using the `:reporters` config key. For example:

```elixir
config :tower, :reporters, [TowerEmail]
```

You can pick any of the following reporters or [build your own](https://hexdocs.pm/tower/Tower.html#module-writing-a-custom-reporter).

- [`TowerBugsnag`](https://github.com/mimiquate/tower_bugsnag)
- [`TowerEmail`](https://github.com/mimiquate/tower_email)
- [`TowerErrorTracker`](https://github.com/mimiquate/tower_error_tracker)
- [`TowerHoneybadger`](https://github.com/mimiquate/tower_honeybadger)
- [`TowerRollbar`](https://github.com/mimiquate/tower_rollbar)
- [`TowerSentry`](https://github.com/mimiquate/tower_sentry)
- [`TowerSlack`](https://github.com/mimiquate/tower_slack)
- [`Tower.EphemeralReporter`](https://github.com/mimiquate/tower/blob/main/lib/tower/ephemeral_reporter.ex)

Community supported:

- [`ivanhercaz/tower_telegram`](https://github.com/ivanhercaz/tower_telegram)

Follow each reporter's README to get `Tower` installed and configured properly.

## Motivation

> Decoupled error capturing and error reporting in Elixir.

Say you need to add error tracking to your elixir app:

  - You decide what service you will use to send your errors to
  - You look for a good elixir library for that service
  - You configure it, deploy and start receiving errors there

Normally these libraries have to take care of a few responsibilities:

1. Capturing of errors (specific to language and runtime, i.e. Elixir and BEAM)
    - Automatic capturing via (at least one of):
        - Logger backend
        - Logger handler
        - Error logger handler
        - Telemetry event handler
        - Plugs
    - Manual capturing by providing a few public API functions the programmer to call if needed
1. Transform these errors into some format for the remote service (specific to remote service), e.g.
    - JSON for an HTTP API request
    - Subject and body for an e-mail message
1. Make a remote call (e.g. an HTTP request with the payload) to the remote service (specific to remote service)

```mermaid
flowchart LR
  A(Elixir App) --> B(Capture)
  subgraph Service Library
  B --> C("Format")
  C --> D("Report")
  end
  D --> E("ErrorTrackingService")
```

`Tower`, instead, takes care of capturing errors (number 1), giving them a well defined shape (`Tower.Event` struct)
and pass along this event to pre-configured but separate reporters which take care of the error reporting steps
(number 2 and 3) depending on which service or remote system they report to.

```mermaid
flowchart LR
  A(Elixir App) --> B(Capture)
  subgraph Tower
  B --> C("Build<br />Tower.Event")
  end
  subgraph A Tower.Reporter
  C --> D("Format")
  D --> E("Report")
  end
  E --> F("ErrorTrackingService")
```

### Consequences of this approach

#### 1. Capture once, report many

You can capture once and report to as many places as you want.

Possibly most will end up with just one reporter. But that doesn't mean you shouldn't be able to
easily have many, either temporarily or permanently if you need it.

Maybe you just need to have a backup in case one service goes downs or something unexpected happens.

Maybe you're trying out different providers and you want to report to the two for a while and compare
how they work, what features they have and how they display the information for you.

Maybe you're planning to switch, and you want to configure the new one without stopping to report to the
old one, at least for a while.

```mermaid
flowchart LR
  A(Elixir App) --> B(Capture)
  subgraph Tower
  B --> C("Build<br />Tower.Event")
  end
  subgraph Tower.Reporter 1
  C --> D("Format")
  D --> E("Report")
  end
  subgraph Tower.Reporter 2
  C --> F("Format")
  F --> G("Report")
  end
  E --> H("ErrorTrackingService 1")
  G --> I("ErrorTrackingService 2")
```

#### 2. Ease of switching services

You can switch from Error Tracking service provider without making any changes to your application error
capturing configuration or expect any change or regression with respect with capturing behavior.

You switch the reporter package, but tower still part of your application, and all the configuration specific
to tower and error capturing tactics is still valid and unchanged.

#### 3. Response to changes in Elixir and BEAM

Necessary future changes caused by deprecations and/or changes in error handling behavior in the BEAM or Elixir can be just
made in `Tower` without need to change any of the service specific reporters.

## License

Copyright 2024 Mimiquate

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
