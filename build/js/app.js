(function() {
  'use strict';
  angular.module('shrub', ['ui.bootstrap', 'shrub.core']);

  angular.module('shrub.core', ['ngRoute', 'ngSanitize', 'shrub.config', 'shrub.packages', 'shrub.require']).config([
    '$injector', 'pkgmanProvider', function($injector, pkgmanProvider) {
      var injected, _, _ref, _results;
      _ref = pkgmanProvider.invokeWithMocks('appConfig');
      _results = [];
      for (_ in _ref) {
        injected = _ref[_];
        _results.push($injector.invoke(injected));
      }
      return _results;
    }
  ]).run([
    '$injector', 'pkgman', function($injector, pkgman) {
      var injected, _, _ref, _results;
      _ref = pkgman.invokeWithMocks('appRun');
      _results = [];
      for (_ in _ref) {
        injected = _ref[_];
        _results.push($injector.invoke(injected));
      }
      return _results;
    }
  ]);

}).call(this);
