defmodule Phoenix.Endpoint.Watcher do
  @moduledoc false
  require Logger

  def start_link(cmd, args, opts) do
    Task.start_link(__MODULE__, :watch, [to_string(cmd), args, opts])
  end

  def watch(cmd, args, opts) do
    :ok = validate(cmd, args, opts)
    opts_with_defaults = Keyword.merge(
      [into: IO.stream(:stdio, :line), stderr_to_stdout: true], opts)

    try do
      System.cmd(cmd, args, opts_with_defaults)
    catch
      :error, :enoent ->
        relative = Path.relative_to_cwd(cmd)
        Logger.error "Could not start watcher #{inspect relative} from #{inspect opts[:cd]}, executable does not exist"
        exit(:shutdown)
    end
  end

  # We specially handle node to make sure we
  # provide a good getting started experience.
  defp validate("node", [script|_], opts) do
    cd = Keyword.fetch!(opts, :cd)
    script_path = Path.expand(script, cd)

    cond do
      !System.find_executable("node") ->
        Logger.error "Could not start watcher because \"node\" is not available. Your Phoenix " <>
                     "application is still running, however assets won't be compiled. " <>
                     "You may fix this by installing \"node\" and then running \"npm install\"."
        exit(:shutdown)

      not File.exists?(script_path) ->
        Logger.error "Could not start node watcher because script #{inspect script_path} does not " <>
                     "exist. Your Phoenix application is still running, however assets " <>
                     "won't be compiled. You may fix this by running \"npm install\"."
        exit(:shutdown)

      true -> :ok
    end
  end

  defp validate(_cmd, _args, _opts) do
    :ok
  end
end
