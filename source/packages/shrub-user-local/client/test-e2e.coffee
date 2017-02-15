```coffeescript

describe 'user', ->

  it 'should show a password reset page, but only if a token is provided', ->

    browser.get '/user/local/reset'
    expect(shrub.count '.shrub-user-local-reset').toBe 0

    browser.get '/user/local/reset/token'
    expect(shrub.count '.shrub-user-local-reset').toBe 1
```
