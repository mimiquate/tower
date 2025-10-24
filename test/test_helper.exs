ExUnit.start()

new_config =
  Application.get_all_env(:logger)
  |> Keyword.put(:handle_sasl_reports, true)

Application.put_all_env(logger: new_config)

Logger.App.stop()

# Shutdown the application
Logger.App.stop()

# And start it without warnings
Application.put_env(:logger, :level, :error)
Application.start(:logger)
Application.delete_env(:logger, :level)
Logger.configure(level: :debug)
