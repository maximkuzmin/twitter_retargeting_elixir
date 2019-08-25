defmodule TwitterRetargeting.TwitterOauth do
  @callback_url "http://localhost:4000/twitter_oauth/callback"

  def user_authorization_url do
    token = ExTwitter.request_token @callback_url
    {:ok, url} = ExTwitter.authenticate_url(token.oauth_token)
    url
  end

  def get_access_token(verifier, token) do
  end
end
