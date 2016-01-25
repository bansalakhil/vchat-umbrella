require IEx
defmodule Vchat.LinkInfo.SimpleWebPage do
  require Logger
  
  alias Vchat.LinkInfo.Result


  def start_link(url, url_ref, owner) do
    Task.start_link(__MODULE__, :fetch, [url, url_ref, owner])
  end

  def fetch(url, url_ref, owner) do
    Logger.debug "#########################################   Start: #{url}       "
    url 
      |> Colorful.string(["green", "bright"])
      |> Logger.debug      


    # Make a request to url and extract title and description 
    result = 
    case HTTPoison.get(url, [], follow_redirect: true, max_redirect: 3) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        title_and_desc = body 
        |> Floki.find("head title, head meta[name=description]")

        title = title_and_desc |> Floki.text()

        description =  case title_and_desc |> Floki.attribute("content") do 
          [desc] -> desc
          _ -> nil
        end

        %{url: url, title: title, description: description}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.debug "#{url} Not found :("
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.debug "#{url} Error: #{reason} :("
        nil
      {:ok, _} ->
        Logger.debug "#{url}. may be redirect"
        nil
    end


    Logger.debug "#########################################   End: #{url}         "      

    send_result(result, url_ref, owner)
  end


  defp send_result(nil, url_ref, owner) do
    send(owner, {:results, url_ref, []})
  end
  defp send_result(result, url_ref, owner) do
    results = [%Result{backend: "SimpleWebPage", url: result.url, title: result.title, description: result.description}]
    send(owner, {:results, url_ref, results})
  end

end