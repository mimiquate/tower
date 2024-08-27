defmodule Tower do
  @moduledoc """
  Decoupled error capturing and error reporting in Elixir.

  ## Motivation

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
      - Manual captruing by providing a few public API functions the programmer to call if needed
  1. Transform these errors into some format for the remote service (specific to remote service), e.g.
      - JSON for an HTTP API request
      - Subject and body for an e-mail message
  1. Make a remote call (e.g. an HTTP request with the payload) to the remote service (specific to remote service)

  ```mermaid
  flowchart LR;
    A(Elixir App) --> B(Capturing);
    subgraph Service Library
    B --> C("Transform/Format");
    C --> D("Report/Notify");
    end
    D --> E("ErrorTrackingService");
  ```

  `Tower`, instead, takes care of capturing errors (number 1), giving them a well defined shape (`Tower.Event` struct)
  and pass along this event to pre-configured but seprate reporters which take care of the error reporting steps
  (number 2 and 3) depending on which service or remote system they report to.

  ```mermaid
  flowchart LR;
    A(Elixir App) --> B(Capturing);
    subgraph Tower
    B --> C("Build Tower.Event");
    end
    subgraph A Tower.Reporter
    C --> D("Transform/Format");
    D --> E("Report/Notify");
    end
    E --> F("ErrorTrackingService");
  ```

  ### Consequences of this approach

  #### 1. Capture once, report many

  You can capture once and report to as many places as you want.

  Possibly most will end up with just one reporter. But that doesn't mean you shouldn't be able to
  easily have many, either temporarily or permantely if you need it.

  Maybe you just need to have a backup in case one service goes downs or something unexpected happens.

  Maybe you're trying out different providers and you want to report to the two for a while and compare
  how they work, what features they have and how they display the information for you.

  Maybe you're planning to switch, and you want to configure the new one without stopping to report to the
  old one, at least for a while.

  ```mermaid
  flowchart LR;
    A(Elixir App) --> B(Capturing);
    subgraph Tower
    B --> C("Build Tower.Event");
    end
    subgraph Tower.Reporter 1
    C --> D("Transform/Format");
    D --> E("Report/Notify");
    end
    subgraph Tower.Reporter 2
    C --> F("Transform/Format");
    F --> G("Report/Notify");
    end
    E --> H("ErrorTrackingService 1");
    G --> I("ErrorTrackingService 2");
  ```

  #### 2. Ease of switching services

  You can switch from Error Tracking service provider without making any changes to your application error
  capturing configuration or expect any change or regression with respect with capturing behvaior.

  You switch the reporter package, but tower still part of your application, and all the configuration specific
  to tower and error captruing tactics is still valid and unchanged.

  #### 3. Response to changes in Elixir and BEAM

  Necessary future changes caused by deprecations and/or changes in error handling behavior in the BEAM or Elixir can be just
  made in `Tower` without need to change any of the service specific reporters.

  ## Reporters

  As expalained in the Motivation section, any captured errors by `Tower` will be passed along to the list of
  configured reporters, which can be set in

      config :tower, :reporters, [...] # Defaults to [Tower.EphemeralReporter]

  So, in summary, you can either
    - Depend on `tower` package directly
      - play with the default built-in toy reporter `Tower.EphemeralReporter`, useful for dev and test
      - at some point for production [write your own custom reporter](#module-writing-a-custom-reporter)

  or
    - depend on one (or many) of the following reporters (separate packages) that build on top and depend on `tower`:
      - [`TowerEmail`](https://hexdocs.pm/tower_email) ([`tower_email`](https://hex.pm/packages/tower_email))
      - [`TowerRollbar`](https://hexdocs.pm/tower_rollbar) ([`tower_rollbar`](https://hex.pm/packages/tower_rollbar))
      - [`TowerSlack`](https://hexdocs.pm/tower_slack) ([`tower_slack`](https://hex.pm/packages/tower_slack))
    - and properly set the `config :tower, :reporters, [...]` configuration key

  ## Enabling automated exception handling

      Tower.attach()

  ## Disabling automated exception handling

      Tower.detach()

  ## Manual handling

  If either, for whatever reason when using automated exception handling, an exception condition is
  not reaching Tower handling, or you just need or want to manually handle possible errors, you can
  manually ask Tower to handle exceptions, throws or exits.

      try do
        # possibly carshing code
      rescue
        exception ->
          Tower.handle_exception(exception, __STACKTRACE__)
      catch
        :throw, value ->
          Tower.handle_throw(value, __STACKTRACE__)
        :exit, reason ->
          Tower.handle_exit(reason, __STACKTRACE__)
      end

  or more generally

      try do
        # possibly carshing code
      catch
        kind, reason ->
          Tower.handle_caught(kind, reason, __STACKTRACE__)
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

      # in some config/*.exs
      config :tower, reporters: [MyApp.ErrorReporter]

      # config/application.ex
      Tower.attach()

  `Tower.attach/0` will be responsible for registering the necessary handlers in your application
  so that any uncaught exception, uncaught throw or abnormal process exit is handled by Tower and
  passed along to the reporter.
  """

  alias Tower.Event

  @default_reporters [Tower.EphemeralReporter]

  @doc """
  Attaches the necessary handlers to automatically listen for application errors.

  [Adds](https://www.erlang.org/doc/apps/kernel/logger.html#add_handler/3) a new
  [`logger_handler`](https://www.erlang.org/doc/apps/kernel/logger_handler), which listens for all
  uncaught exceptions, uncaught throws, abnormal process exits, among other log events of interest.

  Additionally adds other handlers specifically tailored for some packages that
  do catch errors and have their own specific error handling and emit events instead
  of letting errors get to the logger handler, like oban or bandit.

  Note that `Tower.attach/0` is not a precondition for `Tower` `handle_*` functions to work
  properly and inform reporters. They are independent.
  """
  @spec attach() :: :ok
  def attach do
    :ok = Tower.LoggerHandler.attach()
    :ok = Tower.BanditExceptionHandler.attach()
    :ok = Tower.ObanExceptionHandler.attach()
  end

  @doc """
  Detaches the handlers.

  That means it stops the automatic handling of errors.
  You can still manually call `Tower` `handle_*` functions and reporters will be informed about
  those events.
  """
  @spec detach() :: :ok
  def detach do
    :ok = Tower.LoggerHandler.detach()
    :ok = Tower.BanditExceptionHandler.detach()
    :ok = Tower.ObanExceptionHandler.detach()
  end

  @doc """
  Asks Tower to handle a manually caught error.

  ## Example

      try do
        # possibly crashing code
      catch
        # Note this will also catch and handle normal (`:normal` and `:shutdown`) exits
        kind, reason ->
          Tower.handle_caught(kind, reason, __STACKTRACE__)
      end

  ## Options

    * `:plug_conn` - a `Plug.Conn` relevant to the event, if available, that may be used
    by reporters to report useful context information. Be aware that the `Plug.Conn` may contain
    user and/or system sensitive information, and it's up to each reporter to be cautious about
    what to report or not.
    * `:metadata` - a `Map` with additional information you want to provide about the event. It's
    up to each reporter if and how to handle it.

  """
  @spec handle_caught(Exception.kind(), Event.reason(), Exception.stacktrace()) :: :ok
  @spec handle_caught(Exception.kind(), Event.reason(), Exception.stacktrace(), Keyword.t()) ::
          :ok
  def handle_caught(kind, reason, stacktrace, options \\ []) do
    Event.from_caught(kind, reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a manually caught exception.

  ## Example

      try do
        # possibly crashing code
      rescue
        exception ->
          Tower.handle_exception(exception, __STACKTRACE__)
      end

  ## Options

    * Accepts same options as `handle_caught/4#options`.
  """
  @spec handle_exception(Exception.t(), Exception.stacktrace()) :: :ok
  @spec handle_exception(Exception.t(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_exception(exception, stacktrace, options \\ [])
      when is_exception(exception) and is_list(stacktrace) do
    Event.from_exception(exception, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a manually caught throw.

  ## Example

      try do
        # possibly throwing code
      catch
        thrown_value ->
          Tower.handle_throw(thrown_value, __STACKTRACE__)
      end

  ## Options

    * Accepts same options as `handle_caught/4#options`.
  """
  @spec handle_throw(term(), Exception.stacktrace()) :: :ok
  @spec handle_throw(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_throw(reason, stacktrace, options \\ []) do
    Event.from_throw(reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a manually caught exit.

  ## Example

      try do
        # possibly exiting code
      catch
        # Note this will also catch and handle normal (`:normal` and `:shutdown`) exits
        :exit, exit_reason ->
          Tower.handle_exit(exit_reason, __STACKTRACE__)
      end

  ## Options

    * Accepts same options as `handle_caught/4#options`.
  """
  @spec handle_exit(term(), Exception.stacktrace()) :: :ok
  @spec handle_exit(term(), Exception.stacktrace(), Keyword.t()) :: :ok
  def handle_exit(reason, stacktrace, options \\ []) do
    Event.from_exit(reason, stacktrace, options)
    |> report_event()
  end

  @doc """
  Asks Tower to handle a message of certain level.

  ## Examples

      Tower.handle_message(:emergency, "System is falling apart")

      Tower.handle_message(:error, "Unknown error has ocurred", metadata: %{any_key: "here"})

      Tower.handle_message(:info, "Just something interesting", metadata: %{interesting: "additional data"})

  ## Options

    * Accepts same options as `handle_caught/4#options`.
  """
  @spec handle_message(Event.level(), term(), Keyword.t()) :: :ok
  def handle_message(level, message, options \\ []) do
    Event.from_message(level, message, options)
    |> report_event()
  end

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

  defp report_event(%Event{} = event) do
    reporters()
    |> Enum.each(fn reporter ->
      async(fn ->
        reporter.report_event(event)
      end)
    end)
  end

  defp reporters do
    Application.get_env(:tower, :reporters, @default_reporters)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end
end
