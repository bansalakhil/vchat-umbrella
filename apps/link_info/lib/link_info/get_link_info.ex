require IEx
defmodule LinkInfo.GetLinkInfo do
  require Logger
  
  alias LinkInfo.Result


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
    case HTTPoison.get(get_link_info_url(url), [], follow_redirect: true, max_redirect: 3) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # IEx.pry
        redirections = body 
        |> Floki.find(".redirections-list a[rel=nofollow]") 
        |> Floki.attribute("href") 

        %{redirections: redirections, url: url}

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
    results = [%Result{backend: "GetLinkInfo", url: result.url, redirections: result.redirections}]
    send(owner, {:results, url_ref, results})
  end

  defp get_link_info_url(url) do
    "http://getlinkinfo.com/info?link=" <> url
  end

end