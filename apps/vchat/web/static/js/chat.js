// // $(function() {
//   $("div[data-behaviour=chat-users] a[data-behaviour=chat-user]").on('click', function(){
//     alert(this)
//   })
// // });
// // 

var Chat = {

  channel: null,
  getUsers: $("div[data-behaviour=chat-users] li[data-behaviour=chat-user]"),
  getLobbyMbox: $("[data-behaviour=chat-mbox] [data-mbox=chat-lobby] [data-behaviour=mbox]"),
  getAllMboxContainer: $("div[data-behaviour=chat-mbox] div[data-behaviour=mbox-container]"),
  getMsgBox: $("[data-behaviour=msg-form] textarea[data-behaviour=msg-input]"),

  getMboxContainer: function (name) {
    return Chat.getAllMboxContainer.filter("[data-mbox=" + name + "]")
  },

  pushMsgToMboxContainer: function (username, container, msg, payload, options) {
    // console.log(msg)
    // var container = Chat.getMboxContainer(username)
    container.find("[data-behaviour=mbox]").append(msg)

    msg[0].scrollIntoView();

    if (options["highlight"]) {
      msg.effect("highlight", 3000, {
        queue: false
      });
    }

    if (!payload.seen) {
      Chat.displayNotification(username, payload);
    }

    if (window.selected_chatgroup.attr("data-username") == username && !payload.seen) {
      Chat.markSeen(msg)
    }
  },

  displayNotification: function (username, payload) {
    // display notification if not in focused
    if (window.selected_chatgroup.attr("data-username") != username) {
      var notificationBox = Chat.getNotificationBoxFor(username)
      var count = Number(notificationBox.text());
      notificationBox.text(++count);
    }
  },

  getUserFullName: function (username) {
    // console.log($("[data-behaviour=chat-users] li[data-username="+username+"]"))
    return $("[data-behaviour=chat-users] li[data-username=" + username + "]").attr("data-name")
  },

  getUser: function (username) {
    return Chat.getUsers.filter("[data-username=" + username + "]")
  },

  getNotificationBoxFor: function (username) {
    // console.log(Chat.getUser(username).find("[data-behaviour=notification]"))
    return Chat.getUser(username).find("[data-behaviour=notification]")
  },

  resetNotificationFor: function (username) {
    var notificationBox = Chat.getUser(username).find("[data-behaviour=notification]");
    // console.log(notificationBox)
    notificationBox.text("");
  },


  run: function () {
    $(function () {

      // hide all mbox and show lobby mbox  
      Chat.getAllMboxContainer.hide()
      Chat.getMboxContainer('chat-lobby').show()
      window.selected_chatgroup = Chat.getUser("chat-lobby");


      // on click display related mbox  
      Chat.getUsers.on('click', function () {
        // console.log(this)
        // 
        var $this = $(this);
        var username = $this.attr("data-username");

        // console.log('Hiding all mbox-containers')
        // console.log('displayiing '+username+'-container');

        Chat.getAllMboxContainer.hide()
        Chat.getMboxContainer(username).show()
        Chat.resetNotificationFor(username);
        window.selected_chatgroup = $this;
      })
    });
  },

  displayMessage: function (payload, options) {
    var msgFor;
    if (payload.msg_type == 'group') {
      // its a group message
      msgFor = payload.group_name;
    } else {
      // its an individual chat
      if (window.current_username == payload.from) {
        // message sent by me
        msgFor = payload.group_name;
      } else {
        // message received by me
        msgFor = payload.from;
      }
    }


    // var currentTime = new Date();

    //mbox in which new message will be pushed
    var $mboxContainer = Chat.getMboxContainer(msgFor);
    var $newMsgContainer = $("<div>", {
      "data-behaviour": "msg",
      "data-mid": payload.mid,
      "data-seen": payload.seen,
      "data-from-username": payload.from,
      "data-timestamp": payload.time,
      class: "msg-container"
    });
    // console.log("[data-username="+payload.from+"]")
    // 
    // message sender name from dom using username
    var fromName = Chat.getUserFullName(payload.from)
      // prepare the message content to display
    var msg = payload.msg;
    // var $timestampContainer = $("<span>", {class: "grey-out small"}).html("&nbsp;"+currentTime.toLocaleString());
    var $timestampContainer = $("<span>", {
      class: "grey-out small"
    }).html("&nbsp;" + payload.time);
    var $from = $("<span>", {
      class: 'bold'
    }).append(fromName);

    var $username = $("<div>").append($from).append($timestampContainer)
    $newMsgContainer.append($username)

    $newMsgContainer.append($("<div>", {
      class: "msg"
    }).html(Chat.textToLinks(msg)));


    console.log("Message received for chatgroup: " + msgFor);

    // append in the desired chat group
    // 
    Chat.pushMsgToMboxContainer(msgFor, $mboxContainer, $newMsgContainer, payload, options)

    // console.log(payload.links)
    $(payload.links).each(function (i, link) {
      Chat.addLinkInfo({
        mid: payload.mid,
        url: link.url,
        title: link.title,
        description: link.description
      })
    });
  },

  setUserActive: function (username) {
    Chat.getUser(username).addClass("online").removeClass("offline");
  },

  setUserInactive: function (username) {
    console.log(username + " offline")
    Chat.getUser(username).addClass("offline").removeClass("online");
    Chat.displayUserExited(username);
  },

  setInactiveUserStatus: function (payload) {
    // console.log(payload)
    var users = Chat.getUsers
    users.addClass("online").removeClass("offline");

    var offline_users = users.filter(function () {
      return payload.includes($(this).attr("data-username"))
    });

    offline_users.addClass("offline").removeClass("online")
  },

  displayUserExited: function (username) {
    var name = Chat.getUserFullName(username);
    var $msg = $("<div>");
    var currentTime = new Date().toLocaleString();
    var msg = name + " left "
    var $timestampContainer = $("<span>", {
      class: "grey-out small"
    }).text(currentTime);
    $msg.append(msg)
    $msg.append($timestampContainer);
    // console.log(chatLobby)
    Chat.getLobbyMbox.append($msg);
  },

  markSeen: function (messages) {
    // alert(messages)
    var message_ids = messages.map(function (i, el) {
      return el.getAttribute('data-mid')
    });

    if (message_ids.length > 0) {
      Chat.channel.push("chat:mark_seen", {
        message_ids: message_ids.toArray()
      });
      messages.attr("data-seen", true)
    }
  },

  addLinkInfo: function (payload) {
    var msg = Chat.getAllMboxContainer.find("div[data-behaviour=msg]div[data-mid=" + payload.mid + "]")
    var info_node = $("<div>", {
      "data-behaviour": "link_info",
      "class": "link_info"
    })

    var url = $("<a>", {
      href: payload.url
    }).text(payload.url);

    var url_node = $("<div>", {
      "data-behaviour": "link_info_url",
      "class": "link_url"
    }).append(url)

    var title = $("<a>", {
      href: payload.url
    }).text(payload.title);

    var title_node = $("<div>", {
      "data-behaviour": "link_info_title",
      "class": "link_title"
    }).append(title)

    var description_node = $("<div>", {
      "data-behaviour": "link_info_description",
      "class": "link_description"
    }).html(payload.description)

    info_node.append(title_node).append(url_node).append(description_node)
    msg.append(info_node);

    info_node[0].scrollIntoView();
  },

  textToLinks: function (text) {

    var re = /(https?:\/\/(([-\w\.]+)+(:\d+)?(\/([\w/_\.]*(\?\S+)?)?)?))/g;
    return text.replace(re, "<a href=\"$1\" target = '_blank' title=\"\">$1</a>");
  }

};

Chat.run();









module.exports = {
  Chat: Chat
};