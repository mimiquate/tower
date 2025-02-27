defmodule Tower do
  @moduledoc """
  Tower is a flexible error tracker for elixir applications.

  It **listens** for **errors** in an elixir application **and informs** about them to
  the configured list of **reporters** (one or many).

  You can either:
    - include `tower` package directly and [write your own custom reporter(s)](#module-writing-a-custom-reporter)

  Or:
    - include one (or many) of the following reporters (separate packages) that build on top of and depend on `tower`:
      - [`tower_bugsnag`](https://hexdocs.pm/tower_bugsnag)
      - [`tower_email`](https://hexdocs.pm/tower_email)
      - [`tower_error_tracker`](https://hexdocs.pm/tower_error_tracker)
      - [`tower_honeybadger`](https://hexdocs.pm/tower_honeybadger)
      - [`tower_rollbar`](https://hexdocs.pm/tower_rollbar)
      - [`tower_sentry`](https://hexdocs.pm/tower_sentry)
      - [`tower_slack`](https://hexdocs.pm/tower_slack)

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

  ## Reporters

  As explained in the Motivation section, any captured errors by `Tower` will be passed along to the list of
  configured reporters, which can be set in

      config :tower, :reporters, [...] # Defaults to [Tower.EphemeralReporter]

  So, in summary, you can either
    - Depend on `tower` package directly
      - play with the default built-in toy reporter `Tower.EphemeralReporter`, useful for dev and test
      - at some point for production [write your own custom reporter](#module-writing-a-custom-reporter)

  or
    - depend on one (or many) of the following reporters (separate packages) that build on top and depend on `tower`:
      - [`TowerBugsnag`](https://hexdocs.pm/tower_bugsnag) ([`tower_bugsnag`](https://hex.pm/packages/tower_bugsnag))
      - [`TowerEmail`](https://hexdocs.pm/tower_email) ([`tower_email`](https://hex.pm/packages/tower_email))
      - [`TowerErrorTracker`](https://hexdocs.pm/tower_error_tracker) ([`tower_error_tracker`](https://hex.pm/packages/tower_error_tracker))
      - [`TowerHoneybadger`](https://hexdocs.pm/tower_honeybadger) ([`tower_honeybadger`](https://hex.pm/packages/tower_honeybadger))
      - [`TowerRollbar`](https://hexdocs.pm/tower_rollbar) ([`tower_rollbar`](https://hex.pm/packages/tower_rollbar))
      - [`TowerSentry`](https://hexdocs.pm/tower_sentry) ([`tower_sentry`](https://hex.pm/packages/tower_sentry))
      - [`TowerSlack`](https://hexdocs.pm/tower_slack) ([`tower_slack`](https://hex.pm/packages/tower_slack))
    - and properly set the `config :tower, :reporters, [...]` configuration key

  ## Manual reporting

  If either, for whatever reason when using automated exception handling, an exception condition is
  not reaching Tower handling, or you just need or want to manually handle and report errors, you can
  manually ask Tower to report exceptions, throws or exits.

      try do
        # possibly crashing code
      rescue
        exception ->
          Tower.report_exception(exception, __STACKTRACE__)
      catch
        :throw, value ->
          Tower.report_throw(value, __STACKTRACE__)
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.report_exit(reason, __STACKTRACE__)
      end

  or more generally

      try do
        # possibly crashing code
      catch
        kind, reason ->
          Tower.report(kind, reason, __STACKTRACE__)
      end

  which will in turn call the appropriate function based on the caught `kind` and `reason` values

  ## Writing a custom reporter

      # lib/my_app/error_reporter.ex
      defmodule MyApp.ErrorReporter do
        @behaviour Tower.Reporter

        @impl true
        def report_event(%Tower.Event{} = event) do
          # do something with event

          # A `Tower.Event` is a struct with the following typespec:
          #
          # %Tower.Event{
          #   id: UUIDv7.t(),
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

      # in some config/*.exs
      config :tower, reporters: [MyApp.ErrorReporter]

  ## Configuration

  ### `reporters`

  List of reporters Tower should report events to.

  Default: `[Tower.EphemeralReporter]`

  Example:

  ```elixir
  config :tower, reporters: [TowerEmail]
  ```

  ### `log_level`

  `Logger` messages this level and above will be reported.

  Possible values are any of defined `Logger` levels (https://hexdocs.pm/logger/Logger.html#module-levels) or
  `:none` to disable reporting of `Logger` messages.

  Default: `:critical`

  Example:

  ```elixir
  config :tower, log_level: :error
  ```

  ### `ignored_exceptions`

  List of exceptions that Tower should ignore and not report.

  Default: `[]`

  Example:

  ```elixir
  config :tower, ignored_exceptions: [DBConnection.ConnectionError]
  ```

  ### `logger_metadata`

  List of keys that Tower should pick up from the current process `Logger.metadata` when reporting events.

  Default: `[]`

  Example:

  A common use case is setting `Logger.metadata(user_id: user.id)` at the start of your plugs or controller actions and
  configure Tower:

  ```elixir
  config :tower, logger_metadata: [:user_id]
  ```

  so that it's included in the reported exception or message event as extra metadata.

  Also if using Phoenix you can

  ```elixir
  config :tower, logger_metadata: [:request_id]
  ```

  so that you can co-relate your exceptions reports to the request id in your application logs.

  More about Logger metadata:
   - https://hexdocs.pm/logger/Logger.html#module-metadata
   - https://hexdocs.pm/logger/Logger.html#metadata/1
  """

  defmodule ReportEventError do
    defexception [:original, :reporter]

    def message(%__MODULE__{reporter: reporter, original: {kind, reason, stacktrace}}) do
      """
      The following error occurred while trying to report an event with reporter #{reporter}:

      #{Exception.format(kind, reason, stacktrace)}
      """
    end
  end

  defmodule TestException do
    defexception(
      message: "This is Tower forcing a test exception. You seeing this should be a good thing."
    )
  end

  alias Tower.Event

  @doc """
  Determines if a process exit `reason` is "normal".

  Those are `:normal`, `:shutdown` or `{:shutdown, _}`.
  Any other value is considered "non-normal" or "abnormal".

  Allowed in guard clauses.

  ## Examples

      iex> Tower.is_normal_exit(:normal)
      true

      iex> Tower.is_normal_exit(:shutdown)
      true

      iex> Tower.is_normal_exit({:shutdown, :whatever})
      true

      iex> Tower.is_normal_exit(:other_reason)
      false
  """
  defguard is_normal_exit(reason)
           when reason == :normal or reason == :shutdown or
                  (is_tuple(reason) and tuple_size(reason) == 2 and elem(reason, 0) == :shutdown)

  @doc """
  Attaches the necessary handlers to automatically listen for application errors.

  It is automatically called during application start.

  [Adds](https://www.erlang.org/doc/apps/kernel/logger.html#add_handler/3) a new
  [`logger_handler`](https://www.erlang.org/doc/apps/kernel/logger_handler), which listens for all
  uncaught exceptions, uncaught throws, abnormal process exits, among other log events of interest.

  Additionally adds other handlers specifically tailored for some packages that
  do catch errors and have their own specific error handling and emit events instead
  of letting errors get to the logger handler, like oban or bandit.
  """
  @spec attach() :: :ok | {:error, reason :: term()}
  def attach do
    with :ok <- Tower.LoggerHandler.attach(),
         :ok <- Tower.ObanExceptionHandler.attach() do
      :ok
    end
  end

  @doc """
  Detaches the handlers.

  That means it stops the automatic handling of errors.
  You can still manually call `Tower` `report_*` functions and reporters will be informed about
  those events.
  """
  @spec detach() :: :ok | {:error, reason :: term()}
  def detach do
    with :ok <- Tower.LoggerHandler.detach(),
         :ok <- Tower.ObanExceptionHandler.detach() do
      :ok
    end
  end

  @doc """
  Asks Tower to report a manually handled error.

  ## Example

      try do
        # possibly crashing code
      catch
        # Note this will also catch and handle normal (`:normal` and `:shutdown`) exits
        kind, reason ->
          Tower.report(kind, reason, __STACKTRACE__)
      end

  ## Options

    * `:plug_conn` - a `Plug.Conn` relevant to the event, if available, that may be used
    by reporters to report useful context information. Be aware that the `Plug.Conn` may contain
    user and/or system sensitive information, and it's up to each reporter to be cautious about
    what to report or not.
    * `:metadata` - a `Map` with additional information you want to provide about the event. It's
    up to each reporter if and how to handle it.

  """
  @spec report(Exception.kind(), Event.reason(), Exception.stacktrace(), Keyword.t()) ::
          :ok
  def report(kind, reason, stacktrace, options \\ []) do
    Event.from_caught(kind, reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to report an event.

  This can be useful if you have the need to manually run the reporter pipeline for a given `Tower.Event`.

  ## Example

      Tower.report(%Tower.Event{})
  """
  @spec report(%Tower.Event{}) :: :ok
  def report(%Tower.Event{} = event) do
    report_event(event)
  end

  @deprecated "Use Tower.report/3,4 instead."
  defdelegate handle_caught(kind, reason, stacktrace, options \\ []), to: __MODULE__, as: :report

  @doc """
  Asks Tower to report a manually handled exception.

  ## Example

      try do
        # possibly crashing code
      rescue
        exception ->
          Tower.report_exception(exception, __STACKTRACE__)
      end

  ## Options

    * Accepts same options as `report/4#options`.
  """
  @spec report_exception(Exception.t(), Exception.stacktrace(), Keyword.t()) :: :ok
  def report_exception(exception, stacktrace, options \\ [])
      when is_exception(exception) and is_list(stacktrace) do
    unless exception.__struct__ in ignored_exceptions() do
      Event.from_exception(exception, stacktrace, options)
      |> report_event()
    end
  end

  @deprecated "Use Tower.report_exception/2,3 instead."
  defdelegate handle_exception(exception, stacktrace, options \\ []),
    to: __MODULE__,
    as: :report_exception

  @doc """
  Asks Tower to report a manually handled throw.

  ## Example

      try do
        # possibly throwing code
      catch
        thrown_value ->
          Tower.report_throw(thrown_value, __STACKTRACE__)
      end

  ## Options

    * Accepts same options as `report/4#options`.
  """
  @spec report_throw(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def report_throw(reason, stacktrace, options \\ []) do
    Event.from_throw(reason, stacktrace, options)
    |> report_event()
  end

  @deprecated "Use Tower.report_throw/2,3 instead."
  defdelegate handle_throw(reason, stacktrace, options \\ []), to: __MODULE__, as: :report_throw

  @doc """
  Asks Tower to report a manually handled exit.

  ## Example

      try do
        # possibly exiting code
      catch
        :exit, reason when not Tower.is_normal_exit(reason) ->
          Tower.report_exit(reason, __STACKTRACE__)
      end

  ## Options

    * Accepts same options as `report/4#options`.
  """
  @spec report_exit(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def report_exit(reason, stacktrace, options \\ []) do
    Event.from_exit(reason, stacktrace, options)
    |> report_event()
  end

  @deprecated "Use Tower.report_exit/2,3 instead."
  defdelegate handle_exit(reason, stacktrace, options \\ []), to: __MODULE__, as: :report_exit

  @doc """
  Asks Tower to report a message of certain level.

  ## Examples

      Tower.report_message(:emergency, "System is falling apart")

      Tower.report_message(:error, "Unknown error has occurred", metadata: %{any_key: "here"})

      Tower.report_message(:info, "Just something interesting", metadata: %{interesting: "additional data"})

  ## Options

    * Accepts same options as `report/4#options`.
  """
  @spec report_message(Event.level(), term(), Keyword.t()) :: :ok
  def report_message(level, message, options \\ []) do
    Event.from_message(level, message, options)
    |> report_event()
  end

  @deprecated "Use Tower.report_message/2,3 instead."
  defdelegate handle_message(level, message, options \\ []), to: __MODULE__, as: :report_message

  @doc """
  Compares event level severity.

  Returns true if `level1` severity is equal or greater than `level2` severity.

  ## Examples

      iex> Tower.equal_or_greater_level?(:emergency, :error)
      true
      iex> Tower.equal_or_greater_level?(%Tower.Event{level: :info}, :info)
      true
      iex> Tower.equal_or_greater_level?(:warning, :critical)
      false
  """
  @spec equal_or_greater_level?(Event.t() | Event.level(), Event.level()) :: boolean()
  def equal_or_greater_level?(%Event{level: level1}, level2) when is_atom(level2) do
    equal_or_greater_level?(level1, level2)
  end

  def equal_or_greater_level?(level1, level2) when is_atom(level1) and is_atom(level2) do
    :logger.compare_levels(level1, level2) in [:gt, :eq]
  end

  @doc """
  Generates an exception and lets Tower handle it.

  Useful for testing Tower is well configuring and reporting errors during development.
  """
  @spec test() :: :ok
  def test do
    try do
      raise TestException
    rescue
      e ->
        Event.from_exception(e, __STACKTRACE__, metadata: %{test: true})
        |> report_event()

        :ok
    end
  end

  defp report_event(%Event{} = event) do
    reporters()
    |> Enum.each(fn reporter ->
      report_event(reporter, event)
    end)
  end

  defp report_event(reporter, %Event{reason: %ReportEventError{reporter: reporter}}) do
    # Ignore so we don't enter in a loop trying to report to the same buggy reporter
    :ignore
  end

  defp report_event(reporter, event) do
    try do
      reporter.report_event(event)
    rescue
      exception ->
        async(fn ->
          raise ReportEventError,
            reporter: reporter,
            original: {:error, exception, __STACKTRACE__}
        end)
    end
  end

  defp reporters do
    Application.fetch_env!(:tower, :reporters)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end

  defp ignored_exceptions do
    Application.fetch_env!(:tower, :ignored_exceptions)
  end
end
