
describe 'home', ->

  beforeEach ->

    browser.get '/home'

  it 'should render home when user navigates to /home', ->

    expect(shrub.text 'h1').toBe 'Shrub'

describe 'about', ->

  beforeEach ->

    browser.get '/about'

  it 'should render about when user navigates to /about', ->

    expect(shrub.text 'h2').toBe 'Shrub'
