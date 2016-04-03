`/*jshint jquery: true*///`
`/*globals io:false, console:false, Cookies:false *///`

'use strict'

socket = null
sessionid = null
channels = []


setUsernameCookie = (username) ->
  if Cookies is undefined
    return undefined

  if $('#remember').is ':checked'
    Cookies.set 'username', username

getUsernameCookie = ->
  if Cookies is undefined
    return undefined

  Cookies.get 'username'

removeUsernameCookie = ->
  if Cookies is undefined
    return undefined

  Cookies.remove 'username'


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


checkPass = ->
  pass1 = $('#password').val()
  pass2 = $('#password2').val()
  registerbutton = $('#btn')

  if pass1 == pass2
    registerbutton.prop 'disabled', false
    $('#password2').removeClass 'badpass'
    $('#password2').addClass 'goodpass'
  else
    registerbutton.prop 'disabled', true
    $('#password2').removeClass 'goodpass'
    $('#password2').addClass 'badpass'


safe = (callback) ->
  try
    callback()
  catch err
    console.log err
    setstatus err.message, true


escapeRegex = (str) ->
  str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"


parseMessage = (html) ->
  emojis = {
    ':)': "http://emojione.com/wp-content/uploads/assets/emojis/1f603.svg"
    ':unicorn:': "http://emojione.com/wp-content/uploads/assets/emojis/1f984.svg"
  }

  for name in [
    '20%sadder', 'adrianyouhappynow', 'AJscared', 'bigmac', 'cadance', 'colgatehappy', 'derp', 'eyeroll', 'fabulous',
    'facehoof', 'greed', 'hero', 'laugh', 'lie', 'lyraexcited', 'lyrasad', 'NM2', 'NM3', 'notamused', 'photofinish',
    'ppsmile', 'pwink', 'RDhuh', 'rdsmile', 'rdwink', 'scared', 'science', 'seriousTS', 'shiny', 'shrug',
    'somethingwentwrong', 'spikemov', 'spike', 'squee', 'sweetie', 'thisisabrushie', 'thorg', 'trixie', 'tssmile',
    'twiblush', 'umad', 'vinyl', 'XTUXSmiley', 'yay', 'YEAH'
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


    $('#password').keydown (event) ->
      if event.keyCode == 13  # Enter
        event.preventDefault()
        $('#btn').click()


    # Login
    socket.on 'login-complete', (data) ->
      setUsernameCookie data.username

      setstatus "Welcome #{data.username}!", 'Loading chat...'
      initchat()

    socket.on 'login-failed', (data) ->
      setstatus 'Failed to login:', data.error, true

    # Register
    socket.on 'register-complete', (data) ->
      setstatus "Username '#{data.username}' has been successfully registered"

    socket.on 'register-failed', (data) ->
      setstatus 'Failed to register', data.error, true

    username = getUsernameCookie()
    unless username is undefined
      $('#username').val username



initchat = ->
  safe ->
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

      $('#msgbox').keydown (event) ->
        if event.keyCode is 13 # Enter
          event.preventDefault()
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

        html += "#{parseMessage message}</p>"

        $('#chatbox').html html + $('#chatbox').html()


      socket.on 'setchannels', (data) ->
        channels = data.channels

        $('#channels').html "Channels: #{channels.join ", "}"


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


logout = ->
  location.href += ''
