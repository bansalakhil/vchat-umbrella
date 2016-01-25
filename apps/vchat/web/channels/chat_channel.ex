require IEx
defmodule Vchat.ChatChannel do
  use Phoenix.Channel
  require Logger
  
  import Ecto
  import Ecto.Query

  # alias Vchat.Message
  alias Vchat.User
  alias Vchat.MessageAssignment
  alias Vchat.Message

  @url_pattern  ~r/(http|https\:\/\/)[a-zA-Z0-9\.\/\?\:@\-_=#]+\.[a-zA-Z0-9\.\/\?\:@\-_=#]*/
  
  intercept ["chat:new_msg", "chat:old_messages", "chat:link_info"]
  
  def join("chat:*", message, socket) do
    :timer.send_interval(60000, :ping)
    send(self, {:after_join, message})
    {:ok, socket}
  end
    
  def join("chat:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end    
 
  def handle_info({:after_join, _msg}, socket) do
    record_last_activity(socket)
    broadcast! socket, "user:entered_in_lobby", %{ inactive_users: get_inactive_users, user: socket.assigns[:current_user].username}
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    push socket, "chat:user_status", %{inactive_users: get_inactive_users, body: "ping"}
    {:noreply, socket}
  end

  def handle_info({:link_info, message}, socket) do
    parse_links(socket, message)
    {:noreply, socket}
  end


  def handle_in("chat:mark_seen", %{"message_ids" => message_ids}, socket) do
    current_user = socket.assigns[:current_user]
    mark_messages_seen(current_user, message_ids)
    {:noreply, socket}
  end 

  def handle_in("chat:record_last_activity", %{"msg" => _msg}, socket) do
    record_last_activity(socket)
    {:noreply, socket}
  end  

  def handle_in("chat:old_messages", %{"msg" => _msg}, socket) do
    current_user = socket.assigns[:current_user]
    received_messages = get_old_messages(socket)
    broadcast! socket, "chat:old_messages", %{ received_messages: received_messages, user: current_user.username}
    {:noreply, socket}
  end  

  def handle_in("chat:new_msg", %{"msg" => msg, "type" => type, "to" => to}, socket) do
    record_last_activity(socket)
    from_user = socket.assigns[:current_user]

    "Message Received:==>  Type: #{type}, From: #{from_user.username}, To: #{to}, Message: #{msg}"
      |> Colorful.string(["green", "bright"])
      |> Logger.debug

    message_changeset = build_assoc(from_user, :sent_messages, body: msg, msg_type: type, group_name: to)
    # IEx.pry
    # 
    message = case Vchat.Repo.insert(message_changeset) do
      {:ok, message} ->
        if type != "group" do
          to_user = Vchat.Repo.get_by(User, username: to)
          # IEx.pry
          insert_message_assignment(message, to_user)
          insert_message_assignment(message, from_user)
        else 
          users = Vchat.Repo.all(User)  
          Enum.each(users, fn(to_user) ->
          insert_message_assignment(message, to_user)
          end)
        end

        broadcast! socket, "chat:new_msg", %{mid: message.id, from: from_user.username, to: to, msg: msg, seen: false, msg_type: message.msg_type, group_name: message.group_name, time: "#{Ecto.DateTime.to_string(message.inserted_at)}"}
        message

      {:error, _message_changeset} ->
        nil
    end
    :timer.send_after(2000, {:link_info, message})
    # parse_links(socket, message)
    {:noreply, socket}
  end  

  def handle_out("chat:new_msg", payload, socket) do
    if (payload.msg_type == "group") || (socket.assigns[:current_user].username == payload.to) || (socket.assigns[:current_user].username == payload.from) do
      push socket, "chat:new_msg", payload
    end
    {:noreply, socket}
  end

  def handle_out("chat:old_messages", payload, socket) do
    if (socket.assigns[:current_user].username == payload.user)  do
      push socket, "chat:old_messages", payload
    end
    {:noreply, socket}
  end  

  def handle_out("chat:link_info", payload, socket) do
    message = Vchat.Repo.get(Message, payload.mid)
    receiver_ids = assoc(message, :message_assignments) |> select([ma], ma.receiver_id) |> Vchat.Repo.all
    # Enum.any?(receiver_ids, fn(x) -> x == socket.assigns[:current_user].id end)
    if ( Enum.any?(receiver_ids, fn(x) -> x == socket.assigns[:current_user].id end)  )  do
      push socket, "chat:link_info", payload
    end

    {:noreply, socket}  
  end  

  def terminate(reason, socket) do
    mark_offline(socket)
    broadcast! socket, "chat:user_offline", %{username: socket.assigns[:current_user].username}
    Logger.debug"> leave #{inspect reason}"
    :ok
  end












  defp record_last_activity(socket) do
    Vchat.Repo.update(User.record_last_activity(socket.assigns[:current_user]))
  end

  defp mark_offline(socket) do
    Vchat.Repo.update(User.mark_offline(socket.assigns[:current_user]))
  end

  defp get_inactive_users do
    users = Vchat.Repo.all(from u in User, where: u.online == false or u.last_activity_at < datetime_add(^Ecto.DateTime.utc, -60, "second") or is_nil(u.last_activity_at)  )
    Enum.map(users, &(&1.username))
  end

  defp get_old_messages(socket) do 
    # socket.assigns[:current_user]
    user = socket.assigns[:current_user] 
    message_assignments = MessageAssignment |> where(receiver_id: ^user.id) |> limit(100) |> preload(message: [:sender, :links]) |> Vchat.Repo.all
    Enum.map(message_assignments, fn(ma) -> 
      links = Enum.map(ma.message.links, fn(link) -> 
        %{url: link.url, title: link.title, description: link.description}
      end)
      %{mid: ma.message.id, from: ma.message.sender.username, to: user.username, msg: ma.message.body, links: links, seen: ma.seen, msg_type: ma.message.msg_type, group_name: ma.message.group_name, time: "#{Ecto.DateTime.to_string(ma.message.inserted_at)}"}  
    end)
  end

  defp insert_message_assignment(message, user) do
    message_assignments_changeset = build_assoc(message, :message_assignments,  receiver_id: user.id);
    Vchat.Repo.insert(message_assignments_changeset);
  end

  defp mark_messages_seen(user, m_ids) do
    # IEx.pry
    MessageAssignment 
      |> update([ma], set: [seen: true]) 
      |> join(:inner, [ma], m in assoc(ma, :message)) 
      |> where([ma, m], ma.message_id in ^m_ids) 
      |> where([ma, m], ma.receiver_id == ^user.id) 
      |>Vchat.Repo.update_all([])
  end

  defp parse_links(socket, message) do
    message.body
      |> Colorful.string(["green", "bright"])
      |> Logger.debug

    urls = Regex.scan(@url_pattern, message.body)
    urls = Enum.map(urls, fn([x | _ ] ) -> x end)


    pids = Enum.map(urls, fn(url) ->  
      get_link_async = Task.async(fn -> get_link_info(socket, url, message)     end)
      # Task.await(get_link_async, 20000)
    end    
    )
   Enum.map(pids, fn(pid) -> Task.await(pid, 20000) end)

  end

  defp broadcast_link_info(socket, message, title, description, url) do
    broadcast! socket, "chat:link_info", %{mid: message.id, title: title, description: description, url: url}
  end

  defp get_link_info(socket, url, message) do
    Logger.debug "@@@@@@@@@@@@@@@   Start: #{url}         @@@@@@@@@@@@@@@@@@@@@@@@@"
    url 
      |> Colorful.string(["green", "bright"])
      |> Logger.debug      

      # Make a request to url and extract title and description 
      case HTTPoison.get(url, [], follow_redirect: true, max_redirect: 3) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          title_and_desc = body 
          |> Floki.find("head title, head meta[name=description]")

          title = title_and_desc |> Floki.text()

          description =  case title_and_desc |> Floki.attribute("content") do 
            [desc] -> desc
            _ -> nil
          end

          link_changeset = build_assoc(message, :links, url: url, title: title, description: description)
          Vchat.Repo.insert(link_changeset)
          
          broadcast_link_info(socket, message, title, description, url)

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          Logger.debug "#{url} Not found :("
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.debug "#{url} #{reason} :("
        {:ok, _} ->
          Logger.debug "#{url}. may be redirect"
      end
    Logger.debug "@@@@@@@@@@@@@@@   End: #{url}         @@@@@@@@@@@@@@@@@@@@@@@@@"

  end

end