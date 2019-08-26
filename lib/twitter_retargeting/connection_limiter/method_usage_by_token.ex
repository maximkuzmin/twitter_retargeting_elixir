defmodule TwitterRetargeting.ConnectionsLimiter.MethodUsageByToken do
  alias TwitterRetargeting.ConnectionsLimiter.MethodUsageByToken

  defstruct [
    screen_name: nil,
    last_n_calls: [],
    method: nil,
    earliest_call: nil,
    calls_limit: nil,
    window: nil
  ]

  def from_token_and_method(%TwitterRetargeting.Token{} = token, method) when is_atom(method) do
    window = window(method)
    calls_limit = calls_limit(method)
    %MethodUsageByToken{
        screen_name: token.screen_name,
        method: method,
        calls_limit: calls_limit,
        window: window
    }
  end

  def add_call(%MethodUsageByToken{last_n_calls: last_calls} = model, time \\ DateTime.utc_now()) do
    last_n_calls = [ time | Enum.take(last_calls, model.calls_limit - 1) ]
    [earliest_call | _] = Enum.reverse(last_n_calls)
    %MethodUsageByToken{ model | last_n_calls: last_n_calls, earliest_call: earliest_call}
  end


  def can_be_used?(%MethodUsageByToken{} = model) do
    if time_to_next_usage(model) > 0,  do: false, else: true
  end

  def time_to_next_usage(%MethodUsageByToken{} = model) do
    if model.calls_limit > length(model.last_n_calls) do
      0
    else
      IO.puts("more calls then limit")
      time_passed = DateTime.diff DateTime.utc_now, model.earliest_call
      result_or_zero(model.window - time_passed)
    end
  end

  def time_to_next_usage(nil), do: 0

  defp calls_limit(method) when is_atom(method) do
    TwitterRetargeting.ConnectionsLimiter.rate_limits[method][:count]
  end

  defp window(method) when is_atom(method) do
    TwitterRetargeting.ConnectionsLimiter.rate_limits[method][:window]
  end

  defp result_or_zero(int) when int >= 0, do: int
  defp result_or_zero(int) when int  < 0, do: 0
end
