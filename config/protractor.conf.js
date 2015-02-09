exports.config = {
  allScriptsTimeout: 11000,

  specs: [
    '../test/e2e/scenarios.js'
  ],

  capabilities: {
    'browserName': 'chrome'
  },

  baseUrl: 'http://localhost:4201/',

  framework: 'jasmine',

  jasmineNodeOpts: {
    defaultTimeoutInterval: 30000
  },

  onPrepare: '../test/e2e/extensions.js'
};
