(function() {
  var findCss, shrub;

  shrub = global.shrub != null ? global.shrub : global.shrub = {};

  findCss = shrub.find = function(selector) {
    return element(by.css(selector));
  };

  shrub.isVisible = function(selector) {
    return (findCss(selector)).isDisplayed();
  };

  shrub.isPresent = function(selector) {
    return browser.isElementPresent(by.css(selector));
  };

  shrub.click = function(selector) {
    return (element(by.css(selector))).click();
  };

  shrub.text = function(selector) {
    return (element(by.css(selector))).getText();
  };

  shrub.count = function(selector) {
    return (element.all(by.css(selector))).count();
  };

  shrub.get = function(selector, index) {
    if (index == null) {
      index = 0;
    }
    return (element.all(by.css(selector))).get(index);
  };

}).call(this);
