'use strict';

# Load modules
app      = require('express')()
http     = require('http').Server(app)
io       = require('socket.io')(http)
mysql    = require('mysql')
password = require('password-hash-and-salt')

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

          secret = 'SECRET!'

          socket.emit 'login-complete', {
            user: user
            secret: secret
          }


  socket.on 'disconnect', ->
    console.log 'Client has disconnected'


http.listen PORT, ->
  console.log "Server started on port #{PORT}"