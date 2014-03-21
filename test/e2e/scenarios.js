'use strict';

describe('shrub', function() {

  (function() {
    describe('core', function() {
      return it('should be running the server in E2E mode', function() {
        browser.get('/e2e/sanity-check');
        return expect(browser.getCurrentUrl()).toContain('/e2e/sanity-check');
      });
    });
  
  }).call(this);
  
  (function() {
    describe('home', function() {
      beforeEach(function() {
        return browser.get('/home');
      });
      return it('should render home when user navigates to /home', function() {
        return expect(shrub.text('h1')).toBe('Shrub');
      });
    });
  
    describe('about', function() {
      beforeEach(function() {
        return browser.get('/about');
      });
      return it('should render about when user navigates to /about', function() {
        return expect(shrub.text('h1')).toBe('Shrub');
      });
    });
  
  }).call(this);
  
  (function() {
    describe('user', function() {
      it('should show user pages', function() {
        var className, route, _i, _len, _ref, _ref1, _results;
        _ref = [['/user/login', 'userLogin'], ['/user/forgot', 'userForgot'], ['/user/register', 'userRegister']];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref1 = _ref[_i], route = _ref1[0], className = _ref1[1];
          browser.get(route);
          _results.push(expect(shrub.count("." + className)).toBe(1));
        }
        return _results;
      });
      it('should show a password reset page, but only if a token is provided', function() {
        browser.get('/user/reset');
        expect(shrub.count(".userReset")).toBe(0);
        browser.get('/user/reset/token');
        return expect(shrub.count(".userReset")).toBe(1);
      });
      return it('should redirect from certain pages when the user is logged in', function() {
        var destination, _i, _len, _ref, _results;
        _ref = ['forgot', 'login', 'register'];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          destination = _ref[_i];
          browser.get("/e2e/user/login/" + destination);
          _results.push(expect(browser.getCurrentUrl()).not.toContain("" + destination));
        }
        return _results;
      });
    });
  
  }).call(this);
  
});