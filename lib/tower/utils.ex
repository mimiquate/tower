defmodule Tower.Utils do
  def otp_application_data(pid_or_module) do
    case :application.get_application(pid_or_module) do
      {:ok, app_name} ->
        case :application.get_key(app_name, :vsn) do
          {:ok, app_version} when is_list(app_version) ->
            %{name: app_name, version: List.to_string(app_version)}

          _ ->
            %{name: app_name}
        end

      :undefined ->
        %{}
    end
  end
end
