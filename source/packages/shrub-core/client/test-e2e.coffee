
```coffeescript

describe 'core', ->

  it 'should be running the server in E2E mode', ->

    browser.get '/e2e/sanity-check'
    expect(browser.getCurrentUrl()).toContain '/e2e/sanity-check'
```
