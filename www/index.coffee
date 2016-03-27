`/*jshint jquery: true*///`
`/*globals io:false, console:false *///`

'use strict'

socket = null


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

    socket.on 'disconnect', ->
      setstatus 'Lost connection!', true

    $('#password').keyup (event) ->
      if event.keyCode == 13  # Enter
        $('#btn').click()


login = ->
  safe ->
    user = $('#username').val()
    pass = $('#password').val()

    socket.on 'login-complete', (data) ->
      setstatus "Welcome #{user}!", "Psst: #{data.secret}"

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
