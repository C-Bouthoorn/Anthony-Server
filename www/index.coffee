`/*jshint jquery: true*///`
`/*globals io:false, console:false *///`

'use strict'

socket = null
sessionid = null


setstatus = (stat, subscr, iserror) ->
  if typeof subscr isnt 'string'
    iserror = subscr
    subscr = ''

  elem = $('#connstatus')

  html = stat + '<br><small>' + subscr + '</small>'

  elem.html html

  if iserror
    elem.addClass 'error'
  else
    elem.removeClass 'error'


safe = (callback) ->
  try
    callback()
  catch err
    console.log err
    setstatus err.message, true


init = ->
  safe ->
    socket = io.connect()

    socket.on 'connect', ->
      setstatus 'Connected to the server!'

    socket.on 'setid', (data) ->
      sessionid = data.sessionid

    socket.on 'disconnect', ->
      setstatus 'Lost connection!', true

    $('#password').keyup (event) ->
      if event.keyCode == 13  # Enter
        $('#btn').click()


initchat = ->
  $('body').append """
    <h2>Chat</h2>
    <div class="chatbox" id="chatbox"></div><br>
    <input type="text" class="msgbox" id="msgbox">
    <br>
  """

  $('#msgbox').keyup (event) ->
    if event.keyCode == 13  # Enter
      message = $('#msgbox').val()
      $('#msgbox').val('')

      socket.emit 'client-send-message', {
        sessionid: sessionid
        message: message
      }

  socket.on 'client-receive-message', (data) ->
    user = data.user
    message = data.message

    $('#chatbox').append "<span class='user'>#{user}</span>: <span class='message'>#{message}</span><br>"



login = ->
  safe ->
    user = $('#username').val()
    pass = $('#password').val()

    socket.on 'login-complete', (data) ->
      setstatus "Welcome #{user}!"
      initchat()

    socket.on 'login-failed', (data) ->
      setstatus 'Failed to login:', data.error, true

    socket.emit 'login', {
      user: user,
      pass: pass
    }


register = ->
  safe ->
    user = $('#username').val()
    pass = $('#password').val()

    socket.on 'register-complete', (data) ->
      setstatus "Welcome to our server, #{user} !"

    socket.on 'register-failed', (data) ->
      setstatus 'Failed to register', data.error, true

    socket.emit 'register', {
      user: user
      pass: pass
    }
