defmodule TwitterRetargeting.Task.GetFollowers do
  use GenServer
  alias TwitterRetargeting.ConnectionsLimiter, as: Limiter
  alias TwitterRetargeting.Task.CommonFollowers

  # client

  def run(caller, tokens, twitter_user) do
    {:ok, pid } = GenServer.start_link(__MODULE__, {caller, tokens, twitter_user})
    :ok =  GenServer.cast(pid, :run)
    pid
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def set_result(pid, {ids, cursor}) do
    GenServer.cast(pid, {:set_result, ids, cursor})
  end

  def poll(pid), do: GenServer.cast(pid, :poll)

  def report_result(pid), do: GenServer.cast(pid, :report_result)


  # server

  def init({caller, tokens, twitter_user}) do
    state = %{
      caller: caller,
      tokens: tokens,
      twitter_user: twitter_user,
      results: MapSet.new,
      current_cursor: -1
    }
    {:ok, state}
  end

  def handle_cast(:run, state) do
    GenServer.cast(self(), :poll)
    {:noreply, state}
  end

  def handle_cast(:poll, state) do
    %{tokens: tokens, twitter_user: twitter_user, current_cursor: cursor} = state
    Limiter.do_request(:follower_ids, tokens, self(), fn caller ->
      %{items: items, next_cursor: next_cursor} = ExTwitter.follower_ids(twitter_user.id, cursor: cursor)
      set_result(caller, {items, next_cursor})
    end)
    {:noreply, state}
  end

  def handle_cast({:set_result, ids, cursor}, state) do
    new_results = MapSet.union state.results, MapSet.new(ids)
    state = state
      |> Map.put(:results, new_results)
      |> Map.put(:current_cursor, cursor)
    case cursor do
      0 -> report_result(self())
      _ -> poll(self())
    end
    {:noreply, state}
  end

  def handle_cast(:report_result, %{caller: caller} = state) do
    CommonFollowers.receive_results(caller, state.results, state.twitter_user)
    {:noreply, state}
  end

  def handle_call(:get_state, _from ,state) do
    {:reply, state, state}
  end
end
