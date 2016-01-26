defmodule LinkInfo do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    LinkInfo.Supervisor.start_link()
  end

 @backends [LinkInfo.SimpleWebPage, LinkInfo.GetLinkInfo]


  defmodule Result do
    defstruct url: nil, title: nil, description: nil, thumbnail: nil, redirections: nil, backend: nil
  end

  def get(url, opts \\ []) do
    @backends
      |> Enum.map(&spawn_url_query(&1, url))
      |> await_results(opts)
  end

  def start_link(backend, url, url_ref, owner) do
    backend.start_link(url, url_ref, owner)
  end

  defp spawn_url_query(backend, url) do
    url_ref = make_ref()
    opts = [backend, url, url_ref, self()]

    {:ok, pid} = Supervisor.start_child(LinkInfo.Supervisor, opts)

    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, url_ref}
  end


  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000

    timer = Process.send_after(self(), :timedout, timeout)
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, url_ref} = head

    receive do
      {:results, ^url_ref, results} -> 
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
      :timedout -> 
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout -> 
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end

  defp await_result([], acc, _) do
    acc
  end


  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)

    receive do
      :timedout -> :ok
    after
      0 -> :ok
    end
  end


end
