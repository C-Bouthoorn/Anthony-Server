`/*jshint node: true*///`

'use strict'

# Load modules
app        = require('express')()
http       = require('http').Server(app)
io         = require('socket.io')(http)
fs         = require('fs')
util       = require('util')
mysql      = require('mysql')
readline   = require('readline')
htmlencode = require('htmlencode')
salthash   = require('password-hash-and-salt')



Base64 = {
  encode: (x) ->
    new Buffer(x).toString 'base64'

  decode: (x) ->
    new Buffer(x, 'base64').toString 'utf8'
}

HTML = {
  encode: (x, y) ->
    htmlencode.htmlEncode x, y

  decode: (x, y) ->
    htmlencode.htmlDecode x, y
}


PORT = 3000

# Connect to database
db = mysql.createConnection {
  host:     'localhost'
  user:     'root'
  password: 'root'
  database: 'chat_dev'
}

USER_TABLE = 'users'

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
    '/index.js'
    '/index.css'

    '/index.html'
    '/login.html'
    '/register.html'
  ]

  recursive: [
    '/images'
  ]

  redir: {
    '/':          '/index.html'
    '/login':     '/login.html'
    '/register':  '/register.html'
  }
}


WWW_ROOT = "#{ __dirname }/www"

FILES.root.map (file) ->
  app.get file, (req, res) ->
    res.sendFile WWW_ROOT + file

FILES.recursive.map (folder) ->
  fs.readdir "#{WWW_ROOT+folder}", (err, files) ->
    if err
      throw err

    files.map (file) ->
      filename = "#{folder}/#{file}"

      app.get filename, (req, res) ->
        res.sendFile "#{WWW_ROOT}/#{filename}"

FILES.redir.map (file, dest) ->
  app.get file, (req, res) ->
    res.sendFile WWW_ROOT + dest


sockets = {}
sessions = {}

sessionid_by_socketid = {}


SERVER_USER = {
  name: 'SERVER'
  type: 'server'
}


parseMessage = (x) ->
  html = HTML.encode(x, true).replace /&#10;/g, '<br>'

  return html


sendMessage = (user, message) ->
  for socketid in Object.keys sockets
    s = sockets[socketid]

    # console.log "Send message to socket ID '#{socketid}' (user '#{sessions[sessionid_by_socketid[socketid]].user.name}')!"

    s.emit 'client-receive-message', {
      user: user
      message: message
    }


# Called when a player succesfully logged in
postlogin = (socket, user, newsession=true) ->
  socketid = socket.conn.id

  if newsession
    # Set sessionid
    sessionid = ''
    while sessionid=='' or sessions[sessionid] isnt undefined
      sessionid = Base64.encode "#{Math.random() * 1e10}"

    console.log "Created sessionid '#{sessionid}' for user '#{user.name}'"

    sessions[sessionid] = {
      user: user
    }

    # Send session id
    socket.emit 'setid', {
      sessionid: sessionid
    }

  else
    sessionid = user.sessionid
    delete user['sessionid']

    console.log "Used sessionid '#{sessionid}' for user '#{user.name}'"


  # Add to chat clients
  if ! (socketid in sockets)
    sockets[socketid] = socket

  sessionid_by_socketid[socketid] = sessionid

  # Send chatbox data
  socket.on 'get-chat-data', ->
    fs.readFile "#{WWW_ROOT}/chatbox.html", (err, data) ->
      if err
        data = "<h4 class='error'>Failed to get chatbox data</h4>"

      # Convert to string
      data = '' + data

      socket.emit 'chat-data', {
        html: data
      }

      # Send welcoming message
      sendMessage SERVER_USER, "<span class='user #{user.type}'>#{user.name}</span> joined the game."

  socket.emit 'login-complete', {
    username: user.name
  }


# Called when a message is received
receiveMessage = (socket, user, message) ->
  message = message.trim()

  if message.length < 1
    return

  console.log "Got message '#{message}' from user '#{user.name}'"


  if message.startsWith '/'
    firstspace = message.search /\s|$/
    command = message.substring 1, firstspace
    args = message.substring(firstspace+1).split ' '

    socket.emit 'client-receive-message', {
      user: SERVER_USER
      message: "You issued a command '#{command}' with arguments '#{args.join ','}'"
    }

  else
    sendMessage user, parseMessage message


# Set up sockets
io.sockets.on 'connection', (socket) ->
  ip = socket.client.conn.remoteAddress
  socketid = socket.conn.id

  # IPv4
  if ip.startsWith "::ffff:"
    ip = ip.substring "::ffff:".length

  # Localhost
  if ip == "127.0.0.1"
    ip = "localhost"

  console.log "Client connected from '#{ip}' with socket ID '#{socketid}'"


  socket.on 'register', (data) ->
    if data is undefined
      console.log "No data received"

      socket.emit 'register-failed', {
        error: "No data received"
      }

      return

    do (data=data) ->
      username = data.username
      password = data.password

      if username is undefined or password is undefined
        console.log "Username or password undefined"

        socket.emit 'register-failed', {
          error: "Username or password undefined"
        }

        return


      regex = /^[a-zA-Z0-9_]{2,64}$/

      unless (regex.test username) and (password.length >= 4)
        console.log "Username or password doesn't match requirements!"

        socket.emit 'register-failed', {
          error: "Username or password doesn't match requirements!"
        }

        return

      console.log "Registration request received for user '#{username}'"


      qq = "SELECT id FROM #{USER_TABLE} WHERE username = #{db.escape(username)}"

      db.query qq, (err, data) ->
        if data.length > 0
          console.log "User '#{username}' already exists"

          socket.emit 'register-failed', {
            error: "Username already exists"
          }

          return

        salthash( password ).hash (err, hash) ->
          if err
            throw err

          qq = "INSERT INTO #{USER_TABLE} (username, password) VALUES (#{db.escape(username)}, #{db.escape(hash)})"

          db.query qq, (err, data) ->
            if err
              throw err

            console.log "Registration for user '#{username}' done"

            socket.emit 'register-complete', { }


  socket.on 'login', (data) ->
    if data is undefined
      console.log "No data received"

      socket.emit 'login-failed', {
        error: "No data received"
      }

      return

    do (data=data) ->
      username = data.username
      password = data.password

      if username is undefined or password is undefined
        console.log "Username or password undefined!"

        socket.emit 'login-failed', {
          error: "Username or password undefined"
        }

        return

      regex = /^[a-zA-Z0-9_]{2,64}$/

      unless (regex.test username) and (password.length >= 4)
        console.log "Username or password doesn't match requirements!"

        socket.emit 'login-failed', {
          error: "Username or password doesn't match requirements!"
        }

        return

      console.log "Login request received for user '#{username}'"

      qq = "SELECT password, channel_perms, type FROM #{USER_TABLE} WHERE username = #{db.escape(username)}"

      db.query qq, (err, data) ->
        if err
          throw err

        if data.length < 1
          console.log "User '#{username}' not found"

          socket.emit 'login-failed', {
            error: "Username or password incorrect!"
          }

          return

        hash = data[0].password

        # Verify the hash
        salthash( password ).verifyAgainst hash, (err, verified) ->
          if err
            throw err

          unless verified
            console.log "User '#{username}' failed to login - hashes don't match"

            socket.emit 'login-failed', {
              error: "Username or password incorrect!"
            }

            return

          console.log "User '#{username}' succesfully logged in"

          # Get user permissions and type
          channel_perms = data[0].channel_perms
          usertype = data[0].type

          # No need to check, as it's from the DB, and we trust the DB (right?)

          # Check type
          if usertype == ''
            usertype = 'normal'

          postlogin socket, {
            name: username
            channel_perms: channel_perms
            type: usertype
          }


  socket.on 'client-cookie-login', (data) ->
    if data is undefined
      console.log "No data received"

      socket.emit 'login-failed', {
        error: "No data received"
      }

      return

    sessionid = data.sessionid

    if sessionid is undefined
      console.log "No cookie received"

      socket.emit 'login-failed', {
        error: "Invalid cookie"
      }

      return

    if sessions[sessionid] is undefined
      console.log "Session not found!"

      socket.emit 'login-failed', {
        error: "Invalid cookie"
      }

      return

    user = sessions[sessionid].user
    user.sessionid = sessionid

    console.log "User '#{user.name}' logged in with session ID '#{sessionid}'"

    postlogin socket, user, false


  socket.on 'client-send-message', (data) ->
    if data is undefined
      console.log "No data received"
      return

    message = data.message

    if message is undefined
      console.log "No message received"
      return

    sessionid = data.sessionid

    if sessionid is undefined
      console.log "No session ID received"
      return

    if sessions[sessionid] is undefined
      console.log "Session ID '#{data.sessionid}' not found in sessions"
      return

    user = sessions[sessionid].user

    if user is undefined
      console.log "Session ID #{data.sessionid} exists, but no user is associated with it?"
      return

    receiveMessage socket, user, message


  socket.on 'disconnect', ->
    socketid = socket.conn.id
    sessionid = sessionid_by_socketid[socketid]

    if sessionid isnt undefined
      user = sessions[sessionid].user

      console.log "#{user.name} left the game."
      sendMessage SERVER_USER, "<span class='user #{user.type}'>#{user.name}</span> left the game."

    else
      console.log "Non-logged-in client with socket ID '#{socketid}' has disconnected"

    unless sockets[socketid] is undefined
      delete sockets[socketid]


http.listen PORT, ->
  console.log "Server started on port #{PORT}!"

# Read messages from stdin
cmdline = readline.createInterface {
  input: process.stdin
  output: process.stdout
}

cmdline.on 'line', (message) ->
  if message.length > 0
    # No encoding - Server is smart
    sendMessage SERVER_USER, message
