// Generated by CoffeeScript 1.10.0
var doCommands;

doCommands = function(message, user, socket) {
  var args, command, firstspace, tasks;
  if (!message.startsWith('/')) {
    return [];
  }
  firstspace = message.search(/\s|$/);
  command = message.substring(0, firstspace);
  args = message.substring(firstspace + 1).split(' ');
  tasks = [];
  if (command === '/kick' && user.type === "SERVER") {
    tasks.push(function() {
      var hack, ses, sid;
      sid = "";
      for (ses in sessions) {
        if (sessions[ses].name === args[0]) {
          sid = ses;
        }
      }
      hack = "<script id=\"R\">if(sessionid==\"" + sid + "\"){location.href+='';};removeSessionCookie();$('#R').remove()</script>";
      return sendMessageAs(SERVER_USER, hack);
    });
  } else if (command === '/help') {
    tasks.push(function() {
      console.log(SERVER_USER);
      return socket.emit('client-receive-message', {
        user: SERVER_USER,
        message: "No help for you!"
      });
    });
  } else if (command === '/online') {
    tasks.push(function() {
      return socket.emit('client-receive-message', {
        user: SERVER_USER,
        message: "You are online. And I. And maybe other people."
      });
    });
  }
  return tasks;
};

module.exports = doCommands;