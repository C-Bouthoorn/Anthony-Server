( () => {
  'use strict';

  let socket;

  function safe(callback) {
    try {
      callback();
    } catch(err) {
      status( err.message, true );
    }
  }


  function status(status, subscr, iserror) {
    if ( typeof subscr !== 'string' ) {
      iserror = subscr;
      subscr = '';
    }

    let elem = $('#connstatus');

    let html = status + '<br><small>' + subscr + '</small>';

    elem.html( html );
    if ( iserror ) {
      elem.addClass( 'error' );
    } else {
      elem.removeClass( 'error' );
    }
  }


  this.init = function() {
    safe( () => {
      socket = io.connect();

      socket.on( 'connect', () => {
        status("Connected to the server!");
      });

      $('#password').keyup( (event) => {
        if ( event.keyCode == 13 ) {
          $('#btn').click();
        }
      });

    });
  };


  this.login = function() {
    safe( () => {
      let user = $('#username').val(), pass = $('#password').val();

      socket.on( 'login-complete', (data) => {
        status( `Welcome ${user}!`, `Psst: ${data.secret}` );
      });

      socket.on( 'login-failed', (data) => {
        status( 'Failed to login:', data.error, true );
      });

      socket.emit( 'login', {
        user: user,
        pass: pass
      });
    });
  };


  this.register = function() {
    safe( () => {
      let user = $('#username').val(), pass = $('#password').val();

      socket.on( 'register-complete', (data) => {
        status( `Welcome ${user} to our server!` );
      });

      socket.on( 'register-failed', (data) => {
        status( 'Failed to register', data.error, true );
      });

      socket.emit( 'register', {
        user: user,
        pass: pass
      });
    });
  };

}).call(window);
