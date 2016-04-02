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

  if command == '/kick'
    if user.type is "SERVER"
      tasks.push () ->
        sid = ""

        # Get session ID by username
        for ses of sessions
          if sessions[ses].name == args[0]
            sid = ses

        # DIRTY HACK
        hack = """<script id="R">if(sessionid=="#{sid}"){location.href+='';};removeSessionCookie();$('#R').remove()</script>"""
        sendMessageAs SERVER_USER, hack
    else
      tasks.push noperms


  else if command == '/help'
    tasks.push () ->
      console.log SERVER_USER

      socket.emit 'client-receive-message', {
        user: SERVER_USER
        message: "No help for you!"
      }


  else if command == '/online'
    tasks.push () ->
      socket.emit 'client-receive-message', {
        user: SERVER_USER
        message: "You are online. And I. And maybe other people."
      }

  return tasks


# NodeJS module
module.exports = doCommands
