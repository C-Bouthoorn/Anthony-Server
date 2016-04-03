// Generated by CoffeeScript 1.10.0
/*jshint node: true*///;
'use strict';
var Base64, FILES, HTML, PORT, SERVER_USER, USER_TABLE, WWW_ROOT, app, channels, cmdline, connectDatabase, db, db_config, doCommands, encodeHTML, escapeRegex, fs, htmlencode, http, io, mysql, parseCommand, parseMessage, postlogin, readline, receiveMessage, salthash, sendMessageAs, sessionid_by_socketid, sessions, sockets, util,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

app = require('express')();

http = require('http').Server(app);

io = require('socket.io')(http);

fs = require('fs');

util = require('util');

mysql = require('mysql');

readline = require('readline');

htmlencode = require('htmlencode');

salthash = require('password-hash-and-salt');

require('./includes.js');

require('coffee-script');

doCommands = require('./commands.coffee');

Base64 = {
  encode: function(x) {
    return new Buffer(x).toString('base64');
  },
  decode: function(x) {
    return new Buffer(x, 'base64').toString('utf8');
  }
};

HTML = {
  encode: function(x, y) {
    return htmlencode.htmlEncode(x, y);
  },
  decode: function(x, y) {
    return htmlencode.htmlDecode(x, y);
  }
};

PORT = 3000;

db_config = {
  host: 'localhost',
  user: 'root',
  password: 'root',
  database: 'chat_dev'
};

USER_TABLE = 'users';

cmdline = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

sockets = {};

sessions = {};

channels = [];

sessionid_by_socketid = {};

SERVER_USER = {
  name: 'SERVER',
  type: 'server'
};

db = void 0;

connectDatabase = function() {
  console.log("[DATABASE] Connecting to database...");
  db = mysql.createConnection(db_config);
  db.connect(function(err) {
    if (err) {
      setTimeout(connectDatabase, 2000);
      throw err;
    } else {
      return console.log("[DATABASE] Connected");
    }
  });
  return db.on('error', function(err) {
    if (err.code === 'PROTOCOL_CONNECTION_LOST') {
      return setTimeout(connectDatabase, 1000);
    } else {
      throw err;
    }
  });
};

Object.prototype.map = function(callback) {
  var k, results, v;
  results = [];
  for (k in this) {
    if (Object.hasOwnProperty.call(this, k)) {
      v = this[k];
      results.push(callback(k, v));
    } else {
      results.push(void 0);
    }
  }
  return results;
};

Array.prototype.remove = function(item) {
  var index;
  index = this.indexOf(item);
  if (index >= 0) {
    return this.splice(index, 1);
  }
};

FILES = {
  root: ['/index.js', '/style.css', '/style.css.map', '/chat.html', '/register.html'],
  recursive: ['/images'],
  redir: {
    '/': '/chat.html',
    '/register': '/register.html'
  }
};

WWW_ROOT = __dirname + "/www";

escapeRegex = function(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
};

encodeHTML = function(str) {
  return HTML.encode(str, true).replace(/&#10;/g, '');
};

parseMessage = function(x) {
  var base, baseregex, html, i, len, link, linkregex, match, matches;
  html = encodeHTML(x);
  linkregex = /(http(s?):\/\/\S*)/gi;
  baseregex = /http(s?)\:\/\/([^\/]+)/gi;
  matches = html.match(linkregex);
  if (matches == null) {
    matches = [];
  }
  for (i = 0, len = matches.length; i < len; i++) {
    match = matches[i];
    link = linkregex.exec(match)[1];
    base = baseregex.exec(link)[2];
    x = "<a href='" + link + "' target='_blank'>" + base + "</a>";
    html = html.replace(match, x);
  }
  return html;
};

sendMessageAs = function(user, message) {
  var i, len, ref, results, s, socketid;
  ref = Object.keys(sockets);
  results = [];
  for (i = 0, len = ref.length; i < len; i++) {
    socketid = ref[i];
    s = sockets[socketid];
    results.push(s.emit('client-receive-message', {
      user: user,
      message: message
    }));
  }
  return results;
};

postlogin = function(socket, user) {
  var sessionid, socketid;
  socketid = socket.conn.id;
  sessionid = '';
  while (sessionid === '' || sessions[sessionid] !== void 0) {
    sessionid = Base64.encode("" + (Math.random() * 1e10));
  }
  console.log("[ SESSID ] Assigned '" + sessionid + "' to user '" + user.name + "'");
  sessions[sessionid] = {
    user: user,
    socket: socket
  };
  socket.emit('setid', {
    sessionid: sessionid
  });
  if (!(indexOf.call(sockets, socketid) >= 0)) {
    sockets[socketid] = socket;
  }
  sessionid_by_socketid[socketid] = sessionid;
  socket.on('get-chat-data', function() {
    return fs.readFile(WWW_ROOT + "/chatbox.html", function(err, data) {
      if (err) {
        data = "<h4 class='error'>Failed to get chatbox data</h4>";
      }
      data = '' + data;
      socket.emit('chat-data', {
        html: data
      });
      sendMessageAs(SERVER_USER, "<span class='user " + user.type + "'>" + user.name + "</span> joined the game.");
      parseCommand('/online', SERVER_USER, socket);
      return socket.emit('client-receive-message', {
        user: SERVER_USER,
        message: "Welcome to the server! Use <b>\"/help\"</b> to see all the commands you have access to."
      });
    });
  });
  return socket.emit('login-complete', {
    username: user.name
  });
};

receiveMessage = function(socket, user, message) {
  message = message.trim();
  if (message.length < 1) {
    return;
  }
  console.log("[  CHAT  ] '" + user.name + "': '" + message + "'");
  if (!parseCommand(message, user, socket)) {
    return sendMessageAs(user, parseMessage(message));
  }
};

parseCommand = function(message, user, socket) {
  var evil, func, i, len, task, tasks, vars;
  tasks = doCommands(message, user, socket);
  for (i = 0, len = tasks.length; i < len; i++) {
    task = tasks[i];
    if (Array.isArray(task)) {
      vars = task[0];
      func = task[1];
    } else {
      vars = [];
      func = task;
    }
    evil = "(" + (func.toString()) + ")(" + (vars.join(',')) + ");";
    eval(evil);
  }
  return tasks.length > 0;
};

FILES.root.map(function(file) {
  return app.get(file, function(req, res) {
    return res.sendFile(WWW_ROOT + file);
  });
});

FILES.recursive.map(function(folder) {
  return fs.readdir("" + (WWW_ROOT + folder), function(err, files) {
    if (err) {
      throw err;
    }
    return files.map(function(file) {
      var filename;
      filename = folder + "/" + file;
      return app.get(filename, function(req, res) {
        return res.sendFile(WWW_ROOT + "/" + filename);
      });
    });
  });
});

FILES.redir.map(function(file, dest) {
  return app.get(file, function(req, res) {
    return res.sendFile(WWW_ROOT + dest);
  });
});

io.sockets.on('connection', function(socket) {
  var ip, socketid;
  ip = socket.client.conn.remoteAddress;
  socketid = socket.conn.id;
  if (ip.startsWith("::ffff:")) {
    ip = ip.substring("::ffff:".length);
  }
  if (ip === "127.0.0.1") {
    ip = "localhost";
  }
  console.log("[ CONNEC ] " + ip + " connected with socket ID '" + socketid + "'");
  socket.on('register', function(data) {
    if (data === void 0) {
      console.log("[REGISTER] " + ip + " : No data received");
      socket.emit('register-failed', {
        error: "No data received"
      });
      return;
    }
    return (function(data) {
      var password, qq, regex, type, username;
      username = data.username;
      password = data.password;
      type = 'normal';
      if (username === void 0 || password === void 0) {
        console.log("[REGISTER] " + ip + " : Username/password undefined");
        socket.emit('register-failed', {
          error: "Username or password undefined"
        });
        return;
      }
      regex = /^[a-zA-Z0-9_]{2,64}$/;
      if (!((regex.test(username)) && (password.length >= 4))) {
        console.log("[REGISTER] " + ip + " : Username/password don't match requirements!");
        socket.emit('register-failed', {
          error: "Username/password don't match requirements!"
        });
        return;
      }
      console.log("[REGISTER] " + ip + " : Registration request for user '" + username + "'");
      if (db === void 0) {
        console.log("[REGISTER] DATABASE UNDEFINED!");
        socket.emit('register-failed', {
          error: "Internal error. Please try again later"
        });
        return;
      }
      qq = "SELECT id FROM " + USER_TABLE + " WHERE BINARY username = " + (db.escape(username));
      return db.query(qq, function(err, data) {
        if (err) {
          throw err;
        }
        if (data.length > 0) {
          console.log("[REGISTER] " + ip + " : User '" + username + "' already exists with ID '" + data[0].id + "'");
          socket.emit('register-failed', {
            error: "Username already exists"
          });
          return;
        }
        return salthash(password).hash(function(err, hash) {
          if (err) {
            throw err;
          }
          if (db === void 0) {
            console.log("[REGISTER] DATABASE UNDEFINED!");
            socket.emit('register-failed', {
              error: "Internal error. Please try again later"
            });
            return;
          }
          qq = "INSERT INTO " + USER_TABLE + " (username, password, type) VALUES (" + (db.escape(username)) + ", " + (db.escape(hash)) + ", " + (db.escape(type)) + ")";
          return db.query(qq, function(err, data) {
            if (err) {
              throw err;
            }
            console.log("[REGISTER] " + ip + " : Registration for user '" + username + "' completed");
            return socket.emit('register-complete', {
              username: username
            });
          });
        });
      });
    })(data);
  });
  socket.on('login', function(data) {
    if (data === void 0) {
      console.log("[ LOG-IN ] " + ip + " : No data received");
      socket.emit('login-failed', {
        error: "No data received"
      });
      return;
    }
    return (function(data) {
      var password, qq, regex, username;
      username = data.username;
      password = data.password;
      if (username === void 0 || password === void 0) {
        console.log("[ LOG-IN ] " + ip + " : Username/password undefined!");
        socket.emit('login-failed', {
          error: "Username or password undefined"
        });
        return;
      }
      regex = /^[a-zA-Z0-9_]{2,64}$/;
      if (!((regex.test(username)) && (password.length >= 4))) {
        console.log("[ LOG-IN ] " + ip + " : Username/password don't match requirements!");
        socket.emit('login-failed', {
          error: "Username/password don't match requirements!"
        });
        return;
      }
      console.log("[ LOG-IN ] " + ip + " : Login request for user '" + username + "'");
      if (db === void 0) {
        console.log("[ LOG-IN ] DATABASE UNDEFINED!");
        socket.emit('login-failed', {
          error: "Internal error. Please try again later"
        });
        return;
      }
      qq = "SELECT id, password, channel_perms, type FROM " + USER_TABLE + " WHERE BINARY username = " + (db.escape(username));
      return db.query(qq, function(err, data) {
        var hash, id;
        if (err) {
          throw err;
        }
        if (data.length < 1) {
          console.log("[ LOG-IN ] " + ip + " : User '" + username + "' not found");
          socket.emit('login-failed', {
            error: "Username/password incorrect!"
          });
          return;
        }
        hash = data[0].password;
        id = data[0].id;
        return salthash(password).verifyAgainst(hash, function(err, verified) {
          var channel_perms, usertype;
          if (err) {
            throw err;
          }
          if (!verified) {
            console.log("[ LOG-IN ] " + ip + " : User '" + username + "' with id " + id + " failed to login - hash mismatch");
            socket.emit('login-failed', {
              error: "Username/password incorrect!"
            });
            return;
          }
          console.log("[ LOG-IN ] " + ip + " : User '" + username + "' logged in");
          channel_perms = data[0].channel_perms;
          usertype = data[0].type;
          return postlogin(socket, {
            id: id,
            name: username,
            channel_perms: channel_perms,
            type: usertype,
            channels: ["general"]
          });
        });
      });
    })(data);
  });
  socket.on('client-send-message', function(data) {
    var message, sessionid, user;
    if (data === void 0) {
      console.log("[  MESG  ] " + ip + " : No data received");
      return;
    }
    message = data.message;
    if (message === void 0) {
      console.log("[  MESG  ] " + ip + " : No message received");
      return;
    }
    sessionid = data.sessionid;
    if (sessionid === void 0) {
      console.log("[  MESG  ] " + ip + " : No session ID received");
      return;
    }
    if (sessions[sessionid] === void 0) {
      console.log("[  MESG  ] " + ip + " : Session ID '" + data.sessionid + "' not found in sessions");
      return;
    }
    user = sessions[sessionid].user;
    if (user === void 0) {
      console.log("[  MESG  ] " + ip + " : Session ID " + data.sessionid + " exists, but no user is associated with it?");
      return;
    }
    return receiveMessage(socket, user, message);
  });
  return socket.on('disconnect', function() {
    var sessionid, user;
    socketid = socket.conn.id;
    sessionid = sessionid_by_socketid[socketid];
    if (sessionid !== void 0) {
      user = sessions[sessionid].user;
      console.log("[  CHAT  ] " + ip + " : " + user.name + " left the game.");
      sendMessageAs(SERVER_USER, "<span class='user " + user.type + "'>" + user.name + "</span> left the game.");
      delete sessions[sessionid];
    } else {
      console.log("[ DISCON ] Non-logged-in client with socket ID '" + socketid + "' has disconnected");
    }
    delete sockets[socketid];
    return delete sessionid_by_socketid[socketid];
  });
});

cmdline.on('SIGINT', function() {
  return process.exit(0);
});

cmdline.on('line', function(message) {
  if (message.length > 0) {
    if (!parseCommand(message, SERVER_USER)) {
      return sendMessageAs(SERVER_USER, message);
    }
  }
});

connectDatabase();

http.listen(PORT, function() {
  return console.log("[  INFO  ] Server started on port " + PORT + "!");
});
