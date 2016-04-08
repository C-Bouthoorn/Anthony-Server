util = require('util')

doCommands = (message, user, socket) ->
  unless message.startsWith '/'
    return []

  firstspace = message.search /\s|$/
  command = message.substring 0, firstspace
  args = message.substring(firstspace+1).split ' '

  tasks = []

  noperms = () ->
    socket.emit 'client-receive-message', {
      user: SERVER_USER
      message: "You don't have the right permissions to use this command!"
    }



  # Styles
  switch command
    when '/fur'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var color`

          color = args[0]

          console.log "[PONY_CMD]".black.bgCyan + " Set fur color #{color} for user #{user.name}"
      ]

    when '/mane'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var color`

          color = args[0]

          console.log "[PONY_CMD]".black.bgCyan + " Set mane color #{color} for user #{user.name}"
      ]

    when '/tailstyle'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var style`

          style = args[0]

          console.log "[PONY_CMD]".black.bgCyan + " Set tail style #{style} for user #{user.name}"
      ]

    when '/manestyle'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var style`

          style = args[0]

          console.log "[PONY_CMD]".black.bgCyan + " Set mane style #{style} for user #{user.name}"
      ]

    when '/fullstyle'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var style`

          style = args[0]

          console.log "[PONY_CMD]".black.bgCyan + " Set style #{style} for user #{user.name}"
      ]


    # Teleporting
    when '/spawn'
      tasks.push [
        [ util.inspect args ],

        (args) ->

          console.log "[PONY_CMD]".black.bgCyan + " User #{user.name} teleported to spawn"
      ]

    when '/sethome'
      tasks.push [
        [ util.inspect args ],

        (args) ->

          console.log "[PONY_CMD]".black.bgCyan + " Set home for user #{user.name}"
      ]

    when '/home'
      tasks.push [
        [ util.inspect args ],

        (args) ->

          console.log "[PONY_CMD]".black.bgCyan + " User #{user.name} teleported to home"
      ]

    when '/teleport'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var name`

          name = args[0]

          console.log "[PONY_CMD]".black.bgCyan + " User #{user.name} teleported to #{name}"
      ]


    # Channels
    when '/create'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var name`

          name = args[0]

          regex = /^[a-zA-Z0-9_]{2,64}$/
          unless regex.test name
            console.log "[  CHNL  ]".black.bgRed + " Channel doesn't match requirements"

            socket.emit 'client-receive-message', {
              user: SERVER_USER
              message: "Channel name doesn't match requirements"
            }

            return

          console.log "[  CHNL  ]".black.bgGreen + " Create channel #{name} for user #{user.name}"

          if channels.includes name
            console.log "[  CHNL  ]".black.bgRed + " Channel already exists!"

            socket.emit 'client-receive-message', {
              user: SERVER_USER
              message: "Channel already exists! Use <b>/join #{name}</b> to join it"
            }

            return


          channels.push name

          user.channel_perms.push name


          if db is undefined
            console.log "[  CHNL  ]".black.bgRed + " DATABASE UNDEFINED!"
            return

          qq = "UPDATE #{USER_TABLE} SET channel_perms=#{db.escape user.channel_perms.join ';'} WHERE id=#{user.id};"
          db.query qq, (err, data) ->
            if err then throw err

          qq = "INSERT INTO #{CHANNELS_TABLE} (name) VALUES (#{db.escape name});"
          db.query qq, (err, data) ->
            if err then throw err

          console.log "[  CHNL  ]".black.bgGreen + " Channel #{name} created"

          socket.emit 'client-receive-message', {
            user: SERVER_USER
            message: "Channel created. Use <b>/join #{name}</b> to join it"
          }
      ]

    when '/join'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var name`

          name = args[0]

          unless user.channel_perms.split(';').includes name
            console.log "[  CHNL  ]".black.bgRed + " User #{user.name} doesn't have permission to join channel #{name}!"

            socket.emit 'client-receive-message', {
              user: SERVER_USER
              message: "You don't have permission to join this channel"
            }

            return


          unless channels.includes name
            console.log "[  CHNL  ]".black.bgRed + " Channel #{name} doesn't exist!"

            socket.emit 'client-receive-message', {
              user: SERVER_USER
              message: "That channel doesn't exist"
            }

            return


          user.channels.push name

          console.log "[  CHNL  ]".black.bgGreen + " User #{user.name} joined channel #{name}"

          socket.emit 'client-receive-message', {
            user: SERVER_USER
            message: "Joined channel"
          }

          socket.emit 'setchannels', {
            channels: user.channels
          }
      ]

    when '/invite'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var username, name`

          username = args[0]
          name = args[1]
      ]

    when '/leave'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var name`

          name = args[0]
          console.log "[  CHNL  ]".black.bgRed + "user #{user.name} left channel #{name}"

          unless user.channels.includes name
            console.log "[  CHNL  ]".black.bgRed + "User #{user.name} isn't in channel #{name}!"

            socket.emit 'client-receive-message', {
              user: SERVER_USER
              message: "You aren't in that channel"
            }

            return


          user.channels.remove name

          socket.emit 'setchannels', {
            channels: user.channels
          }

          socket.emit 'client-receive-message', {
            user: SERVER_USER
            message: "Succesfully left channel!"
          }
      ]


    # Minigames
    when '/tag'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var tag`

          tag = args[0]

          console.log "[MINIGAME]".black.bgMagenta + "user #{user.name} joined the tag!"
      ]


    # Other
    when '/report'
      tasks.push [
        [ util.inspect args ],

        (args) ->
          `var name, reason`

          name = args[0]
          reason = args.splice(1).join(' ')

          console.log "[ REPORT ]".red.bgWhite + " User #{user.name} reported #{name} for " + "#{reason}".underline

          socket.emit 'client-receive-message', {
            user: SERVER_USER
            message: "Thank you for reporting! We will look into it. Note, however, that false reports might result in a ban!"
          }
      ]


    when '/rules'
      tasks.push () ->
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
      tasks.push () ->
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
      tasks.push () ->

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


        socket.emit 'client-receive-message', {
          user: SERVER_USER
          message: "Users online(#{users.length}): #{(u.name for u in users).join ", "}"
        }


    when '/kick'
      targetname = args[0]

      if (user.type == "server") or (user.name == targetname)

        tasks.push [
          [ util.inspect args ],



          ( args ) ->

            `var targetname`  # Scoping ffs
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
        ]

      else
        tasks.push noperms


  return tasks


# NodeJS module
module.exports = doCommands
