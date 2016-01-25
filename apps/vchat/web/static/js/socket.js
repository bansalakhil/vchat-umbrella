// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {
  Socket
}
from "deps/phoenix/web/static/js/phoenix"

import {
  Chat
}
from "web/static/js/chat";

let socket = new Socket("/socket", {
  params: {
    token: window.userToken
  }
})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

if (window.userToken) {
  socket.connect()
}

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("chat:*", {})
let chatLobby = Chat.getLobbyMbox;
Chat.channel = channel;

channel.join()
  .receive("ok", resp => {
    console.log("Joined successfully", resp);
    channel.push("chat:old_messages", {
      msg: "..."
    })
  })
  .receive("error", resp => {
    console.log("Unable to join", resp)
  })




channel.on("user:entered_in_lobby", payload => {
  // get the name of the user who joined the lobby
  var name = Chat.getUserFullName(payload.user);
  var $joinedMsg = $("<div>");
  var currentTime = new Date().toLocaleString();
  var msg = name + " joined "
  var $timestampContainer = $("<span>", {
    class: "grey-out small"
  }).text(currentTime);
  $joinedMsg.append(msg)
  $joinedMsg.append($timestampContainer);
  // console.log(chatLobby)
  chatLobby.append($joinedMsg);

  Chat.setUserActive(payload.user);
  Chat.setInactiveUserStatus(payload.inactive_users);


})

channel.on("chat:old_messages", payload => {

  $.each(payload.received_messages, function () {
    Chat.displayMessage(this, {
      highlight: false
    });
  });

})

channel.on("chat:new_msg", payload => {
  Chat.displayMessage(payload, {
    highlight: true
  });
})

channel.on("chat:user_status", payload => {
  Chat.setInactiveUserStatus(payload.inactive_users);
  channel.push("chat:record_last_activity", {
    msg: "..."
  })

})

channel.on("chat:user_offline", payload => {
  Chat.setUserInactive(payload.username);
  channel.push("chat:record_last_activity", {
    msg: "..."
  })

})

channel.on("chat:link_info", payload => {
  Chat.addLinkInfo(payload);
})



var $msgBox = Chat.getMsgBox;
$msgBox.keydown(function (e) {
  if (e.keyCode == 13 && !e.shiftKey) {
    var msg = $msgBox.val().trim();
    if (msg) {
      channel.push("chat:new_msg", {
        msg: msg,
        to: window.selected_chatgroup.attr("data-username"),
        type: window.selected_chatgroup.attr("data-chat-type")
      })
      $msgBox.val("")
    }
    e.preventDefault();
  }
});



$(function () {
  Chat.getUsers.on('click', function () {
    // console.log(this)
    // 
    var $this = $(this);
    var group_name = $this.attr("data-group-name");
    var messages = Chat.getMboxContainer(group_name).find("[data-behaviour=msg]").filter("[data-seen=false]");
    Chat.markSeen(messages);
    // console.log(messages)
    if (messages.length > 0) {
      messages[messages.length - 1].scrollIntoView();
    }
    messages.effect("highlight", 3000, {
      queue: false
    });


  })
});


export
default socket