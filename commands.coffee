util = require('util')

@tasks = []
@args = []


addTask = (func) ->
  @tasks.push [
    [ util.inspect @args ],

    func
  ]


doCommands = (message, user, socket) ->
  unless message.startsWith '/'
    return []

  @tasks = []

  firstspace = message.search /\s|$/
  command = message.substring 0, firstspace
  @args = message.substring(firstspace+1).split ' '


  noperms = () ->
    sendServerMessageTo socket, "You don't have the right permissions to use this command!"



  # Styles
  switch command
    when '/pleasepullfromgitformeplease'
      addTask (args) ->
        p = child.spawn "git", ["pull"]

        change = true

        out = (data) ->
          data = (data+'').trim()

          if data.length > 0
            if data == "Already up-to-date."
              change = false

            console.log "[GIT] #{data.split('\n').join('\n[GIT] ')}"

            sendServerMessageTo socket, "[GIT] #{data}"

        p.stdout.on 'data', out
        p.stderr.on 'data', out

        p.on 'exit', ->
          if change
            console.log "Please restart!"
            process.exit 1


    when '/debug'
      addTask (args) ->
        type = args[0]
        color = args[1]

        createTexture type, color


    when '/fur'
      addTask (args) ->
        color = args[0]

        console.log "[PONY_CMD]".c_CHAT + " Set fur color #{color} for user #{user.name}"


    when '/mane'
      addTask (args) ->
        color = args[0]

        console.log "[PONY_CMD]".c_CHAT + " Set mane color #{color} for user #{user.name}"


    when '/tailstyle'
      addTask (args) ->
        style = args[0]

        console.log "[PONY_CMD]".c_CHAT + " Set tail style #{style} for user #{user.name}"


    when '/manestyle'
      addTask (args) ->
        style = args[0]

        console.log "[PONY_CMD]".c_CHAT + " Set mane style #{style} for user #{user.name}"


    when '/fullstyle'
      addTask (args) ->
        style = args[0]

        console.log "[PONY_CMD]".c_CHAT + " Set style #{style} for user #{user.name}"


    # Teleporting
    when '/spawn'
      addTask (args) ->
        console.log "[PONY_CMD]".c_CHAT + " User #{user.name} teleported to spawn"


    when '/sethome'
      addTask (args) ->
        console.log "[PONY_CMD]".c_CHAT + " Set home for user #{user.name}"


    when '/home'
      addTask (args) ->
        console.log "[PONY_CMD]".c_CHAT + " User #{user.name} teleported to home"


    when '/teleport'
      addTask (args) ->
        name = args[0]

        console.log "[PONY_CMD]".c_CHAT + " User #{user.name} teleported to #{name}"


    # Channels
    when '/create'
      addTask (args) ->
        name = args[0]

        regex = /^[a-zA-Z0-9_]{2,64}$/
        unless regex.test name
          console.log "[  CHNL  ]".c_ERR + " Channel doesn't match requirements"

          sendServerMessageTo socket, "Channel name doesn't match requirements"
          return

        console.log "[  CHNL  ]".c_OK + " Create channel #{name} for user #{user.name}"

        if channels.includes name
          console.log "[  CHNL  ]".c_ERR + " Channel already exists!"

          sendServerMessageTo socket, "Channel already exists! Use <b>/join #{name}</b> to join it"
          return


        channels[name] = []

        user.channel_perms.push name


        if db is undefined
          console.log "[  CHNL  ]".c_ERR + " DATABASE UNDEFINED!"
          return

        qq = "UPDATE #{USER_TABLE} SET channel_perms=#{db.escape user.channel_perms.join ';'} WHERE id=#{user.id};"
        db.query qq, (err, data) ->
          if err then throw err

        # NOTE: User hasn't joined yet!
        qq = "INSERT INTO #{CHANNELS_TABLE} (name) VALUES (#{db.escape name});"
        db.query qq, (err, data) ->
          if err then throw err

        console.log "[  CHNL  ]".c_OK + " Channel #{name} created"

        sendServerMessageTo socket, "Channel created. Use <b>/join #{name}</b> to join it"


    when '/join'
      addTask (args) ->
        `var name`

        name = args[0]

        unless user.channel_perms.includes name
          console.log "[  CHNL  ]".c_ERR + " User #{user.name} doesn't have permission to join channel #{name}!"

          sendServerMessageTo socket, "You don't have permission to join this channel"

          return


        unless channels[name]?
          console.log "[  CHNL  ]".c_ERR + " Channel #{name} doesn't exist!"

          sendServerMessageTo socket, "That channel doesn't exist"
          return


        user.channels.push name

        unless channels[name].includes user.id
          channels[name].push user.id


        if db is undefined
          console.log "[  CHNL  ]".c_ERR + " DATABASE UNDEFINED!"
          return

        qq = "UPDATE #{CHANNELS_TABLE} SET joined=#{db.escape channels[name].join ';'};"
        db.query qq, (err, data) ->
          if err then throw err

        console.log "[  CHNL  ]".c_OK + " User #{user.name} joined channel #{name}"

        sendServerMessageTo socket, "Joined channel"

        socket.emit 'setchannels', {
          channels: user.channels
        }


    when '/invite'
      addTask (args) ->
        username = args[0]
        name = args[1]


    when '/leave'
      addTask (args) ->
        name = args[0]
        console.log "[  CHNL  ]".c_ERR + " user #{user.name} leaves channel #{name}"

        if name == 'general'
          sendServerMessageTo socket, "One can't leave the general channel"
          return

        unless user.channels.includes name
          console.log "[  CHNL  ]".c_ERR + " User #{user.name} isn't in channel #{name}!"

          sendServerMessageTo socket, "You are not in that channel"
          return


        user.channels.remove name
        channels[name].remove user.id

        if db is undefined
          console.log "[  CHNL  ]".c_ERR + " DATABASE UNDEFINED!"
          return

        qq = "UPDATE #{CHANNELS_TABLE} SET joined=#{db.escape channels[name].join ';'};"
        db.query qq, (err, data) ->
          if err then throw err

        socket.emit 'setchannels', {
          channels: user.channels
        }

        sendServerMessageTo socket, "Succesfully left channel!"


    # Minigames
    when '/tag'
      addTask (args) ->
        `var tag`

        tag = args[0]

        console.log "[MINIGAME]".black.bgMagenta + "user #{user.name} joined the tag!"


    # Other
    when '/report'
      addTask (args) ->
        `var name, reason`

        name = args[0]
        reason = args.splice(1).join(' ')

        console.log "[ REPORT ]".red.bgWhite+" User "+"#{user.name}".underline+" reported "+"#{name}".underline+" for "+"#{reason}"

        sendServerMessageTo socket, "Thank you for reporting! We will look into it. Note, however, that false reports might result in a ban!"


    when '/rules'
      addTask () ->
        socket.emit 'client-receive-message', {
          user: SERVER_USER
          message: """
The rules are:
1. Don't swear
2. Don't swear
3. Don't fucking swear
4. Only admins can swear
5. But don't swear
6. Please
7. Oh, and follow the rules
""".replace /\n/g, '<br>'
        }


    when '/help'
      addTask () ->
        socket.emit 'client-receive-message', {
          user: SERVER_USER
          message: """
  <b>/fur [color]:</b>
  Changes your fur to indicated color. e.g. /fur red or /fur #ff0000
  <b>/mane [color]:</b>
  Changes your mane to indicated color.
  <b>/tailstyle [style]:</b>
  Changes your tail to indicated style. e.g. /tailstyle derpy or /tailstyle applejack
  <b>/manestyle [style]:</b>
  Changes your mane to indicated style.
  <b>/fullstyle [style]:</b>
  Changes your mane and tail to indicated style.
  <b>/online:</b>
  Shows you who is online.
  <b>/spawn:</b>
  Teleports you to the spawn.
  <b>/sethome:</b>
  Sets your private spawn point to your current location.
  <b>/home:</b>
  Teleports you to your private spawn point.
  <b>/tag:</b>
  Join/leave the tag.
  <b>/rules:</b>
  Displays the rules.
  <b>/create [name]:</b>
  Creates a chatchannel.
  <b>/join [name]:</b>
  Joins a chatchannel.
  <b>/leave [name]:</b>
  Leaves a chatchannel. (You cannot leave certain default channels)
  <b>/teleport [name]:</b>
  Teleports you to a player.
  <b>/report [name] [reason]:</b>
  Report a player. Troll reports will be punished!
  """.replace /\n/g, '<br>'
        }


    when '/online'
      addTask () ->

        # Get online users
        users = []

        for _,s of sessions
          unless s.user is undefined
            users.push s.user


        # Sort by type
        users.sort (a, b) ->
          # "admin" / "mod" / "normal"

          typea = a.type
          typeb = b.type

          if typea == typeb
            if a.id > b.id
              return 1
            else
              return -1

          else if ( typea == "admin" ) or ( typea == "mod" and typeb == "normal" )
            return 1

          else
            return -1


        sendServerMessageTo socket, "Users online(#{users.length}): #{(u.name for u in users).join ", "}"


    when '/kick'
      targetname = args[0]

      if (user.type == "server") or (user.name == targetname)

        addTask (args) ->
          `var targetname`

          targetname = args[0]

          # Get session ID by username
          for sesid, ses of sessions
            if ses.user is undefined
              continue

            if ses.user.name == targetname
              targetsock = ses.socket

              # Relies on target to not check incoming messages...
              targetsock.emit 'client-receive-message', {
                user: SERVER_USER
                message: "<script>removeUsernameCookie();location.href+='';</script>"
              }

              break

      else
        addTask noperms


  return tasks


# NodeJS module
module.exports = doCommands
