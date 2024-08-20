# :european_castle: Tower

[![ci](https://github.com/mimiquate/tower/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mimiquate/tower/actions?query=branch%3Amain)
[![Hex.pm](https://img.shields.io/hexpm/v/tower.svg)](https://hex.pm/packages/tower)
[![Docs](https://img.shields.io/badge/docs-gray.svg)](https://hexdocs.pm/tower)

Solid and simple **error handling** and **reporting** in Elixir

## Usage

Tower is an Elixir package that tries to do one job well, **handle** error **events** in an Elixir application
**and inform** about them to configured **reporters** (one or many).

You can either write your own reporter or use any amount of the following reporters:

- [tower_rollbar](http://github.com/mimiquate/tower_rollbar)
- [tower_slack](http://github.com/mimiquate/tower_slack)

In case you use any of the above reporters, you don't need to include `tower` as a dependency. It will be a transitive dependency
of any of the above reporters.

### Writing a custom reporter

In case you don't want to use pre-built reporters and you want to write your own, first include
the core `tower` package:

```elixir
# mix.exs
def deps do
  [
    {:tower, "~> 0.5.0"}
  ]
end
```

Implement you custom reporting by implementing `Tower.Reporter` behaviour:

```elixir
# lib/my_app/error_reporter.ex
defmodule MyApp.ErrorReporter do
  use Tower.Reporter

  @impl true
  def report_event(%Tower.Event{} = event) do
    # Do whatever you want with event...

    # A `Tower.Event` is a struct with the following typespec:
    #
    # %Tower.Event{
    #   id: Uniq.UUID.t(),
    #   datetime: DateTime.t(),
    #   level: :logger.level(),
    #   kind: :error | :exit | :throw | :message,
    #   reason: Exception.t() | term(),
    #   stacktrace: Exception.stacktrace() | nil,
    #   log_event: :logger.log_event() | nil,
    #   plug_conn: struct() | nil,
    #   metadata: map()
    # }
  end
end
```

Tell `tower` you want your reporter to be informed about events.

```elixir
# config/runtime.exs

config :tower, reporters: [MyApp.ErrorReporter]
```

Finally attach Tower to your application.

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  ...

  def start(_type, _args) do
    Tower.attach()

    ...
  end

  ...
end
```

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
