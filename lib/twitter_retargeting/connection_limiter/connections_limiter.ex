defmodule TwitterRetargeting.ConnectionsLimiter do
  use GenServer
  alias TwitterRetargeting.ConnectionsLimiter.MethodUsageByToken
  @rate_limits %{
    follower_ids: %{count: 15, window: 15 * 60}
  }

  def start_link() do
    GenServer.start(__MODULE__ , nil, name: :connections_limiter )
  end

  def test_call(caller) do
    token  = TwitterRetargeting.Repo.get TwitterRetargeting.Token, 3
    tokens = [token]
    do_request(:follower_ids, tokens, caller, fn _ ->
      :timer.sleep(2000)
    end)
  end

  # client
  def do_request(method_name, tokens, caller, handler) do
    GenServer.cast(:connections_limiter, {:do_request, method_name, tokens, caller, handler})
  end

  def store_log(%MethodUsageByToken{} = log) do
    GenServer.call(:connections_limiter, {:store_log, log})
  end

  def rate_limits, do: @rate_limits

  # server
  def init(_) do
    state = %{ usage: %{} }
    {:ok, state}
  end

  def handle_cast({:do_request, method_name, tokens, caller, handler_func}, state) when is_atom(method_name) do
    {suitable_token, time_to_next_usage} = find_token_for_method(method_name, tokens, state)
    log_time = DateTime.add DateTime.utc_now, time_to_next_usage
    spawn(fn ->
      log = make_log(state, method_name, suitable_token, log_time)
      store_log(log)
      :timer.sleep(time_to_next_usage * 1000)
      configire_extwitter(suitable_token)
      handler_func.(caller)
    end)
    {:noreply, state}
  end

  def handle_call({:store_log, %MethodUsageByToken{method: method, screen_name: screen_name} = log}, _, state) do
    method_usages = state.usage[method] || %{}
    method_usages = Map.put(method_usages, screen_name, log)
    usage = state.usage |> Map.put(method, method_usages)
    state = state |> Map.put(:usage, usage)
    {:reply, state, state}
  end

  # private server

  defp find_token_for_method(method, tokens, state) do
    method_usages = get_in(state, [:usage, method]) || %{}
    token = tokens |> Enum.min_by( fn (token) ->
      method_usage = method_usages[token.screen_name]
      MethodUsageByToken.time_to_next_usage(method_usage)
    end)
    time_to_next_usage = MethodUsageByToken.time_to_next_usage(method_usages[token.screen_name])
    {token, time_to_next_usage}
  end

  defp make_log(state, method, token, time_at) do
    log = get_in(state, [:usage, method, token.screen_name])
    log = log || MethodUsageByToken.from_token_and_method(token, method)
    MethodUsageByToken.add_call(log, time_at)
  end

  defp configire_extwitter(%{oauth_token: token, oauth_token_secret: secret}) do
    token_conf = [
      access_token: token,
      access_token_secret: secret
    ]
    new_conf = ExTwitter.configure() |> Keyword.merge(token_conf)
    ExTwitter.configure(:procces, new_conf)
  end
end
