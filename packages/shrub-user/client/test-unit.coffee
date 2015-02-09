
describe 'user', ->

  user = null

  beforeEach ->

    inject [
      'shrub-user'
      (_user_) -> user = _user_
    ]

  it 'should provide an anonymous user by default', ->

    expect(user.instance().id?).toBe false

  it 'should log in a user through RPC', ->

    inject [
      '$rootScope', '$timeout', 'shrub-socket'
      ($rootScope, $timeout, socket) ->

        socket.catchEmit 'rpc://shrub.user.login', (data, fn) ->

          fn result: id: 1, name: 'cha0s'

        user.login 'local', 'cha0s', 'password'

        $timeout.flush()

        expect(user.isLoggedIn()).toBe true

    ]

  it 'should log out a user through RPC', ->

    inject [
      '$rootScope', '$timeout', 'shrub-socket'
      ($rootScope, $timeout, socket) ->

        socket.catchEmit 'rpc://user.login', (data, fn) ->
          fn result: id: 1, name: 'cha0s'

        socket.catchEmit 'rpc://user.logout', (data, fn) ->
          fn result: null

        (user.login 'local', 'cha0s', 'password').then -> user.logout()

        $timeout.flush()

        expect(user.isLoggedIn()).toBe false

    ]
