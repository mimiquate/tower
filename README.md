# 🏰 Tower

[![ci](https://github.com/mimiquate/tower/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mimiquate/tower/actions?query=branch%3Amain)
[![Hex.pm](https://img.shields.io/hexpm/v/tower.svg)](https://hex.pm/packages/tower)
[![Documentation](https://img.shields.io/badge/Documentation-purple.svg)](https://hexdocs.pm/tower)

> Solid and simple **error handling** and **reporting** in Elixir.

Tower is an automated exception handler for elixir applications.

It tries to do one job well, **handle** uncaught **error events** in an elixir application
**and inform** pre-configured list of **reporters** (one or many) about these events.

You can either:

1. use `tower` package directly and [write your own custom reporter](https://hexdocs.pm/tower/Tower.html#module-writing-a-custom-reporter) or;
1. use one (or many) of the following reporters (separate packages) that build on top and depend on `tower`:
    - [`TowerEmail`](https://hexdocs.pm/tower_email) ([`tower_email`](https://hex.pm/packages/tower_email))
    - [`TowerRollbar`](https://hexdocs.pm/tower_rollbar) ([`tower_rollbar`](https://hex.pm/packages/tower_rollbar))
    - [`TowerSlack`](https://hexdocs.pm/tower_slack) ([`tower_slack`](https://hex.pm/packages/tower_slack))

## Installation

```elixir
# mix.exs

def deps do
  [
    {:tower, "~> 0.5.1"}
  ]
end
```

## Usage

- [Documentation](https://hexdocs.pm/tower)

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
