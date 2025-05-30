defmodule Crawly.Fetchers.Splash do
  @moduledoc """
  Implements Crawly.Fetchers.Fetcher behavior for Splash Javascript rendering.

  Splash is a lightweight QT based Javascript rendering engine. See:
  https://splash.readthedocs.io/

  Splash exposes the render.html endpoint which renders incoming requests sent
  with ?url get parameter.

  This particular Splash fetcher converts all requests made by Crawly to Splash
  requests, and  cleans up the final responses, by removing the Splash parts
  from the response.

  It's possible to start splash server in any documented way. One of the options
  is to run it locally with a help of docker:
  docker run -it -p 8050:8050 scrapinghub/splash

  In this case you have to configure the fetcher in the following way:
  `fetcher: {Crawly.Fetchers.Splash, [base_url: "http://localhost:8050/render.html"]},`
  """
  @behaviour Crawly.Fetchers.Fetcher

  require Logger

  @spec fetch(request, client_options) :: response
        when request: Crawly.Request.t(),
             client_options: [binary()],
             response: Crawly.Response.t()
  def fetch(request, client_options) do
    {base_url, other_options} = Keyword.pop(client_options, :base_url, nil)

    query_parameters =
      URI.encode_query(Keyword.put(other_options, :url, request.url))

    url =
      URI.merge(base_url, "?" <> query_parameters)
      |> URI.to_string()

    case HTTPoison.get(url, request.headers, request.options) do
      {:ok, response} ->
        new_request = %HTTPoison.Request{response.request | url: request.url}

        new_response = %HTTPoison.Response{
          response
          | request: new_request,
            request_url: request.url
        }

        {:ok, new_response}

      error ->
        error
    end
  end
end
