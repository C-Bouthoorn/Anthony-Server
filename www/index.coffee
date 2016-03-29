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


escapeRegex = (str) ->
  str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"


parseEmoji = (html) ->
  emojis = {
    ':)': "http://emojione.com/wp-content/uploads/assets/emojis/1f603.svg"
  }

  for name in [
    '20%sadder', 'adrianyouhappynow', 'AJscared', 'bigmac', 'cadance', 'colgatehappy', 'eyeroll', 'fabulous',
    'facehoof', 'greed', 'hero', 'laugh', 'lie', 'lyraexcited', 'lyrasad', 'NM2', 'NM3', 'notamused', 'photofinish',
    'ppsmile', 'pwink', 'RDhuh', 'rdsmile', 'rdwink', 'scared', 'science', 'seriousTS', 'shiny', 'shrug',
    'somethingwentwrong', 'spikemov', 'spike', 'sweetie', 'thisisabrushie', 'thorg', 'trixie', 'tssmile',
    'twiblush', 'umad', 'vinyl', 'XTUXSmiley', 'YEAH'
  ]

    emojis[":#{name}:"] = "/images/#{name}.png"

  for emoji of emojis
    link = emojis[emoji]

    html = html.replace new RegExp(escapeRegex(emoji), 'gi'), "<img alt='#{emoji}' src='#{link}'>"


  return html


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


    # Login
    socket.on 'login-complete', (data) ->
      setstatus "Welcome #{username}!", 'Loading chat...'
      initchat()

    socket.on 'login-failed', (data) ->
      setstatus 'Failed to login:', data.error, true

    # Register
    socket.on 'register-complete', (data) ->
      setstatus "Welcome to our server, #{username} !"

    socket.on 'register-failed', (data) ->
      setstatus 'Failed to register', data.error, true



initchat = ->
  socket.on 'disconnect', ->
    unless $('#msgbox')?
      alert 'Disconnected from server!'

  socket.on 'chat-data', (data) ->
    html = data.html

    $('body').html html

    socket.on 'disconnect', ->
      msgbox = $('#msgbox')
      msgbox.hide()

      if $('#refreshlink')[0] is undefined
        msgbox.parent().append """
          <span id="refreshlink" class="error">Lost connection
          <a href style="display: none;" onclick="location.href=location.href"> Try refreshing?</a></span>
        """

      socket.on 'connect', ->
        $('#refreshlink a').show()

      socket.on 'disconnect', ->
        $('#refreshlink a').hide()

    $('#msgbox').keyup (event) ->
      if event.keyCode is 13 and not event.shiftKey # Enter
        message = $('#msgbox').val()
        $('#msgbox').val('')

        socket.emit 'client-send-message', {
          sessionid: sessionid
          message: message
        }

    socket.on 'client-receive-message', (data) ->
      user = data.user
      message = data.message

      html = "<p class='chat-message #{user.type}'>"

      unless user.name is "SERVER"
        html += "<span class='user'>#{user.name}: </span>"

      html += "#{parseEmoji message}</p>"

      $('#chatbox').html html + $('#chatbox').html()

  socket.emit 'get-chat-data', {}


login = ->
  safe ->
    username = $('#username').val()
    password = $('#password').val()

    socket.emit 'login', {
      username: username
      password: password
    }


register = ->
  safe ->
    username = $('#username').val()
    password = $('#password').val()

    socket.emit 'register', {
      username: username
      password: password
    }
