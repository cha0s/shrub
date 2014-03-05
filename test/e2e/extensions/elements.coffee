
shrub = global.shrub ?= {}

findCss = shrub.find = (selector) -> element `by`.css selector

shrub.isVisible = (selector) -> (findCss selector).isDisplayed()

shrub.isPresent = (selector) -> browser.isElementPresent `by`.css selector

shrub.click = (selector) -> (element `by`.css selector).click()

shrub.text = (selector) -> (element `by`.css selector).getText()

shrub.count = (selector) -> (element.all `by`.css selector).count()

shrub.get = (selector, index = 0) -> (element.all `by`.css selector).get index
