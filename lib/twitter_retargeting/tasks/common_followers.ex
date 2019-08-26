defmodule TwitterRetargeting.Task.CommonFollowers do
  use GenServer

  #Client

  def run(caller, user, handlers) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {caller, user, handlers})
    :ok = GenServer.cast(pid, :run)
    pid
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def receive_results(pid, results, twitter_user) do
    GenServer.cast(pid, {:receive_results, results, twitter_user})
  end


  def report_results(pid) do
    GenServer.cast(pid, :report_results)
  end
  # Server

  def init({caller, user, handlers}) do
    user = TwitterRetargeting.Repo.preload(user, :tokens)
    state = %{
      init_handlers: handlers,
      caller: caller,
      user: user,
      handlers: [],
      tokens: user.tokens,
      results: %{}
    }
    {:ok, state}
  end

  def handle_cast(:run, state) do
    state = confirm_handlers(state)
    state.handlers |> Enum.each(&(collect_followers_for(&1, state) ))
    {:noreply, state}
  end

  def handle_cast({:receive_results, results, twitter_user}, state) do
    state = put_in state, [:results, twitter_user.screen_name], results
    check_if_all_users_ready(state)
    {:noreply, state}
  end

  def handle_cast(:report_results, %{results: results} = state) do
    intersection =
      results
        |> Map.values
        |> Enum.reduce(nil, fn(i, acc) ->
          i_set = MapSet.new(i)
          if acc, do: MapSet.intersection(i_set, acc), else: i_set
        end)

    # TODO: organize proper output
    intersection |> MapSet.to_list |> Enum.join(", ") |> IO.puts
    {:noreply, state}
  end

  def handle_call(:get_state, _from ,state) do
    {:reply, state, state}
  end

  defp check_if_all_users_ready(%{results: results, handlers: handlers}) do
    all_users_ready = handlers |> Enum.all?(fn (%{screen_name: screen_name}) ->
      !!results[screen_name]
    end)
    if all_users_ready, do: report_results(self())
  end

  defp confirm_handlers(%{init_handlers: handlers} = state) do
    confirmed_handlers = handlers
      |> Enum.map(fn (h) -> safe_get_user(h) end)
      |> Enum.filter(&(&1))

    Map.put(state, :handlers, confirmed_handlers)
  end

  defp safe_get_user(handler) do
    try do
      ExTwitter.user(handler)
    rescue
      _ -> nil
    end
  end

  defp collect_followers_for(handler, %{tokens: tokens}) do
    TwitterRetargeting.Task.GetFollowers.run(self(), tokens, handler)
  end
end
