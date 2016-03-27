'use strict';

# Load modules
app      = require('express')()
http     = require('http').Server(app)
io       = require('socket.io')(http)
mysql    = require('mysql')
password = require('password-hash-and-salt')
fs       = require('fs')


Base64 = {
  encode: (x) ->
    new Buffer(x).toString('base64')

  decode: (x) ->
    new Buffer(x, 'base64').toString('utf8')
}


PORT = 3000

# Connect to database
db = mysql.createConnection {
  host:     'localhost'
  user:     'root'
  password: 'root'
  database: 'chat_dev'
}

USER_TABLE = 'users_dev'

db.connect()


# Monkey patch hash loop
Object.prototype.map = (callback) ->
  for k of this
    if Object.hasOwnProperty.call this, k
      v = this[k]
      callback k, v


# Set paths for files
FILES = {
  root: [
    '/index.html'
    '/index.js'
    '/index.css'

    '/login.html'
    '/register.html'
  ]

  redir: {
    '/': '/index.html'
    '/login': '/login.html'
    '/register': '/register.html'
  }
}


WWW_ROOT = __dirname + '/www'

FILES.root.map (file) ->
  app.get file, (req, res) ->
    res.sendFile WWW_ROOT + file

FILES.redir.map (file, dest) ->
  app.get file, (req, res) ->
    res.sendFile WWW_ROOT + dest


sockets = []
sessions = {}

sendMessage = (user, message) ->
  for s in sockets
    s.emit 'client-receive-message', {
      user: user
      message: message
    }


# Called when a player succesfully logged in
postlogin = (socket, user) ->
  # Set sessionid
  sessionid = ""
  while sessionid=="" or sessions[sessionid] isnt undefined
    sessionid = Base64.encode "#{Math.random() * 1e10}"

  console.log "Created sessionid '#{sessionid}'"

  sessions[sessionid] = {
    user: user
  }

  # Send session id
  socket.emit 'setid', {
    sessionid: sessionid
  }

  # Add to chat clients
  sockets.push socket

  # Send chatbox data
  socket.on 'get-chat-data', ->
    console.log ''

    fs.readFile "#{WWW_ROOT}/chatbox.html", (err, data) ->
      if err
        data = "<h4 class='error'>Failed to get chatbox data</h4>"

      socket.emit 'chat-data', {
        html: data
      }

  socket.emit 'login-complete', { }

  # Send welcoming message
  sendMessage 'SERVER', "<span class='user'>#{user}</span> joined us! Yay!"


# Set up sockets
io.sockets.on 'connection', (socket) ->
  ip = socket.client.conn.remoteAddress

  # IPv4
  if ip.startsWith "::ffff:"
    ip = ip.substring "::ffff:".length

  # Localhost
  if ip == "127.0.0.1"
    ip = "localhost"


  console.log "Client connected from #{ip}"

  socket.on 'register', (data) ->
    if data is undefined
      console.log 'No data received'

      socket.emit 'register-failed', {
        error: 'No data received'
      }

      return

    do (data=data) ->
      user = data.user
      pass = data.pass

      if user is undefined or pass is undefined
        console.log 'Username or password undefined!'

        socket.emit 'register-failed', {
          error: 'Username or password undefined'
        }

        return

      console.log "Registration request received for user '#{user}'"

      qq = "SELECT id FROM #{USER_TABLE} WHERE username = #{db.escape(user)}"

      db.query qq, (err, data) ->
        if data.length > 0
          console.log "User '#{user}' already exists"

          socket.emit 'register-failed', {
            error: 'Username already exists'
          }

          return

        password( pass ).hash (err, hash) ->
          if err
            throw err

          qq = "INSERT INTO #{USER_TABLE} (username, password) VALUES (#{db.escape(user)}, #{db.escape(hash)})"

          db.query qq, (err, data) ->
            if err
              throw err

            console.log "Registration for user '#{user}' done"

            socket.emit 'register-complete', {
              user: user
            }


  socket.on 'login', (data) ->
    if data is undefined
      console.log 'No data received'

      socket.emit 'login-failed', {
        error: 'No data received'
      }

      return

    do (data=data) ->
      user = data.user
      pass = data.pass

      if user is undefined or pass is undefined
        console.log 'Username and/or password undefined!'

        socket.emit 'login-failed', {
          error: 'Username or password undefined'
        }

        return

      console.log "Login request received for user '#{user}'"

      qq = "SELECT password FROM #{USER_TABLE} WHERE username = #{db.escape(user)}"

      db.query qq, (err, data) ->
        if err
          throw err

        if data.length < 1
          console.log "User '#{user}' not found"

          socket.emit 'login-failed', {
            error: 'Username or password incorrect!'
          }

          return

        hash = data[0].password

        # Verify the hash
        password( pass ).verifyAgainst hash, (err, succes) ->
          if err
            throw err

          if ! succes
            console.log "User '#{user}' failed to login - hashes don't match"

            socket.emit 'login-failed', {
              error: 'Username or password incorrect!'
            }

            return

          console.log "User '#{user}' succesfully logged in"

          postlogin socket, user


  socket.on 'client-send-message', (data) ->
    if data is undefined
      console.log 'No data received'
      return

    if data.sessionid is undefined
      console.log 'No session id received'
      return

    if sessions[data.sessionid] is undefined
      console.log 'Session ID not found in sessions'
      return

    user = sessions[data.sessionid].user
    message = data.message

    if message is undefined
      console.log 'No message received'
      return


    console.log "Got message '#{message}' from user '#{user}'"

    sendMessage user, message


  socket.on 'disconnect', ->
    console.log 'Client has disconnected'

    if socket in sockets
      delete sockets[socket]


http.listen PORT, ->
  console.log "Server started on port #{PORT}"
