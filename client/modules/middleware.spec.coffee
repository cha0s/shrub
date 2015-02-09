
middleware = require 'middleware'

describe 'middleware', ->

  it 'can use and dispatch', ->

    middleware_ = new middleware.Middleware()

    first = false
    second = false
    third = false

    middleware_.use (req, res, next) ->

      first = req.foo is 69 and res.foo is 420

      next()

    middleware_.use (req, res, next) ->

      second = req.foo is 69 and res.foo is 420

      next()

    req = foo: 69
    res = foo: 420

    middleware_.dispatch req, res, (error) ->

      third = not error?

    expect(first).toBe true
    expect(second).toBe true
    expect(third).toBe true

  it 'can properly handle errors', ->

    middleware_ = new middleware.Middleware()

    first = true
    second = false
    third = true
    fourth = false
    fifth = false

    middleware_.use (req, res, next) ->

      next new Error()

    middleware_.use (req, res, next) ->

      first = false

      next()

    middleware_.use (error, req, res, next) ->

      second = true

      throw new Error()

    middleware_.use (req, res, next) ->

      third = false

      next()

    middleware_.use (error, req, res, next) ->

      fourth = true

      next error

    req = null
    res = null

    middleware_.dispatch req, res, (error) ->

      fifth = error?

    expect(first).toBe true
    expect(second).toBe true
    expect(third).toBe true
    expect(fourth).toBe true
    expect(fifth).toBe true
