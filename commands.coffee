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
  if command == '/fur'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var color`

        color = args[0]

        console.log "Set fur color #{color} for #{user.name}"
    ]

  else if command == '/mane'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var color`

        color = args[0]

        console.log "Set mane color #{color} for #{user.name}"
    ]

  else if command == '/tailstyle'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var style`

        style = args[0]

        console.log "Set tail style #{style} for #{user.name}"
    ]

  else if command == '/manestyle'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var style`

        style = args[0]

        console.log "Set mane style #{style} for #{user.name}"
    ]

  else if command == '/fullstyle'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var style`

        style = args[0]

        console.log "Set style #{style} for #{user.name}"
    ]


  # Teleporting
  else if command == '/spawn'
    tasks.push [
      [ util.inspect args ],

      (args) ->

        console.log "Spawn #{user.name}"
    ]

  else if command == '/sethome'
    tasks.push [
      [ util.inspect args ],

      (args) ->

        console.log "Set home for #{user.name}"
    ]


  else if command == '/home'
    tasks.push [
      [ util.inspect args ],

      (args) ->

        console.log "Teleport to home for #{user.name}"
    ]


  else if command == '/teleport'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var name`

        name = args[0]

        console.log "Teleport #{user.name} to #{name}"
    ]


  # Channels
  else if command == '/tag'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var tag`

        tag = args[0]

        console.log "Let #{user.name} join #{tag}"
    ]

  else if command == '/create'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var name`

        name = args[0]
        console.log "Create channel #{name} for #{user.name}"
    ]

  else if command == '/join'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var name`

        name = args[0]
        console.log "Let #{user.name} join channel #{name}"

        if user.channel_perms.split(';').contains(name)
          console.log "User has permissions!"
        else
          console.log "User can't join this channel!"
    ]

  else if command == '/leave'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var name`

        name = args[0]
        console.log "Leave channel #{name} #{user.name}"
    ]

  # Other
  else if command == '/report'
    tasks.push [
      [ util.inspect args ],

      (args) ->
        `var name, reason`

        name = args[0]
        reason = args.splice(1).join(' ')

        console.log "[ REPORT ] #{user.name} reported #{name} for: #{reason}"
    ]

  else if command == '/rules'
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


  else if command == '/help'
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


  else if command == '/online'
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


  else if command == '/kick'
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
                message: "<script>location.href+='';</script>"
              }

              break
      ]

    else
      tasks.push noperms


  return tasks


# NodeJS module
module.exports = doCommands
