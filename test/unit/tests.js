'use strict';

describe('shrub', function() {

  beforeEach(function() {
    module('shrub.core');
  });

  (function() {
    describe('form', function() {
      var form;
      form = null;
      beforeEach(function() {
        return inject([
          'form', function(_form_) {
            return form = _form_;
          }
        ]);
      });
      it('should automagically register a form when compiling a directive', function() {
        return inject([
          '$compile', '$rootScope', function($compile, $rootScope) {
            var scope, tpl;
            expect(form.lookup('test')).not.toBeDefined();
            tpl = $compile('<div data-form="test"></div>');
            scope = $rootScope.$new();
            scope.test = {};
            tpl(scope);
            return expect(form.lookup('test')).toBeDefined();
          }
        ]);
      });
      it('should generate correct form elements when compiled', function() {
        return inject([
          '$compile', '$rootScope', function($compile, $rootScope) {
            var $form, $input, childrenCount, elm, hasFormKey, input, name, scope, tpl, _i, _len, _ref, _ref1, _ref2;
            tpl = $compile('<div data-form="test"></div>');
            scope = $rootScope.$new();
            scope.test = {
              email: {
                type: 'email',
                label: "email"
              },
              password: {
                type: 'password',
                label: "password",
                required: true
              },
              text: {
                defaultValue: 'test',
                type: 'text',
                label: "text"
              }
            };
            elm = tpl(scope);
            $form = elm.find('form');
            expect($form.length).toBe(1);
            childrenCount = 0;
            hasFormKey = false;
            _ref = $form.find('input');
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              input = _ref[_i];
              $input = angular.element(input);
              name = input.name;
              if (-1 !== ['email', 'password', 'text'].indexOf(name)) {
                childrenCount += 1;
                expect(input.type).toBe(input.name);
              }
              if ((_ref1 = scope.test[name]) != null ? _ref1.required : void 0) {
                expect($input.attr('required')).toBeDefined();
              } else {
                expect($input.attr('required')).not.toBeDefined();
              }
              if (((_ref2 = scope.test[name]) != null ? _ref2.defaultValue : void 0) != null) {
                expect(scope.test[name].defaultValue).toBe(input.value);
              }
              if (name === 'formKey') {
                hasFormKey = true;
              }
            }
            expect(childrenCount).toBe(3);
            return expect(hasFormKey).toBe(true);
          }
        ]);
      });
      it('should handle form modification and submission', function() {
        return inject([
          '$compile', '$rootScope', function($compile, $rootScope) {
            var $form, $input, elm, input, scope, submissionCleared, tpl, _i, _len, _ref;
            tpl = $compile('<div data-form="test"></div>');
            scope = $rootScope.$new();
            submissionCleared = false;
            scope.test = {
              text: {
                type: 'text',
                label: "text"
              },
              submit: {
                type: 'submit',
                label: "Submit",
                handler: function() {
                  return submissionCleared = scope.text === 'test';
                }
              }
            };
            elm = tpl(scope);
            scope.text = 'test';
            scope.$digest();
            $form = elm.find('form');
            _ref = $form.find('input');
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              input = _ref[_i];
              $input = angular.element(input);
              if ('submit' === input.type) {
                input.click();
              }
            }
            return expect(submissionCleared).toBe(true);
          }
        ]);
      });
      return it('should handle rpc submission', function() {
        return inject([
          '$compile', '$rootScope', '$timeout', 'socket', function($compile, $rootScope, $timeout, socket) {
            var $form, $input, elm, input, rpcSubmission, scope, submissionCleared, tpl, _i, _len, _ref;
            tpl = $compile('<div data-form="test"></div>');
            scope = $rootScope.$new();
            rpcSubmission = '';
            submissionCleared = false;
            socket.catchEmit('rpc://test', function(data, fn) {
              rpcSubmission = data.text;
              return fn({
                result: 420
              });
            });
            scope.test = {
              text: {
                type: 'text',
                label: "text"
              },
              submit: {
                rpc: true,
                type: 'submit',
                label: "Submit",
                handler: function(error, result) {
                  return submissionCleared = result === 420;
                }
              }
            };
            elm = tpl(scope);
            scope.text = 'test';
            scope.$digest();
            $form = elm.find('form');
            _ref = $form.find('input');
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              input = _ref[_i];
              $input = angular.element(input);
              if ('submit' === input.type) {
                input.click();
              }
            }
            $timeout.flush();
            $rootScope.$apply();
            expect(rpcSubmission).toBe('test');
            return expect(submissionCleared).toBe(true);
          }
        ]);
      });
    });
  
  }).call(this);
  
  (function() {
    describe('rpc', function() {
      var rpc;
      rpc = null;
      beforeEach(function() {
        return inject([
          'rpc', function(_rpc_) {
            return rpc = _rpc_;
          }
        ]);
      });
      it('should send and receive data back from rpc calls', function() {
        return inject([
          '$rootScope', '$timeout', 'socket', function($rootScope, $timeout, socket) {
            var error, promise, result;
            socket.catchEmit('rpc://test', function(data, fn) {
              return fn({
                result: 420
              });
            });
            result = null;
            error = 'invalid';
            promise = rpc.call('test');
            promise.then(function(_) {
              return result = _;
            });
            promise["catch"](function(_) {
              return error = _;
            });
            $timeout.flush();
            $rootScope.$apply();
            expect(result).toBe(420);
            return expect(error).toBe('invalid');
          }
        ]);
      });
      return it('should handle errors gracefully', function(done) {
        return inject([
          '$rootScope', 'socket', function($rootScope, socket) {
            var error, promise, result;
            socket.catchEmit('rpc://test', function(data, fn) {
              return fn({
                error: new Error()
              });
            });
            result = 'invalid';
            error = null;
            promise = rpc.call('test');
            promise.then(function(_) {
              return result = _;
            });
            promise["catch"](function(_) {
              return error = _;
            });
            expect(result).toBe('invalid');
            expect(error).toBeDefined();
            return $rootScope.$apply();
          }
        ]);
      });
    });
  
  }).call(this);
  
  (function() {
    describe('md', function() {
      var markdown;
      markdown = null;
      beforeEach(function() {
        return inject(function(uiMarkdownFilter) {
          return markdown = uiMarkdownFilter;
        });
      });
      it('should be able to parse markdown into HTML', function() {
        return expect(markdown('Oh, *hello*')).toEqual('<p>Oh, <em>hello</em></p>\n');
      });
      it('should sanitize HTML by default', function() {
        return expect(markdown('Oh, <div>hello</div>')).toEqual('<p>Oh, &lt;div&gt;hello&lt;/div&gt;</p>\n');
      });
      return it('should allow unsanitized HTML, if requested', function() {
        return expect(markdown('Oh, <div>hello</div>', false)).toEqual('<p>Oh, <div>hello</div></p>\n');
      });
    });
  
    describe('notifications', function() {
      var notifications;
      notifications = null;
      beforeEach(function() {
        return inject([
          'ui/notifications', function(_notifications_) {
            return notifications = _notifications_;
          }
        ]);
      });
      it('should allow adding and removing notifications', function() {
        notifications.add({
          text: 'Testing'
        });
        expect(notifications.top().text).toBe('Testing');
        expect(notifications.count()).toBe(1);
        notifications.removeTop();
        expect(notifications.top()).toBe(void 0);
        return expect(notifications.count()).toBe(0);
      });
      return it('should accept notification batches from the socket', function() {
        return inject([
          '$timeout', 'socket', function($timeout, socket) {
            socket.stimulateOn('notifications', {
              notifications: [
                {
                  text: 'Testing'
                }, {
                  text: 'Testing'
                }, {
                  text: 'Testing'
                }, {
                  text: 'Testing'
                }
              ]
            });
            $timeout.flush();
            return expect(notifications.count()).toBe(4);
          }
        ]);
      });
    });
  
    describe('title', function() {
      var title;
      title = null;
      beforeEach(function() {
        return inject([
          'ui/title', function(_title_) {
            return title = _title_;
          }
        ]);
      });
      it('should set window title to page title [separator] site title by default when the page title is set', function() {
        title.setPage('Home');
        return expect(title.window()).toBe("" + (title.page()) + (title.separator()) + (title.site()));
      });
      return it('should allow page title to be set without altering the window title', function() {
        title.setPage('Home', false);
        return expect(title.site()).not.toContain('Home');
      });
    });
  
  }).call(this);
  
  (function() {
    describe('user', function() {
      var user;
      user = null;
      beforeEach(function() {
        return inject(function(_user_) {
          return user = _user_;
        });
      });
      it('should provide an anonymous user by default', function() {
        return expect(user.instance().id != null).toBe(false);
      });
      it('should log in a user through RPC', function() {
        return inject([
          '$rootScope', '$timeout', 'socket', function($rootScope, $timeout, socket) {
            socket.catchEmit('rpc://user.login', function(data, fn) {
              return fn({
                result: {
                  id: 1,
                  name: 'cha0s'
                }
              });
            });
            user.login('local', 'cha0s', 'password');
            $timeout.flush();
            $rootScope.$apply();
            return expect(user.isLoggedIn()).toBe(true);
          }
        ]);
      });
      return it('should log out a user through RPC', function() {
        return inject([
          '$rootScope', '$timeout', 'socket', function($rootScope, $timeout, socket) {
            socket.catchEmit('rpc://user.login', function(data, fn) {
              return fn({
                result: {
                  id: 1,
                  name: 'cha0s'
                }
              });
            });
            socket.catchEmit('rpc://user.logout', function(data, fn) {
              return fn({
                result: null
              });
            });
            (user.login('local', 'cha0s', 'password')).then(function() {
              return user.logout();
            });
            $timeout.flush();
            $rootScope.$apply();
            return expect(user.isLoggedIn()).toBe(false);
          }
        ]);
      });
    });
  
  }).call(this);
  
});