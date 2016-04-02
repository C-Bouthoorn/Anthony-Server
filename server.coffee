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

doCommands = require('./commands')


# Custom Base64 class for en- and decoding
Base64 = {
  encode: (x) ->
    new Buffer(x).toString 'base64'

  decode: (x) ->
    new Buffer(x, 'base64').toString 'utf8'
}


# Custom HTML class for en- and decoding
HTML = {
  encode: (x, y) ->
    htmlencode.htmlEncode x, y

  decode: (x, y) ->
    htmlencode.htmlDecode x, y
}


# The port to run the server on
PORT = 3000


# Connect to database
db_config = {
  host:     'localhost'
  user:     'root'
  password: 'root'
  database: 'chat_dev'
}

USER_TABLE = 'users'

# Read messages from stdin
cmdline = readline.createInterface {
  input:  process.stdin
  output: process.stdout
}

# The sockets and sessions of the clients
sockets = {}
sessions = {}

# A dirty fix to get the sessionid when you have the socketid
sessionid_by_socketid = {}

# The server user to send messages as
SERVER_USER = {
  name: 'SERVER'
  type: 'server'
}

db = undefined


connectDatabase = ->
  console.log "[ MySQL  ] Connecting to database..."
  db = mysql.createConnection db_config

  db.connect (err) ->
    if err
      # Try reconnecting in 2 seconds
      setTimeout connectDatabase, 2000

      throw err
    else
      console.log "[ MySQL  ] Connected"

  db.on 'error', (err) ->
    if err.code == 'PROTOCOL_CONNECTION_LOST'
      # Try reconnecting
      setTimeout connectDatabase, 1000
    else
      throw err


# Monkey patch hash loop
Object.prototype.map = (callback) ->
  for k of this
    if Object.hasOwnProperty.call this, k
      v = this[k]
      callback k, v


# Set paths for files
FILES = {

  # Files on the root of the server
  root: [
    '/index.js'
    '/style.css'
    '/style.css.map'

    '/chat.html'
    '/register.html'
  ]

  # Resursive means that ALL files in that folder should be added
  recursive: [
    '/images'
  ]

  # Redirections
  redir: {
    '/':         '/chat.html'
    '/register': '/register.html'
  }
}


WWW_ROOT = "#{ __dirname }/www"

# Escape a string so that it can be used in a regex
#    "{ "a.b": ()->[] } "  --> "\{ "a.b": \(\)\->\[\]\} "
escapeRegex = (str) ->
  str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"


# Encode HTML so that it can't be injected
#  "<script>" --> "&lt;script&gt;"
encodeHTML = (str) ->
  HTML.encode(str, true).replace /&#10;/g, ''


# Parse a message, so that links are converted, and HTML is encoded
parseMessage = (x) ->
  html = encodeHTML x

  # (http(s?):\/\/\S*)
  linkregex = /(http(s?):\/\/\S*)/gi

  # http(s?):\/\/([^\/]*)
  baseregex = /http(s?)\:\/\/([^\/]+)/gi

  matches = html.match linkregex
  unless matches?
    matches = []

  for match in matches

    link = linkregex.exec(match)[1]
    base = baseregex.exec(link)[2]

    x = "<a href='#{link}' target='_blank'>#{base}</a>"

    html = html.replace match, x

  return html



# Send a message to all connected clients as the given user
sendMessageAs = (user, message) ->
  for socketid in Object.keys sockets
    s = sockets[socketid]

    s.emit 'client-receive-message', {
      user: user
      message: message
    }


# Called when a player succesfully logged in
postlogin = (socket, user, newsession=true) ->
  socketid = socket.conn.id

  if newsession
    # Create sessionid
    sessionid = ''
    while sessionid=='' or sessions[sessionid] isnt undefined
      sessionid = Base64.encode "#{Math.random() * 1e10}"

    console.log "[ SESSID ] Assigned '#{sessionid}' to user '#{user.name}'"

    # Set session ID
    sessions[sessionid] = {
      user: user
    }

    # Send session id, so that the user can remind it
    socket.emit 'setid', {
      sessionid: sessionid
    }

  else
    # There is already a session ID known (cookie)

    # Get session from data
    sessionid = user.sessionid
    # Remove session from data (We don't want to send the session to all users o.o)
    delete user['sessionid']

    console.log "[ SESSID ] Re-assigned '#{sessionid}' to user '#{user.name}'"


  # Add to chat clients
  if ! (socketid in sockets)
    sockets[socketid] = socket

  # Make a dirty link
  sessionid_by_socketid[socketid] = sessionid

  # Send chatbox data
  socket.on 'get-chat-data', ->

    # TODO: Read this file on start-up, so we don't have to load it every time
    fs.readFile "#{WWW_ROOT}/chatbox.html", (err, data) ->
      if err
        data = "<h4 class='error'>Failed to get chatbox data</h4>"
        # TODO: Add timeout to try again?

      # Convert to string
      data = '' + data

      socket.emit 'chat-data', {
        html: data
      }

      # Send welcoming message
      sendMessageAs SERVER_USER, "<span class='user #{user.type}'>#{user.name}</span> joined the game."

  socket.emit 'login-complete', {
    username: user.name
  }


# Called when a message is received
receiveMessage = (socket, user, message) ->
  message = message.trim()

  if message.length < 1
    return

  console.log "[  CHAT  ] '#{user.name}': '#{message}'"


  unless parseCommand message, user, socket
    sendMessageAs user, parseMessage message


parseCommand = (message, user, socket) ->
  # External file!
  tasks = doCommands message, user, socket

  for task in tasks
    eval "(#{task.toString()})();"

  return tasks.length > 0


#  ↑  Functions | Actually doing something  ↓


# Add all root files
FILES.root.map (file) ->
  app.get file, (req, res) ->
    res.sendFile WWW_ROOT + file


# Add all recursive folders
FILES.recursive.map (folder) ->
  fs.readdir "#{WWW_ROOT+folder}", (err, files) ->
    if err
      throw err

    files.map (file) ->
      filename = "#{folder}/#{file}"

      app.get filename, (req, res) ->
        res.sendFile "#{WWW_ROOT}/#{filename}"


# Add all redirections
FILES.redir.map (file, dest) ->
  app.get file, (req, res) ->
    res.sendFile WWW_ROOT + dest


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

  console.log "[ CONNEC ] #{ip} connected with socket ID '#{socketid}'"


  socket.on 'register', (data) ->
    if data is undefined
      console.log "[REGISTER] #{ip} : No data received"

      socket.emit 'register-failed', {
        error: "No data received"
      }

      return

    do (data=data) ->
      username = data.username
      password = data.passworderror
      type = 'user'

      if username is undefined or password is undefined
        console.log "[REGISTER] #{ip} : Username/password undefined"

        socket.emit 'register-failed', {
          error: "Username or password undefined"
        }

        return


      regex = /^[a-zA-Z0-9_]{2,64}$/

      unless (regex.test username) and (password.length >= 4)
        console.log "[REGISTER] #{ip} : Username/password don't match requirements!"

        socket.emit 'register-failed', {
          error: "Username/password don't match requirements!"
        }

        return

      console.log "[REGISTER] #{ip} : Registration request for user '#{username}'"


      if db is undefined
        console.log "[REGISTER] DATABASE UNDEFINED!"

        socket.emit 'register-failed', {
          error: "Internal error. Please try again later"
        }
        return


      qq = "SELECT id FROM #{USER_TABLE} WHERE BINARY username = #{db.escape(username)}"
      db.query qq, (err, data) ->
        if err
          throw err

        if data.length > 0
          console.log "[REGISTER] #{ip} : User '#{username}' already exists with ID '#{data[0].id}'"

          socket.emit 'register-failed', {
            error: "Username already exists"
          }

          return

        salthash( password ).hash (err, hash) ->
          if err
            throw err


          if db is undefined
            console.log "[REGISTER] DATABASE UNDEFINED!"

            socket.emit 'register-failed', {
              error: "Internal error. Please try again later"
            }
            return

          qq = "INSERT INTO #{USER_TABLE} (username, password, type) VALUES (#{db.escape(username)}, #{db.escape(hash)}, #{db.escape(type)})"
          db.query qq, (err, data) ->
            if err
              throw err

            console.log "[REGISTER] #{ip} : Registration for user '#{username}' completed"

            socket.emit 'register-complete', {
              username: username
            }


  socket.on 'login', (data) ->
    if data is undefined
      console.log "[ LOG-IN ] #{ip} : No data received"

      socket.emit 'login-failed', {
        error: "No data received"
      }

      return

    do (data=data) ->
      username = data.username
      password = data.password

      if username is undefined or password is undefined
        console.log "[ LOG-IN ] #{ip} : Username/password undefined!"

        socket.emit 'login-failed', {
          error: "Username or password undefined"
        }

        return

      regex = /^[a-zA-Z0-9_]{2,64}$/

      unless (regex.test username) and (password.length >= 4)
        console.log "[ LOG-IN ] #{ip} : Username/password don't match requirements!"

        socket.emit 'login-failed', {
          error: "Username/password don't match requirements!"
        }

        return

      console.log "[ LOG-IN ] #{ip} : Login request for user '#{username}'"


      if db is undefined
        console.log "[ LOG-IN ] DATABASE UNDEFINED!"

        socket.emit 'login-failed', {
          error: "Internal error. Please try again later"
        }
        return

      qq = "SELECT id, password, channel_perms, type FROM #{USER_TABLE} WHERE BINARY username = #{db.escape(username)}"
      db.query qq, (err, data) ->
        if err
          throw err

        if data.length < 1
          console.log "[ LOG-IN ] #{ip} : User '#{username}' not found"

          socket.emit 'login-failed', {
            error: "Username/password incorrect!"
          }

          return

        hash = data[0].password
        id = data[0].id

        # Verify the hash
        salthash( password ).verifyAgainst hash, (err, verified) ->
          if err
            throw err

          unless verified
            console.log "[ LOG-IN ] #{ip} : User '#{username}' with id #{id} failed to login - hash mismatch"

            socket.emit 'login-failed', {
              error: "Username/password incorrect!"
            }

            return

          console.log "[ LOG-IN ] #{ip} : User '#{username}' logged in"

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
      console.log "[ COOKIE ] #{ip} : No data received"

      socket.emit 'login-failed', {
        error: "No data received"
      }

      return

    sessionid = data.sessionid

    if sessionid is undefined
      console.log "[ COOKIE ] #{ip} : Cookie invalid"

      socket.emit 'login-failed', {
        error: "Invalid cookie"
      }

      return

    if sessions[sessionid] is undefined
      console.log "[ COOKIE ] #{ip} : Session not found!"

      socket.emit 'login-failed', {
        error: "Invalid cookie"
      }

      return

    user = sessions[sessionid].user
    user.sessionid = sessionid

    console.log "[ COOKIE ] #{ip} : User '#{user.name}' logged in with session ID '#{sessionid}'"

    postlogin socket, user, false


  socket.on 'client-send-message', (data) ->
    if data is undefined
      console.log "[  MESG  ] #{ip} : No data received"
      return

    message = data.message

    if message is undefined
      console.log "[  MESG  ] #{ip} : No message received"
      return

    sessionid = data.sessionid

    if sessionid is undefined
      console.log "[  MESG  ] #{ip} : No session ID received"
      return

    if sessions[sessionid] is undefined
      console.log "[  MESG  ] #{ip} : Session ID '#{data.sessionid}' not found in sessions"
      return

    user = sessions[sessionid].user

    if user is undefined
      console.log "[  MESG  ] #{ip} : Session ID #{data.sessionid} exists, but no user is associated with it?"
      return

    receiveMessage socket, user, message


  socket.on 'disconnect', ->
    socketid = socket.conn.id
    sessionid = sessionid_by_socketid[socketid]

    if sessionid isnt undefined
      user = sessions[sessionid].user

      console.log "[  CHAT  ] #{ip} : #{user.name} left the game."
      sendMessageAs SERVER_USER, "<span class='user #{user.type}'>#{user.name}</span> left the game."

    else
      console.log "[ DISCON ] Non-logged-in client with socket ID '#{socketid}' has disconnected"

    unless sockets[socketid] is undefined
      delete sockets[socketid]


cmdline.on 'line', (message) ->
  if message.length > 0

    unless parseCommand message, SERVER_USER
      # No encoding - Server is smart (?)
      sendMessageAs SERVER_USER, message



# Connect to database
connectDatabase()

# Start server
http.listen PORT, ->
  console.log "[  INFO  ] Server started on port #{PORT}!"
