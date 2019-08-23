defmodule TwitterRetargeting.Repo do
  use Ecto.Repo,
    otp_app: :twitter_retargeting,
    adapter: Ecto.Adapters.Postgres
end
