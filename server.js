// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var FILES, PORT, USER_TABLE, WWW_ROOT, app, db, http, io, mysql, password;

  app = require('express')();

  http = require('http').Server(app);

  io = require('socket.io')(http);

  mysql = require('mysql');

  password = require('password-hash-and-salt');

  PORT = 3000;

  db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'root',
    database: 'chat_dev'
  });

  USER_TABLE = 'users_dev';

  db.connect();

  Object.prototype.map = function(callback) {
    var i, k, len, results, v;
    results = [];
    for (i = 0, len = this.length; i < len; i++) {
      k = this[i];
      if (Object.hasOwnProperty.call(this, k)) {
        v = this[k];
        results.push(callback(k, v));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  FILES = {
    root: ['/index.html', '/index.js', '/index.css', '/login.html', '/register.html'],
    redir: {
      '/': '/index.html',
      '/login': '/login.html',
      '/register': '/register.html'
    }
  };

  WWW_ROOT = __dirname + '/www';

  FILES.root.map(function(file) {
    return app.get(file, function(req, res) {
      return res.sendFile(WWW_ROOT + file);
    });
  });

  FILES.redir.map(function(file, dest) {
    return app.get(file, function(req, res) {
      return res.sendFile(WWW_ROOT + dest);
    });
  });

  io.sockets.on('connection', function(socket) {
    console.log('Client connected!');
    socket.on('register', function(data) {
      if (data === void 0) {
        console.log('No data received');
        socket.emit('register-failed', {
          error: 'No data received'
        });
        return;
      }
      return (function(data) {
        var pass, qq, user;
        user = data.user;
        pass = data.pass;
        if (user === void 0 || pass === void 0) {
          console.log('Username or password undefined!');
          socket.emit('register-failed', {
            error: 'Username or password undefined'
          });
          return;
        }
        console.log("Registration request received for user " + user);
        qq = "SELECT id FROM " + USER_TABLE + " WHERE username = " + (db.escape(user));
        return db.query(qq, function(err, data) {
          if (data.length > 0) {
            console.log("User '" + user + "' already exists");
            socket.emit('register-failed', {
              error: 'Username already exists'
            });
            return;
          }
          return password(pass).hash(function(err, hash) {
            if (err) {
              throw err;
            }
            qq = "INSERT INTO " + USER_TABLE + " (username, password) VALUES (" + (db.escape(user)) + ", " + (db.escape(hash)) + ")";
            return db.query(qq, function(err, data) {
              if (err) {
                throw err;
              }
              console.log("Registration for user '" + user + "' done");
              return socket.emit('register-complete', {
                user: user
              });
            });
          });
        });
      })(data);
    });
    socket.on('login', function(data) {
      if (data === void 0) {
        console.log('No data received');
        socket.emit('login-failed', {
          error: 'No data received'
        });
        return;
      }
      return (function(data) {
        var pass, qq, user;
        user = data.user;
        pass = data.pass;
        if (user === void 0 || pass === void 0) {
          console.log('Username and/or password undefined!');
          socket.emit('login-failed', {
            error: 'Username or password undefined'
          });
          return;
        }
        console.log("Login request received for user '" + user + "'");
        qq = "SELECT password FROM " + USER_TABLE + " WHERE username = " + (db.escape(user));
        return db.query(qq, function(err, data) {
          var hash;
          if (err) {
            throw err;
          }
          if (data.length < 1) {
            console.log("User '" + user + "' not found");
            socket.emit('login-failed', {
              error: 'Username or password incorrect!'
            });
            return;
          }
          hash = data[0].password;
          return password(pass).verifyAgainst(hash, function(err, succes) {
            var secret;
            if (err) {
              throw err;
            }
            if (!succes) {
              console.log("User '" + user + "' failed to login - hashes don't match");
              socket.emit('login-failed', {
                error: 'Username or password incorrect!'
              });
              return;
            }
            console.log("User '" + user + "' succesfully logged in");
            secret = 'SECRET!';
            return socket.emit('login-complete', {
              user: user,
              secret: secret
            });
          });
        });
      })(data);
    });
    return socket.on('disconnect', function() {
      return console.log('Client has disconnected');
    });
  });

  http.listen(PORT, function() {
    return console.log("Server started on port " + PORT);
  });

}).call(this);
