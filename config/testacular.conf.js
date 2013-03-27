basePath = '../';

files = [
  JASMINE,
  JASMINE_ADAPTER,
  'app/lib/angular/angular.js',
  'app/lib/angular/angular-*.js',
  'test/lib/angular/angular-mocks.js',
  'app/js/app.js',
  'app/js/controllers.js',
  'app/js/directives.js',
  'app/js/filters.js',
  'app/js/services.js',
  'app/js/mocks.js',
  'app/js/modules.js',
  'test/unit/**/*.js'
];

autoWatch = true;

browsers = ['Chrome'];

junitReporter = {
  outputFile: 'test_out/unit.xml',
  suite: 'unit'
};
