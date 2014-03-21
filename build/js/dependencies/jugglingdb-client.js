!function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.jugglingdb=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){

},{}],2:[function(_dereq_,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function EventEmitter() {
  this._events = this._events || {};
  this._maxListeners = this._maxListeners || undefined;
}
module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function(n) {
  if (!isNumber(n) || n < 0 || isNaN(n))
    throw TypeError('n must be a positive number');
  this._maxListeners = n;
  return this;
};

EventEmitter.prototype.emit = function(type) {
  var er, handler, len, args, i, listeners;

  if (!this._events)
    this._events = {};

  // If there is no 'error' event listener then throw.
  if (type === 'error') {
    if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
      er = arguments[1];
      if (er instanceof Error) {
        throw er; // Unhandled 'error' event
      } else {
        throw TypeError('Uncaught, unspecified "error" event.');
      }
      return false;
    }
  }

  handler = this._events[type];

  if (isUndefined(handler))
    return false;

  if (isFunction(handler)) {
    switch (arguments.length) {
      // fast cases
      case 1:
        handler.call(this);
        break;
      case 2:
        handler.call(this, arguments[1]);
        break;
      case 3:
        handler.call(this, arguments[1], arguments[2]);
        break;
      // slower
      default:
        len = arguments.length;
        args = new Array(len - 1);
        for (i = 1; i < len; i++)
          args[i - 1] = arguments[i];
        handler.apply(this, args);
    }
  } else if (isObject(handler)) {
    len = arguments.length;
    args = new Array(len - 1);
    for (i = 1; i < len; i++)
      args[i - 1] = arguments[i];

    listeners = handler.slice();
    len = listeners.length;
    for (i = 0; i < len; i++)
      listeners[i].apply(this, args);
  }

  return true;
};

EventEmitter.prototype.addListener = function(type, listener) {
  var m;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!isUndefined(this._maxListeners)) {
      m = this._maxListeners;
    } else {
      m = EventEmitter.defaultMaxListeners;
    }

    if (m && m > 0 && this._events[type].length > m) {
      this._events[type].warned = true;
      console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
      console.trace();
    }
  }

  return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.once = function(type, listener) {
  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  var fired = false;

  function g() {
    this.removeListener(type, g);

    if (!fired) {
      fired = true;
      listener.apply(this, arguments);
    }
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (isObject(list)) {
    for (i = length; i-- > 0;) {
      if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
        position = i;
        break;
      }
    }

    if (position < 0)
      return this;

    if (list.length === 1) {
      list.length = 0;
      delete this._events[type];
    } else {
      list.splice(position, 1);
    }

    if (this._events.removeListener)
      this.emit('removeListener', type, listener);
  }

  return this;
};

EventEmitter.prototype.removeAllListeners = function(type) {
  var key, listeners;

  if (!this._events)
    return this;

  // not listening for removeListener, no need to emit
  if (!this._events.removeListener) {
    if (arguments.length === 0)
      this._events = {};
    else if (this._events[type])
      delete this._events[type];
    return this;
  }

  // emit removeListener for all listeners on all events
  if (arguments.length === 0) {
    for (key in this._events) {
      if (key === 'removeListener') continue;
      this.removeAllListeners(key);
    }
    this.removeAllListeners('removeListener');
    this._events = {};
    return this;
  }

  listeners = this._events[type];

  if (isFunction(listeners)) {
    this.removeListener(type, listeners);
  } else {
    // LIFO order
    while (listeners.length)
      this.removeListener(type, listeners[listeners.length - 1]);
  }
  delete this._events[type];

  return this;
};

EventEmitter.prototype.listeners = function(type) {
  var ret;
  if (!this._events || !this._events[type])
    ret = [];
  else if (isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};

function isFunction(arg) {
  return typeof arg === 'function';
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isUndefined(arg) {
  return arg === void 0;
}

},{}],3:[function(_dereq_,module,exports){
if (typeof Object.create === 'function') {
  // implementation from standard node.js 'util' module
  module.exports = function inherits(ctor, superCtor) {
    ctor.super_ = superCtor
    ctor.prototype = Object.create(superCtor.prototype, {
      constructor: {
        value: ctor,
        enumerable: false,
        writable: true,
        configurable: true
      }
    });
  };
} else {
  // old school shim for old browsers
  module.exports = function inherits(ctor, superCtor) {
    ctor.super_ = superCtor
    var TempCtor = function () {}
    TempCtor.prototype = superCtor.prototype
    ctor.prototype = new TempCtor()
    ctor.prototype.constructor = ctor
  }
}

},{}],4:[function(_dereq_,module,exports){
// shim for using process in browser

var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
    && window.setImmediate;
    var canPost = typeof window !== 'undefined'
    && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return function (f) { return window.setImmediate(f) };
    }

    if (canPost) {
        var queue = [];
        window.addEventListener('message', function (ev) {
            var source = ev.source;
            if ((source === window || source === null) && ev.data === 'process-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('process-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

process.binding = function (name) {
    throw new Error('process.binding is not supported');
}

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};

},{}],5:[function(_dereq_,module,exports){
module.exports = function isBuffer(arg) {
  return arg && typeof arg === 'object'
    && typeof arg.copy === 'function'
    && typeof arg.fill === 'function'
    && typeof arg.readUInt8 === 'function';
}
},{}],6:[function(_dereq_,module,exports){
(function (process,global){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var formatRegExp = /%[sdj%]/g;
exports.format = function(f) {
  if (!isString(f)) {
    var objects = [];
    for (var i = 0; i < arguments.length; i++) {
      objects.push(inspect(arguments[i]));
    }
    return objects.join(' ');
  }

  var i = 1;
  var args = arguments;
  var len = args.length;
  var str = String(f).replace(formatRegExp, function(x) {
    if (x === '%%') return '%';
    if (i >= len) return x;
    switch (x) {
      case '%s': return String(args[i++]);
      case '%d': return Number(args[i++]);
      case '%j':
        try {
          return JSON.stringify(args[i++]);
        } catch (_) {
          return '[Circular]';
        }
      default:
        return x;
    }
  });
  for (var x = args[i]; i < len; x = args[++i]) {
    if (isNull(x) || !isObject(x)) {
      str += ' ' + x;
    } else {
      str += ' ' + inspect(x);
    }
  }
  return str;
};


// Mark that a method should not be used.
// Returns a modified function which warns once by default.
// If --no-deprecation is set, then it is a no-op.
exports.deprecate = function(fn, msg) {
  // Allow for deprecating things in the process of starting up.
  if (isUndefined(global.process)) {
    return function() {
      return exports.deprecate(fn, msg).apply(this, arguments);
    };
  }

  if (process.noDeprecation === true) {
    return fn;
  }

  var warned = false;
  function deprecated() {
    if (!warned) {
      if (process.throwDeprecation) {
        throw new Error(msg);
      } else if (process.traceDeprecation) {
        console.trace(msg);
      } else {
        console.error(msg);
      }
      warned = true;
    }
    return fn.apply(this, arguments);
  }

  return deprecated;
};


var debugs = {};
var debugEnviron;
exports.debuglog = function(set) {
  if (isUndefined(debugEnviron))
    debugEnviron = process.env.NODE_DEBUG || '';
  set = set.toUpperCase();
  if (!debugs[set]) {
    if (new RegExp('\\b' + set + '\\b', 'i').test(debugEnviron)) {
      var pid = process.pid;
      debugs[set] = function() {
        var msg = exports.format.apply(exports, arguments);
        console.error('%s %d: %s', set, pid, msg);
      };
    } else {
      debugs[set] = function() {};
    }
  }
  return debugs[set];
};


/**
 * Echos the value of a value. Trys to print the value out
 * in the best way possible given the different types.
 *
 * @param {Object} obj The object to print out.
 * @param {Object} opts Optional options object that alters the output.
 */
/* legacy: obj, showHidden, depth, colors*/
function inspect(obj, opts) {
  // default options
  var ctx = {
    seen: [],
    stylize: stylizeNoColor
  };
  // legacy...
  if (arguments.length >= 3) ctx.depth = arguments[2];
  if (arguments.length >= 4) ctx.colors = arguments[3];
  if (isBoolean(opts)) {
    // legacy...
    ctx.showHidden = opts;
  } else if (opts) {
    // got an "options" object
    exports._extend(ctx, opts);
  }
  // set default options
  if (isUndefined(ctx.showHidden)) ctx.showHidden = false;
  if (isUndefined(ctx.depth)) ctx.depth = 2;
  if (isUndefined(ctx.colors)) ctx.colors = false;
  if (isUndefined(ctx.customInspect)) ctx.customInspect = true;
  if (ctx.colors) ctx.stylize = stylizeWithColor;
  return formatValue(ctx, obj, ctx.depth);
}
exports.inspect = inspect;


// http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
inspect.colors = {
  'bold' : [1, 22],
  'italic' : [3, 23],
  'underline' : [4, 24],
  'inverse' : [7, 27],
  'white' : [37, 39],
  'grey' : [90, 39],
  'black' : [30, 39],
  'blue' : [34, 39],
  'cyan' : [36, 39],
  'green' : [32, 39],
  'magenta' : [35, 39],
  'red' : [31, 39],
  'yellow' : [33, 39]
};

// Don't use 'blue' not visible on cmd.exe
inspect.styles = {
  'special': 'cyan',
  'number': 'yellow',
  'boolean': 'yellow',
  'undefined': 'grey',
  'null': 'bold',
  'string': 'green',
  'date': 'magenta',
  // "name": intentionally not styling
  'regexp': 'red'
};


function stylizeWithColor(str, styleType) {
  var style = inspect.styles[styleType];

  if (style) {
    return '\u001b[' + inspect.colors[style][0] + 'm' + str +
           '\u001b[' + inspect.colors[style][1] + 'm';
  } else {
    return str;
  }
}


function stylizeNoColor(str, styleType) {
  return str;
}


function arrayToHash(array) {
  var hash = {};

  array.forEach(function(val, idx) {
    hash[val] = true;
  });

  return hash;
}


function formatValue(ctx, value, recurseTimes) {
  // Provide a hook for user-specified inspect functions.
  // Check that value is an object with an inspect function on it
  if (ctx.customInspect &&
      value &&
      isFunction(value.inspect) &&
      // Filter out the util module, it's inspect function is special
      value.inspect !== exports.inspect &&
      // Also filter out any prototype objects using the circular check.
      !(value.constructor && value.constructor.prototype === value)) {
    var ret = value.inspect(recurseTimes, ctx);
    if (!isString(ret)) {
      ret = formatValue(ctx, ret, recurseTimes);
    }
    return ret;
  }

  // Primitive types cannot have properties
  var primitive = formatPrimitive(ctx, value);
  if (primitive) {
    return primitive;
  }

  // Look up the keys of the object.
  var keys = Object.keys(value);
  var visibleKeys = arrayToHash(keys);

  if (ctx.showHidden) {
    keys = Object.getOwnPropertyNames(value);
  }

  // IE doesn't make error fields non-enumerable
  // http://msdn.microsoft.com/en-us/library/ie/dww52sbt(v=vs.94).aspx
  if (isError(value)
      && (keys.indexOf('message') >= 0 || keys.indexOf('description') >= 0)) {
    return formatError(value);
  }

  // Some type of object without properties can be shortcutted.
  if (keys.length === 0) {
    if (isFunction(value)) {
      var name = value.name ? ': ' + value.name : '';
      return ctx.stylize('[Function' + name + ']', 'special');
    }
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    }
    if (isDate(value)) {
      return ctx.stylize(Date.prototype.toString.call(value), 'date');
    }
    if (isError(value)) {
      return formatError(value);
    }
  }

  var base = '', array = false, braces = ['{', '}'];

  // Make Array say that they are Array
  if (isArray(value)) {
    array = true;
    braces = ['[', ']'];
  }

  // Make functions say that they are functions
  if (isFunction(value)) {
    var n = value.name ? ': ' + value.name : '';
    base = ' [Function' + n + ']';
  }

  // Make RegExps say that they are RegExps
  if (isRegExp(value)) {
    base = ' ' + RegExp.prototype.toString.call(value);
  }

  // Make dates with properties first say the date
  if (isDate(value)) {
    base = ' ' + Date.prototype.toUTCString.call(value);
  }

  // Make error with message first say the error
  if (isError(value)) {
    base = ' ' + formatError(value);
  }

  if (keys.length === 0 && (!array || value.length == 0)) {
    return braces[0] + base + braces[1];
  }

  if (recurseTimes < 0) {
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    } else {
      return ctx.stylize('[Object]', 'special');
    }
  }

  ctx.seen.push(value);

  var output;
  if (array) {
    output = formatArray(ctx, value, recurseTimes, visibleKeys, keys);
  } else {
    output = keys.map(function(key) {
      return formatProperty(ctx, value, recurseTimes, visibleKeys, key, array);
    });
  }

  ctx.seen.pop();

  return reduceToSingleString(output, base, braces);
}


function formatPrimitive(ctx, value) {
  if (isUndefined(value))
    return ctx.stylize('undefined', 'undefined');
  if (isString(value)) {
    var simple = '\'' + JSON.stringify(value).replace(/^"|"$/g, '')
                                             .replace(/'/g, "\\'")
                                             .replace(/\\"/g, '"') + '\'';
    return ctx.stylize(simple, 'string');
  }
  if (isNumber(value))
    return ctx.stylize('' + value, 'number');
  if (isBoolean(value))
    return ctx.stylize('' + value, 'boolean');
  // For some reason typeof null is "object", so special case here.
  if (isNull(value))
    return ctx.stylize('null', 'null');
}


function formatError(value) {
  return '[' + Error.prototype.toString.call(value) + ']';
}


function formatArray(ctx, value, recurseTimes, visibleKeys, keys) {
  var output = [];
  for (var i = 0, l = value.length; i < l; ++i) {
    if (hasOwnProperty(value, String(i))) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          String(i), true));
    } else {
      output.push('');
    }
  }
  keys.forEach(function(key) {
    if (!key.match(/^\d+$/)) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          key, true));
    }
  });
  return output;
}


function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
  var name, str, desc;
  desc = Object.getOwnPropertyDescriptor(value, key) || { value: value[key] };
  if (desc.get) {
    if (desc.set) {
      str = ctx.stylize('[Getter/Setter]', 'special');
    } else {
      str = ctx.stylize('[Getter]', 'special');
    }
  } else {
    if (desc.set) {
      str = ctx.stylize('[Setter]', 'special');
    }
  }
  if (!hasOwnProperty(visibleKeys, key)) {
    name = '[' + key + ']';
  }
  if (!str) {
    if (ctx.seen.indexOf(desc.value) < 0) {
      if (isNull(recurseTimes)) {
        str = formatValue(ctx, desc.value, null);
      } else {
        str = formatValue(ctx, desc.value, recurseTimes - 1);
      }
      if (str.indexOf('\n') > -1) {
        if (array) {
          str = str.split('\n').map(function(line) {
            return '  ' + line;
          }).join('\n').substr(2);
        } else {
          str = '\n' + str.split('\n').map(function(line) {
            return '   ' + line;
          }).join('\n');
        }
      }
    } else {
      str = ctx.stylize('[Circular]', 'special');
    }
  }
  if (isUndefined(name)) {
    if (array && key.match(/^\d+$/)) {
      return str;
    }
    name = JSON.stringify('' + key);
    if (name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)) {
      name = name.substr(1, name.length - 2);
      name = ctx.stylize(name, 'name');
    } else {
      name = name.replace(/'/g, "\\'")
                 .replace(/\\"/g, '"')
                 .replace(/(^"|"$)/g, "'");
      name = ctx.stylize(name, 'string');
    }
  }

  return name + ': ' + str;
}


function reduceToSingleString(output, base, braces) {
  var numLinesEst = 0;
  var length = output.reduce(function(prev, cur) {
    numLinesEst++;
    if (cur.indexOf('\n') >= 0) numLinesEst++;
    return prev + cur.replace(/\u001b\[\d\d?m/g, '').length + 1;
  }, 0);

  if (length > 60) {
    return braces[0] +
           (base === '' ? '' : base + '\n ') +
           ' ' +
           output.join(',\n  ') +
           ' ' +
           braces[1];
  }

  return braces[0] + base + ' ' + output.join(', ') + ' ' + braces[1];
}


// NOTE: These type checking functions intentionally don't use `instanceof`
// because it is fragile and can be easily faked with `Object.create()`.
function isArray(ar) {
  return Array.isArray(ar);
}
exports.isArray = isArray;

function isBoolean(arg) {
  return typeof arg === 'boolean';
}
exports.isBoolean = isBoolean;

function isNull(arg) {
  return arg === null;
}
exports.isNull = isNull;

function isNullOrUndefined(arg) {
  return arg == null;
}
exports.isNullOrUndefined = isNullOrUndefined;

function isNumber(arg) {
  return typeof arg === 'number';
}
exports.isNumber = isNumber;

function isString(arg) {
  return typeof arg === 'string';
}
exports.isString = isString;

function isSymbol(arg) {
  return typeof arg === 'symbol';
}
exports.isSymbol = isSymbol;

function isUndefined(arg) {
  return arg === void 0;
}
exports.isUndefined = isUndefined;

function isRegExp(re) {
  return isObject(re) && objectToString(re) === '[object RegExp]';
}
exports.isRegExp = isRegExp;

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}
exports.isObject = isObject;

function isDate(d) {
  return isObject(d) && objectToString(d) === '[object Date]';
}
exports.isDate = isDate;

function isError(e) {
  return isObject(e) &&
      (objectToString(e) === '[object Error]' || e instanceof Error);
}
exports.isError = isError;

function isFunction(arg) {
  return typeof arg === 'function';
}
exports.isFunction = isFunction;

function isPrimitive(arg) {
  return arg === null ||
         typeof arg === 'boolean' ||
         typeof arg === 'number' ||
         typeof arg === 'string' ||
         typeof arg === 'symbol' ||  // ES6 symbol
         typeof arg === 'undefined';
}
exports.isPrimitive = isPrimitive;

exports.isBuffer = _dereq_('./support/isBuffer');

function objectToString(o) {
  return Object.prototype.toString.call(o);
}


function pad(n) {
  return n < 10 ? '0' + n.toString(10) : n.toString(10);
}


var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
              'Oct', 'Nov', 'Dec'];

// 26 Feb 16:19:34
function timestamp() {
  var d = new Date();
  var time = [pad(d.getHours()),
              pad(d.getMinutes()),
              pad(d.getSeconds())].join(':');
  return [d.getDate(), months[d.getMonth()], time].join(' ');
}


// log is just a thin wrapper to console.log that prepends a timestamp
exports.log = function() {
  console.log('%s - %s', timestamp(), exports.format.apply(exports, arguments));
};


/**
 * Inherit the prototype methods from one constructor into another.
 *
 * The Function.prototype.inherits from lang.js rewritten as a standalone
 * function (not on Function.prototype). NOTE: If this file is to be loaded
 * during bootstrapping this function needs to be rewritten using some native
 * functions as prototype setup using normal JavaScript does not work as
 * expected during bootstrapping (see mirror.js in r114903).
 *
 * @param {function} ctor Constructor function which needs to inherit the
 *     prototype.
 * @param {function} superCtor Constructor function to inherit prototype from.
 */
exports.inherits = _dereq_('inherits');

exports._extend = function(origin, add) {
  // Don't do anything if add isn't an object
  if (!add || !isObject(add)) return origin;

  var keys = Object.keys(add);
  var i = keys.length;
  while (i--) {
    origin[keys[i]] = add[keys[i]];
  }
  return origin;
};

function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

}).call(this,_dereq_("/home/cha0s6983/dev/code/js/reddichat/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"),typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./support/isBuffer":5,"/home/cha0s6983/dev/code/js/reddichat/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":4,"inherits":3}],7:[function(_dereq_,module,exports){
(function (global,__dirname){
'use strict';

var fs = _dereq_('fs');
var path = _dereq_('path');

var Schema = exports.Schema = _dereq_('./lib/schema').Schema;
exports.AbstractClass = _dereq_('./lib/model.js');

var baseSQL = './lib/sql';

/*istanbul ignore next: depends on compoundjs*/
exports.__defineGetter__('BaseSQL', function () {
    return _dereq_(baseSQL);
});

/*istanbul ignore next: depends on compoundjs*/
exports.loadSchema = function(filename, settings, compound) {
    var schema = [];
    var definitions = _dereq_(filename);
    Object.keys(definitions).forEach(function(k) {
        var conf = settings[k];
        if (!conf) {
            console.log('No config found for ' + k + ' schema, using in-memory schema');
            conf = {driver: 'memory'};
        }
        schema[k] = new Schema(conf.driver, conf);
        schema[k].on('define', function(m, name, prop, sett) {
            compound.models[name] = m;
            if (conf.backyard) {
                schema[k].backyard.define(name, prop, sett);
            }
        });
        schema[k].name = k;
        schema.push(schema[k]);
        if (conf.backyard) {
            schema[k].backyard = new Schema(conf.backyard.driver, conf.backyard);
        }
        if ('function' === typeof definitions[k]) {
            define(schema[k], definitions[k]);
            if (conf.backyard) {
                define(schema[k].backyard, definitions[k]);
            }
        }
    });

    return schema;

    function define(db, def) {
        def(db, compound);
    }
};

/*istanbul ignore next: depends on compoundjs*/
exports.init = function (compound) {
    if (global.railway) {
        global.railway.orm = exports;
    } else {
        compound.orm = {
            Schema: exports.Schema,
            AbstractClass: exports.AbstractClass
        };
        if (compound.app.enabled('noeval schema')) {
            compound.orm.schema = exports.loadSchema(
                compound.root + '/db/schema',
                compound.app.get('database'),
                compound
            );
            if (compound.app.enabled('autoupdate')) {
                compound.on('ready', function() {
                    compound.orm.schema.forEach(function(s) {
                        s.autoupdate();
                        if (s.backyard) {
                            s.backyard.autoupdate();
                            s.backyard.log = s.log;
                        }
                    });
                });
            }
            return;
        }
    }

    // legacy stuff

    if (compound.version > '1.1.5-15') {
        compound.on('after routes', initialize);
    } else {
        initialize();
    }

    function initialize() {
        var railway = './lib/railway', init;
        try {
            init = _dereq_(railway);
        } catch (e) {
            console.log(e.stack);
        }
        if (init) {
            init(compound);
        }
    }
};

exports.__defineGetter__('version', function () {
    return JSON.parse(fs.readFileSync(__dirname + '/package.json')).version;
});
}).call(this,typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},"/")
},{"./lib/model.js":11,"./lib/schema":13,"fs":1,"path":false}],8:[function(_dereq_,module,exports){
'use strict';

/**
 * Module exports
 */
exports.Hookable = Hookable;

/**
 * Hooks mixins for ./model.js
 */
var Hookable = _dereq_('./model.js');

/**
 * List of hooks available
 */
Hookable.afterInitialize = null;
Hookable.beforeValidate = null;
Hookable.afterValidate = null;
Hookable.beforeSave = null;
Hookable.afterSave = null;
Hookable.beforeCreate = null;
Hookable.afterCreate = null;
Hookable.beforeUpdate = null;
Hookable.afterUpdate = null;
Hookable.beforeDestroy = null;
Hookable.afterDestroy = null;

Hookable.prototype.trigger = function trigger(actionName, work, data, quit){
  var capitalizedName = capitalize(actionName);
  var beforeHook = this.constructor['before' + capitalizedName];
  var afterHook = this.constructor['after' + capitalizedName];
  if (actionName === 'validate') {
    beforeHook = beforeHook || this.constructor.beforeValidation;
    afterHook = afterHook || this.constructor.afterValidation;
  }
  var inst = this;

  // we only call "before" hook when we have actual action (work) to perform
  if (work) {
    if (beforeHook) {
      // before hook should be called on instance with one param: callback
      beforeHook.call(inst, function (err){
        if (err) {
          if (quit) {
            quit(err);
          }
          return;
        }
        // actual action also have one param: callback
        work.call(inst, next);
      }, data);
    } else {
      work.call(inst, next);
    }
  } else {
    next();
  }

  function next(done){
    /*jshint validthis:true */
    if (afterHook) {
      afterHook.call(inst, done);
    } else if (done) {
      done.call(this);
    }
  }
};

function capitalize(string){
  return string.charAt(0).toUpperCase() + string.slice(1);
}

},{"./model.js":11}],9:[function(_dereq_,module,exports){
'use strict';

/**
 * Include mixin for ./model.js
 */
var
  AbstractClass = _dereq_('./model.js'),
  utils = _dereq_('./utils')
  ;

/**
 * Allows you to load relations of several objects and optimize numbers of requests.
 *
 * @param {Array} objects - array of instances
 * @param {String|Object|Array} include - which relations you want to load.
 * @param {Function} [cb] - Callback called when relations are loaded
 *
 * Examples:
 *
 * - User.include(users, 'posts', function() {}); will load all users posts with only one additional request.
 * - User.include(users, ['posts'], function() {}); // same
 * - User.include(users, ['posts', 'passports'], function() {}); // will load all users posts and passports with two
 *     additional requests.
 * - Passport.include(passports, {owner: 'posts'}, function() {}); // will load all passports owner (users), and all
 *     posts of each owner loaded
 * - Passport.include(passports, {owner: ['posts', 'passports']}); // ...
 * - Passport.include(passports, {owner: [{posts: 'images'}, 'passports']}); // ...
 *
 */
AbstractClass.include = function (objects, include, cb){
  var self = this;

  if (
    (include.constructor.name == 'Array' && include.length === 0) ||
      (include.constructor.name == 'Object' && Object.keys(include).length === 0)
    ) {
    return utils.Q.resolve(objects).nodeify(cb);
  }

  var d = utils.defer();

  include = processIncludeJoin(include);

  var keyVals = {};
  var objsByKeys = {};

  var nbCallbacks = 0;

  function cbed(){
    nbCallbacks--;
    if (nbCallbacks === 0) {
      d.resolve(objects);
    }
  }

  try {
    for (var i = 0; i < include.length; i++) {
      var callback = processIncludeItem(objects, include[i], keyVals, objsByKeys);

      if (callback !== null) {
        nbCallbacks++;
        callback(cbed);
      } else {
        d.resolve(objects);
        break;
      }
    }
  } catch (e) {
    d.reject(e);
  }

  function processIncludeJoin(ij){
    if (typeof ij === 'string') {
      ij = [ij];
    }
    if (ij.constructor.name === 'Object') {
      var newIj = [];
      for (var key in ij) {
        var obj = {};
        obj[key] = ij[key];
        newIj.push(obj);
      }
      return newIj;
    }
    return ij;
  }

  function processIncludeItem(objs, include, keyVals, objsByKeys){
    var relations = self.relations, relationName, subInclude;

    if (include.constructor.name === 'Object') {
      relationName = Object.keys(include)[0];
      subInclude = include[relationName];
    } else {
      relationName = include;
      subInclude = [];
    }
    var relation = relations[relationName];

    if (!relation) {
      return function (){
        throw new Error('Relation "' + relationName + '" is not defined for ' + self.modelName + ' model');
      };
    }

    var req = {'where': {}};

    if (!keyVals[relation.keyFrom]) {
      objsByKeys[relation.keyFrom] = {};
      objs.filter(Boolean).forEach(function (obj){
        if (!objsByKeys[relation.keyFrom][obj[relation.keyFrom]]) {
          objsByKeys[relation.keyFrom][obj[relation.keyFrom]] = [];
        }
        objsByKeys[relation.keyFrom][obj[relation.keyFrom]].push(obj);
      });
      keyVals[relation.keyFrom] = Object.keys(objsByKeys[relation.keyFrom]);
    }

    if (keyVals[relation.keyFrom].length > 0) {
      // deep clone is necessary since inq seems to change the processed array
      var keysToBeProcessed = {};
      var inValues = [];
      for (var j = 0; j < keyVals[relation.keyFrom].length; j++) {
        keysToBeProcessed[keyVals[relation.keyFrom][j]] = true;
        if (keyVals[relation.keyFrom][j] !== 'null' && keyVals[relation.keyFrom][j] !== 'undefined') {
          inValues.push(keyVals[relation.keyFrom][j]);
        }
      }

      req['where'][relation.keyTo] = {inq: inValues};
      req['include'] = subInclude;

      return function (cb){
        var objectsFrom, j;

        relation.modelTo.all(req).done(function (objsIncluded){
          for (var i = 0; i < objsIncluded.length; i++) {
            delete keysToBeProcessed[objsIncluded[i][relation.keyTo]];
            objectsFrom = objsByKeys[relation.keyFrom][objsIncluded[i][relation.keyTo]];
            for (j = 0; j < objectsFrom.length; j++) {
              if (!objectsFrom[j].__cachedRelations) {
                objectsFrom[j].__cachedRelations = {};
              }
              if (relation.multiple) {
                if (!objectsFrom[j].__cachedRelations[relationName]) {
                  objectsFrom[j].__cachedRelations[relationName] = [];
                }
                objectsFrom[j].__cachedRelations[relationName].push(objsIncluded[i]);
              } else {
                objectsFrom[j].__cachedRelations[relationName] = objsIncluded[i];
              }
            }
          }

          // No relation have been found for these keys
          for (var key in keysToBeProcessed) {
            objectsFrom = objsByKeys[relation.keyFrom][key];
            for (j = 0; j < objectsFrom.length; j++) {
              if (!objectsFrom[j].__cachedRelations) {
                objectsFrom[j].__cachedRelations = {};
              }
              objectsFrom[j].__cachedRelations[relationName] = relation.multiple ? [] : null;
            }
          }
          cb(null, objsIncluded);
        }, cb);
      };
    }

    return null;
  }

  return d.promise.nodeify(cb);
};
},{"./model.js":11,"./utils":15}],10:[function(_dereq_,module,exports){
'use strict';

var
  util = _dereq_('util'),
  utils = _dereq_('./utils');

module.exports = List;

/**
 * List class provides functionality of nested collection
 *
 * @param {Array} data - array of items.
 * @param {*} type - array with some type information? TODO: rework this API.
 * @param {AbstractClass} parent - owner of list.
 * @constructor
 */
function List(data, type, parent){
  var list = this;
  if (!(list instanceof List)) {
    return new List(data, type, parent);
  }

  if (data && data instanceof List) {
    data = data.items;
  }

  Object.defineProperty(list, 'parent', {
    writable    : false,
    enumerable  : false,
    configurable: false,
    value       : parent
  });

  Object.defineProperty(list, 'nextid', {
    writable  : true,
    enumerable: false,
    value     : 1
  });

  var Item = ListItem;
  if (typeof type === 'object' && type.constructor.name === 'Array') {
    Item = type[0] || ListItem;
  }

  data = list.items = data || [];
  Object.defineProperty(list, 'ItemType', {
    writable    : true,
    enumerable  : false,
    configurable: true,
    value       : Item
  });

  if ('string' === typeof data) {
    try {
      list.items = data = JSON.parse(data);
    } catch (e) {
      list.items = data = [];
    }
  }

  data.forEach(function (item, i){
    data[i] = new Item(item, list);
    Object.defineProperty(list, data[i].id, {
      writable    : true,
      enumerable  : false,
      configurable: true,
      value       : data[i]
    });
    if (list.nextid <= data[i].id) {
      list.nextid = data[i].id + 1;
    }
  });

  Object.defineProperty(list, 'length', {
    enumerable  : false,
    configurable: true,
    get         : function (){
      return list.items.length;
    }
  });

  return list;

}

List.prototype.inspect = function (){
  return util.inspect(this.items);
};

var _;
try {
  var lodash = 'lodash';
  _ = _dereq_(lodash);
} catch (e) {
  _ = false;
}

if (!_) {
  /*istanbul ignore next*/
  try {
    var underscore = 'underscore';
    _ = _dereq_(underscore);
  } catch (e) {
    _ = false;
  }
}

  /*istanbul ignore next: can't test properly*/
if (_) {
  var _import = [
    // collection methods
    'each',
    'map',
    'reduce',
    'reduceRight',
    'find',
    'filter',
    'reject',
    'all',
    'any',
    'include',
    'invoke',
    'pluck',
    'max',
    'min',
    'sortBy',
    'groupBy',
    'sortedIndex',
    'shuffle',
    'toArray',
    'size',
    // array methods
    'first',
    'initial',
    'last',
    'rest',
    'compact',
    'flatten',
    'without',
    'union',
    'intersection',
    'difference',
    'uniq',
    'zip',
    'indexOf',
    'lastIndexOf',
    'range'
  ];

  _import.forEach(function (name){
    List.prototype[name] = function (){
      var args = utils.slice.call(arguments);
      args.unshift(this.items);
      return _[name].apply(_, args);
    };
  });
}

// copy all array methods
[   'concat',
  'join',
  'pop',
  'push',
  'reverse',
  'shift',
  'slice',
  'sort',
  'splice',
  'toSource',
  'toString',
  'unshift',
  'every',
  'filter',
  'forEach',
  'indexOf',
  'lastIndexOf',
  'map',
  'some'
].forEach(function (method){
    List.prototype[method] = function (){
      return Array.prototype[method].apply(this.items, utils.slice.call(arguments));
    };
  });

List.prototype.find = function (pattern, field){
  if (!field) {
    field = 'id';
  }
  var res;
  this.items.forEach(function (o){
    if (o[field] == pattern) {
      res = o;
    }
  });
  return res;
};

List.prototype.removeAt = function (index){
  this.splice(index, 1);
};

List.prototype.toObject = function (){
  return this.items;
};

List.prototype.toJSON = function (){
  return this.items;
};

List.prototype.toString = function (){
  return JSON.stringify(this.items);
};

List.prototype.autoincrement = function (){
  return this.nextid++;
};

List.prototype.push = function (obj){
  var item = new ListItem(obj, this);
  this.items.push(item);
  return item;
};

List.prototype.remove = function (obj){
  var id = obj.id ? obj.id : obj;
  var found = false;
  this.items.forEach(function (o, i){
    if (id && o.id == id) {
      found = i;
      /*istanbul ignore next: not testable*/
      if (o.id !== id) {
        console.log('WARNING! Type of id not matched');
      }
    }
  });
  if (found !== false) {
    delete this[id];
    this.items.splice(found, 1);
  }
};

List.prototype.map = function (cb){
  if (typeof cb === 'function') {
    return this.items.map(cb);
  }
  if (typeof cb === 'string') {
    return this.items.map(function (el){
      if (typeof el[cb] === 'function') {
        return el[cb]();
      }
      if (el.hasOwnProperty(cb)) {
        return el[cb];
      }
    });
  }
};

function ListItem(data, parent){
  if (typeof data === 'object') {
    for (var i in data) {
      this[i] = data[i];
    }
  } else {
    this.id = data;
  }
  Object.defineProperty(this, 'parent', {
    writable    : false,
    enumerable  : false,
    configurable: true,
    value       : parent
  });
  if (!this.id) {
    this.id = parent.autoincrement();
  }
  if (parent.ItemType) {
    this.__proto__ = parent.ItemType.prototype;
    /*istanbul ignore next: edge case */
    if (parent.ItemType !== ListItem) {
      parent.ItemType.apply(this);
    }
  }

}
/*istanbul ignore next: edge case */
ListItem.prototype.save = function save(){
  this.parent.parent.save();
};


},{"./utils":15,"util":6}],11:[function(_dereq_,module,exports){
'use strict';

/**
 * Module exports class Model
 */
module.exports = AbstractClass;

/**
 * Module dependencies
 */
var
  util = _dereq_('util'),
  utils = _dereq_('./utils'),
  curry = utils.curry,
  validations = _dereq_('./validations.js'),
  ValidationError = validations.ValidationError,
  List = _dereq_('./list.js');

_dereq_('./hooks.js');
_dereq_('./relations.js');
_dereq_('./include.js');

var BASE_TYPES = ['String', 'Boolean', 'Number', 'Date', 'Text'];

/**
 * AbstractClass class - base class for all persist objects
 * provides **common API** to access any database adapter.
 * This class describes only abstract behavior layer, refer to `lib/adapters/*.js`
 * to learn more about specific adapter implementations
 *
 * `AbstractClass` mixes `Validatable` and `Hookable` classes methods
 *
 * @constructor
 * @param {Object} data - initial object data
 */
function AbstractClass(data){
  this._initProperties(data, true);
}

AbstractClass.prototype._initProperties = function (data, applySetters){
  var self = this;
  var ctor = this.constructor;
  var ds = ctor.schema.definitions[ctor.modelName];
  var properties = ds.properties;
  data = data || {};

  if (typeof data === 'string') {
    data = JSON.parse(data);
  }

  utils.hiddenProperty(this, '__cachedRelations', {});
  utils.hiddenProperty(this, '__data', {});
  utils.hiddenProperty(this, '__dataWas', {});

  if (data['__cachedRelations']) {
    this.__cachedRelations = data['__cachedRelations'];
  }

  for (var i in data) {
    if (i in properties) {
      this.__data[i] = this.__dataWas[i] = data[i];
    } else if (i in ctor.relations) {
      this.__data[ctor.relations[i].keyFrom] = this.__dataWas[i] = data[i][ctor.relations[i].keyTo];
      this.__cachedRelations[i] = data[i];
    }
  }

  if (applySetters === true) {
    Object.keys(data).forEach(function (attr){
      self[attr] = data[attr];
    });
  }

  ctor.forEachProperty(function (attr){

    if ('undefined' === typeof self.__data[attr]) {
      self.__data[attr] = self.__dataWas[attr] = getDefault(attr);
    } else {
      self.__dataWas[attr] = self.__data[attr];
    }

  });

  ctor.forEachProperty(function (attr){

    var type = properties[attr].type;

    if (BASE_TYPES.indexOf(type.name) === -1) {
      if (typeof self.__data[attr] !== 'object' && self.__data[attr]) {
        try {
          self.__data[attr] = JSON.parse(self.__data[attr] + '');
        } catch (e) {
          self.__data[attr] = String(self.__data[attr]);
        }
      }
      if (type.name === 'Array' || typeof type === 'object' && type.constructor.name === 'Array') {
        self.__data[attr] = new List(self.__data[attr], type, self);
      }
    }

  });

  function getDefault(attr){
    var def = properties[attr]['default'];
    if (isdef(def)) {
      if (typeof def === 'function') {
        return def();
      } else {
        return def;
      }
    } else {
      return undefined;
    }
  }

  this.trigger('initialize');
};

/**
 * @param {String} prop - property name
 * @param {Object} params - various property configuration
 */
AbstractClass.defineProperty = function (prop, params){
  this.schema.defineProperty(this.modelName, prop, params);
};

AbstractClass.whatTypeName = function (propName){
  var prop = this.schema.definitions[this.modelName].properties[propName];
  if (!prop || !prop.type) {
    return null;
    // throw new Error('Undefined type for ' + this.modelName + ':' + propName);
  }
  return prop.type.name;
};

/**
 * Updates the respective record
 *
 * @param {Object} params - { where:{uid:'10'}, update:{ Name:'New name' } }
 * @param {Function} [cb] Optional callback
 *
 * @returns {Promise.promise}
 */
AbstractClass.update = function update(params, cb){
  var Model = this;

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    if (params && params.update && typeof params.update !== 'function') {
      params.update = Model._forDB(params.update);
    }

    Model.schema.adapter.update(Model.modelName, params, function (err, obj){
      if (err) {
        d.reject(err);
      } else {
        d.resolve(Model._fromDB(obj));
      }
    });

    return d.promise;
  }).nodeify(cb);
};

/**
 * Prepares data for storage adapter.
 *
 * Ensures data is allowed by the schema, and stringifies JSON field types.
 * If the schema defines a custom field name, it is transformed here.
 *
 * @param {Object} data
 * @return {Object} Returns data for storage.
 */
AbstractClass._forDB = function (data){
  if (!data) {
    return null;
  }
  var
    res = {},
    Model = this,
    definition = this.schema.definitions[Model.modelName].properties;

  Object.keys(data).forEach(function (propName){
    var val;
    var typeName = Model.whatTypeName(propName);

    if (!typeName && !data[propName] instanceof Array) {
      return;
    }
    val = data[propName];
    if (definition[propName] && definition[propName].name) {
      // Use different name for DB field/column
      res[definition[propName].name] = val;
    } else {
      res[propName] = val;
    }
  });

  return res;
};

/**
 * Unpacks data from storage adapter.
 *
 * If the schema defines a custom field name, it is transformed here.
 *
 * @param {Object} data
 * @return {Object}
 */
AbstractClass._fromDB = function (data){
  if (!data) {
    return null;
  }

  var
    definition = this.schema.definitions[this.modelName].properties,
    propNames = Object.keys(data);

  Object.keys(definition).forEach(function (defPropName){
    var customName = definition[defPropName].name;
    if (customName && propNames.indexOf(customName) !== -1) {
      data[defPropName] = data[customName];
      delete data[customName];
    }
  });

  return data;
};

AbstractClass.prototype.whatTypeName = function (propName){
  return this.constructor.whatTypeName(propName);
};

/**
 * Create new instance of Model class, saved in database
 *
 * @param data [optional]
 * @param {Function} [cb] Optional callback
 *
 * @returns {PromiseResolver.promise}
 */
AbstractClass.create = function create(data, cb){
  var
    Model = this;

  if (typeof data === 'function') {
    cb = data;
    data = {};
  }

  return stillConnecting(Model.schema).then(function(){
    var
      d = utils.defer(),
      modelName = Model.modelName;

    data = data || {};

    // Passed via data from save
    var options = data.options || { validate: true };

    if (data.data instanceof Model) {
      data = data.data;
    }

    if (data instanceof Array) {
      var
        instances = [],
        length = data.length,
        errors,
        gotError = false,
        wait = length;

      if (length === 0) {
        d.resolve([]);
      } else {
        errors = new Array(length);

        var modelCreated = function (){
          if (--wait === 0) {
            if (gotError) {
              d.reject(errors);
            } else {
              d.resolve(instances);
            }
          }
        };

        var createModel = function (d, i){
          Model.create(d).catch(function (err){
            if (err) {
              errors[i] = err;
              gotError = true;
            }
            modelCreated();
          }).done(function(inst){
            instances.push(inst);
            modelCreated();
          });
        };

        for (var i = 0; i < length; i += 1) {
          createModel(data[i], i);
        }
      }
    } else {
      var
        obj,
        reject = curry(d.reject, d),
        innerCreate = function (){
          obj.trigger('create', function (createDone){
            obj.trigger('save', function (saveDone){
              obj._adapter().create(modelName, Model._forDB(obj.toObject(true)), function adapterCreate(err, id, rev){
                if (id) {
                  obj.__data.id = id;
                  obj.__dataWas.id = id;
                  utils.defineReadonlyProp(obj, 'id', id);
                }
                if (rev) {
                  rev = Model._fromDB(rev);
                  obj._rev = rev;
                }
                if (err) {
                  d.reject(err);
                } else {
                  saveDone.call(obj, function saveDoneCall(){
                    createDone.call(obj, function createDoneCall(){
                      d.resolve(obj);
                    });
                  });
                }
              }, obj);
            }, obj, reject);
          }, obj, reject);
        };

      // if we come from save
      if (data instanceof Model && !data.id) {
        obj = data;
      } else {
        obj = new Model(data);
      }
      data = obj.toObject(true);

      if (!options.validate) {
        innerCreate();
      } else {
        // validation required
        obj.isValid(data).done(
          innerCreate,
          function(err){
            d.reject(err);
          }
        );
      }
    }

    return d.promise;
  }).nodeify(cb);
};

/**
 *
 * @param schema
 *
 * @returns {PromiseResolver.promise}
 */
function stillConnecting(schema){
  var d = utils.defer();

  if (schema.connected) {
    d.resolve();
  } else {
    schema.once('connected', function(){
      d.resolve();
    });

    if (!schema.connecting) {
      schema.connect();
    }
  }

  return d.promise;
}

/**
 * Update or insert
 *
 * @param {Object} data
 * @param {Function} [cb] Optional callback
 */
AbstractClass.upsert = AbstractClass.updateOrCreate = function upsert(data, cb){
  var Model = this;

  return stillConnecting(Model.schema).then(function(){
    if (!data.id) {
      return Model.create(data);
    }

    var
      d = utils.defer(),
      resolve = curry(d.resolve, d),
      reject = curry(d.reject, d);

    if (typeof Model.schema.adapter.updateOrCreate === 'function') {
      var inst = new Model(data);

      Model.schema.adapter.updateOrCreate(Model.modelName, Model._forDB(inst.toObject(true)), function (err, data){
        var obj;

        if (data) {
          data = inst.constructor._fromDB(data);
          inst._initProperties(data);
          obj = inst;
        } else {
          obj = null;
        }

        if (err) {
          d.reject(err);
        } else {
          d.resolve(obj);
        }
      });
    } else {
      Model.find(data.id).done(function (inst){
        if (inst) {
          inst.updateAttributes(data).done(resolve, reject);
        } else {
          var obj = new Model(data);
          obj.save(data).done(resolve, reject);
        }
      }, reject);
    }

    return d.promise;
  }).nodeify(cb);
};

/**
 * Find one record, same as `all`, limited by 1 and return object, not collection,
 * if not found, create using data provided as second argument
 *
 * @param {Object} query - search conditions: {where: {test: 'me'}}.
 * @param {Object|Function} data - object to create.
 * @param {Function} [cb] Optional callback
 * @returns {PromiseResolver.promise}
 */
AbstractClass.findOrCreate = function findOrCreate(query, data, cb){
  if (typeof query === 'undefined') {
    query = {where: {}};
  }

  if (typeof data === 'function' || typeof data === 'undefined') {
    data = query && query.where;
  }

  var Model = this;

  return Model.findOne(query).then(function (record){
    if (record) {
      return record;
    }
    return Model.create(data);
  }).nodeify(cb);
};

/**
 * Check whether object exitst in database
 *
 * @param {id} id - identifier of object (primary key value)
 * @param {Function} [cb] Optional callback
 */
AbstractClass.exists = function exists(id, cb){
  var Model = this;

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    if (id) {
      Model.schema.adapter.exists(Model.modelName, id, d.callback);
    } else {
      d.reject(new Error('Model::exists requires positive id argument'));
    }

    return d.promise;
  }).nodeify(cb);
};

/**
 * Find object by id
 *
 * @param {id} id - primary key value
 * @param {Function} [cb] Optional callback
 *
 * @returns {PromiseResolver.promise}
 */
AbstractClass.find = function find(id, cb){
  var Model = this;

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    Model.schema.adapter.find(Model.modelName, id, function (err, data){
      var obj = null;

      if (data) {
        data = Model._fromDB(data);
        if (!data.id) {
          data.id = id;
        }
        obj = new Model();
        obj._initProperties(data, false);
      }

      if (err) {
        d.reject(err);
      } else {
        d.resolve(obj);
      }
    });

    return d.promise;
  }).nodeify(cb);
};

/**
 * Find all instances of Model, matched by query
 * make sure you have marked as `index: true` fields for filter or sort
 *
 * @param {Object} params (optional)
 *
 * - where: Object `{ key: val, key2: {gt: 'val2'}}`
 * - include: String, Object or Array. See AbstractClass.include documentation.
 * - order: String
 * - limit: Number
 * - skip: Number
 *
 * @param {Function} [cb] Optional callback
 *
 * @returns {PromiseResolver.promise}
 */
AbstractClass.all = function all(params, cb){
  var Model = this;

  if (typeof params === 'function') {
    cb = params;
    params = {};
  }

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();


    if (params) {
      if ('skip' in params) {
        params.offset = params.skip;
      } else if ('offset' in params) {
        params.skip = params.offset;
      }
    }

    if (params && params.where && typeof params.where !== 'function') {
      params.where = Model._forDB(params.where);
    }

    Model.schema.adapter.all(Model.modelName, params, function (err, data){
      if (data && data.forEach) {

        if (!params || !params.onlyKeys) {

          data.forEach(function (_data, i){
            var obj = new Model();
            _data = Model._fromDB(_data);
            obj._initProperties(_data, false);
            if (params && params.include && params.collect) {
              data[i] = obj.__cachedRelations[params.collect];
            } else {
              data[i] = obj;
            }
          });
        }

        if (err) {
          d.reject(err);
        } else {
          d.resolve(data);
        }
      } else {
        if (err) {
          d.reject(err);
        } else {
          d.resolve([]);
        }
      }
    });

    return d.promise;
  }).nodeify(cb);
};

/**
 * Iterate through dataset and perform async method iterator. This method
 * designed to work with large datasets loading data by batches.
 *
 * @param {Object|Function} filter - query conditions. Same as for `all` may contain
 * optional member `batchSize` to specify size of batch loaded from db. Optional.
 * @param {Function} iterator - method(obj, next) called on each obj.
 * @param {Function} [cb] Optional callback
 */
AbstractClass.iterate = function map(filter, iterator, cb){
  var
    Model = this,
    d = utils.defer();

  if ('function' === typeof filter) {
    iterator = filter;
    filter = {};
  }

  function done(err){
    if (err) {
      d.reject(err);
    } else {
      d.resolve(batchNumber);
    }
  }

  var concurrent = filter.concurrent;
  delete filter.concurrent;
  var limit = filter.limit;
  var batchSize = filter.limit = filter.batchSize || 1000;
  var batchNumber = -1;

  nextBatch();

  function nextBatch(){
    batchNumber += 1;
    filter.skip = filter.offset = batchNumber * batchSize;

    if (limit < batchSize) {
      filter.limit = Math.abs(limit);
    }

    if (filter.limit <= 0) {
      done();
      return;
    }

    Model.all(filter).done(function (collection){
      if (collection.length === 0 || limit <= 0) {
        done();
        return;
      }

      var nextItem = function (err){
        if (err) {
          done(err);
          return;
        }

        if (++i >= collection.length) {
          nextBatch();
          return;
        }

        iterator(collection[i], nextItem, filter.offset + i);
      };

      limit -= collection.length;
      var i = -1;
      if (concurrent) {
        var wait = collection.length, _next;

        _next = function (){
          if (--wait === 0) {
            nextBatch();
          }
        };

        collection.forEach(function (obj, i){
          iterator(obj, _next, filter.offset + i);
        });
      } else {
        nextItem();
      }
    }, curry(d.reject, d));
  }

  return d.promise.nodeify(cb);
};

/**
 * Find one record, same as `all`, limited by 1 and return object, not collection
 *
 * @param {Object} params - search conditions: {where: {test: 'me'}}
 * @param {Function} [cb] Optional callback
 */
AbstractClass.findOne = function findOne(params, cb){
  var Model = this;

  if (typeof params === 'function') {
    cb = params;
    params = {};
  }

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    params = typeof params === 'object' ? params : {};
    params.limit = 1;

    Model.all(params).done(function (collection){
      if (!collection || collection.length === 0) {
        d.resolve(null);
      } else {
        d.resolve(collection[0]);
      }
    }, curry(d.reject, d));

    return d.promise;
  }).nodeify(cb);
};

/**
 * Destroy all records
 * @param {Function} [cb] Optional callback
 */
AbstractClass.destroyAll = function destroyAll(cb){
  var Model = this;

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    Model.schema.adapter.destroyAll(Model.modelName, function (err){
      if (err) {
        d.reject(err);
      } else {
        d.resolve();
      }
    });

    return d.promise;
  }).nodeify(cb);
};

/**
 * Delete some objects from persistence
 *
 * @triggers `destroy` hook (async) before and after destroying object
 * @param {Object|Function} query
 * @param {Function} [cb] Optional callback
 */
AbstractClass.destroySome = function destroySome(query, cb){
  var Model = this;

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    Model.all(query).then(function(ids){
      if (!ids || !ids.length) {
        throw new Error('No items found to destroy');
      }
      var all = [];
      ids.forEach(function(id){
        all.push(id.destroy());
      });
      utils.Q.all(all).done(function(count){
        d.resolve(count.length);
      });
    }).catch(function(err){
      d.reject(err);
    }).done();

    return d.promise;
  }).nodeify(cb);
};

/**
 * Return count of matched records
 *
 * @param {Object} query - search conditions (optional)
 * @param {Function} [cb] Optional callback
 */
AbstractClass.count = function count(query, cb){
  var Model = this;

  if (typeof query === 'function') {
    cb = query;
    query = null;
  }

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    if (typeof query === 'object'){
      if (typeof query.where !== 'function') {
        query = Model._forDB(query);
      }
    } else {
      query = null;
    }

    Model.schema.adapter.count(Model.modelName, d.callback, query);

    return d.promise;
  }).nodeify(cb);
};

/**
 * Return string representation of class
 *
 * @override default toString method
 */
AbstractClass.toString = function (){
  return '[Model ' + this.modelName + ']';
};

/**
 * Save instance. When instance haven't id, create method called instead.
 * Triggers: validate, save, update | create
 * @param {Object} [options] {validate: true}
 * @param {Function} [cb] Optional callback
 */
AbstractClass.prototype.save = function save(options, cb){
  var
    Model = this.constructor,
    inst = this;

  if (typeof options === 'function') {
    cb = options;
    options = {};
  }

  return stillConnecting(Model.schema).then(function(){
    options = typeof options === 'object' ? options : {};

    if (!('validate' in options)) {
      options.validate = true;
    }

    var data = inst.toObject(true);
    var modelName = Model.modelName;

    if (!inst.id) {
      // Pass options and this to create
      data = {
        data   : inst,
        options: options
      };

      return Model.create(data);
    }

    // then save
    var
      d = utils.defer(),
      reject = curry(d.reject, d),
      innerSave = function (){
        inst.trigger('save', function (saveDone){
          inst.trigger('update', function (updateDone){
            inst._adapter().save(modelName, inst.constructor._forDB(data), function (err){
              if (err) {
                d.reject(err);
              } else {
                inst._initProperties(data, false);
                updateDone.call(inst, function (){
                  saveDone.call(inst, function (){
                    d.resolve(inst);
                  });
                });
              }
            });
          }, data, reject);
        }, data, reject);
      };

    // validate first
    if (!options.validate) {
      innerSave();
    } else {
      inst.isValid(data).done(function (){
        innerSave();
      }, reject);
    }

    return d.promise;
  }).nodeify(cb);
};

AbstractClass.prototype.isNewRecord = function (){
  return !this.id;
};

/**
 * Return adapter of current record
 * @private
 */
AbstractClass.prototype._adapter = function (){
  return this.schema.adapter;
};

/**
 * Convert instance to Object
 *
 * @param {Boolean} onlySchema - restrict properties to schema only, default false
 * when onlySchema == true, only properties defined in schema returned,
 * otherwise all enumerable properties returned
 * @param {Boolean} cachedRelations
 * @returns {Object} - canonical object representation (no getters and setters)
 */
AbstractClass.prototype.toObject = function (onlySchema, cachedRelations){
  var data = {};
  var ds = this.constructor.schema.definitions[this.constructor.modelName];
  var properties = ds.properties;
  var self = this;

  this.constructor.forEachProperty(function (attr){
    if (self[attr] instanceof List) {
      data[attr] = self[attr].toObject();
    } else if (self.__data.hasOwnProperty(attr)) {
      data[attr] = self[attr];
    } else {
      data[attr] = null;
    }
  });

  if (!onlySchema) {
    Object.keys(self).forEach(function (attr){
      if (!data.hasOwnProperty(attr)) {
        data[attr] = self[attr];
      }
    });

    if (cachedRelations === true && this.__cachedRelations) {
      var relations = this.__cachedRelations;
      Object.keys(relations).forEach(function (attr){
        if (!data.hasOwnProperty(attr)) {
          data[attr] = relations[attr];
        }
      });
    }
  }

  return data;
};

// AbstractClass.prototype.hasOwnProperty = function (prop) {
//     return this.__data && this.__data.hasOwnProperty(prop) ||
//         Object.getOwnPropertyNames(this).indexOf(prop) !== -1;
// };

AbstractClass.prototype.toJSON = function (cachedRelations){
  return this.toObject(false, cachedRelations);
};

/**
 * Delete object from persistence
 *
 * @triggers `destroy` hook (async) before and after destroying object
 * @param {Function} [cb] Optional callback
 */
AbstractClass.prototype.destroy = function destroy(cb){
  var
    Model = this.constructor,
    inst = this;

  return stillConnecting(Model.schema).then(function(){
    var d = utils.defer();

    inst.trigger('destroy', function (destroyed){
      inst._adapter().destroy(Model.modelName, inst.id, function (err){
        if (err) {
          d.reject(err);
        } else {
          destroyed(curry(d.resolve, d));
        }
      });
    }, inst.toObject(), curry(d.reject, d));

    return d.promise;
  }).nodeify(cb);
};

/**
 * Update single attribute
 *
 * equals to `updateAttributes({name: value}, cb)
 *
 * @param {String} name - name of property
 * @param {*} value - value of property
 * @param {Function} [cb] Optional callback
 */
AbstractClass.prototype.updateAttribute = function updateAttribute(name, value, cb){
  var data = {};
  data[name] = value;
  return this.updateAttributes(data, cb);
};

/**
 * Update set of attributes
 *
 * this method performs validation before updating
 *
 * @trigger `validation`, `save` and `update` hooks
 * @param {Object} data - data to update
 * @param {Function} [cb] Optional callback
 */
AbstractClass.prototype.updateAttributes = function updateAttributes(data, cb){
  var
    Model = this.constructor,
    inst = this;

  return stillConnecting(Model.schema).then(function(){
    var
      modelName = Model.modelName,
      d = utils.defer(),
      reject = curry(d.reject, d);

    data = typeof data === 'object' ? data : {};

    // update instance's properties
    Object.keys(data).forEach(function (key){
      inst[key] = data[key];
    });

    inst.isValid(data).done(function(){
      inst.trigger('save', function (saveDone){
        inst.trigger('update', function (done){

          Object.keys(data).forEach(function (key){
            inst[key] = data[key];
          });

          inst._adapter().updateAttributes(modelName, inst.id, inst.constructor._forDB(inst.toObject(true)), function (err){
            if (!err) {
              // update _was attrs
              Object.keys(data).forEach(function (key){
                inst.__dataWas[key] = inst.__data[key];
              });
            }

            done.call(inst, function (){
              saveDone.call(inst, function (){
                if (err) {
                  d.reject(err);
                } else {
                  d.resolve(inst);
                }
              });
            });
          });
        }, data, reject);
      }, data, reject);
    }, reject);

    return d.promise;
  }).nodeify(cb);
};

AbstractClass.prototype.fromObject = function (obj){
  var inst = this;
  Object.keys(obj).forEach(function (key){
    inst[key] = obj[key];
  });
};

/**
 * Checks is property changed based on current property and initial value
 *
 * @param {String} attr - property name
 * @return Boolean
 */
AbstractClass.prototype.propertyChanged = function propertyChanged(attr){
  return this.__data[attr] !== this.__dataWas[attr];
};

/**
 * Reload object from persistence
 *
 * @requires id member of `object` to be able to call `find`
 * @param {Function} [cb] Optional callback
 */
AbstractClass.prototype.reload = function reload(cb){
  var
    Model = this.constructor,
    inst = this;

  return stillConnecting(Model.schema).then(function(){
    return Model.find(inst.id);
  }).nodeify(cb);
};

/**
 * Reset dirty attributes
 *
 * this method does not perform any database operation it just reset object to it's
 * initial state
 */
AbstractClass.prototype.reset = function (){
  var obj = this;

  Object.keys(obj).forEach(function (k){
    if (k !== 'id' && !obj.constructor.schema.definitions[obj.constructor.modelName].properties[k]) {
      delete obj[k];
    }
    if (obj.propertyChanged(k)) {
      obj[k] = obj[k + '_was'];
    }
  });
};

AbstractClass.prototype.inspect = function (){
  return util.inspect(this.__data, false, 4, true);
};

/**
 * Check whether `s` is not undefined
 * @param {*} s
 * @return {Boolean} s is undefined
 */
function isdef(s){
  var undef;
  return s !== undef;
}

},{"./hooks.js":8,"./include.js":9,"./list.js":10,"./relations.js":12,"./utils":15,"./validations.js":16,"util":6}],12:[function(_dereq_,module,exports){
'use strict';

/**
 * Dependencies
 */
var
  i8n = _dereq_('inflection'),
  utils = _dereq_('./utils'),
  defineScope = _dereq_('./scope.js').defineScope;

/**
 * Relations mixins for ./model.js
 */
var AbstractClass = _dereq_('./model.js');

AbstractClass.relationNameFor = function relationNameFor(foreignKey){
  for (var rel in this.relations) {
    if (this.relations[rel].type === 'belongsTo' && this.relations[rel].keyFrom === foreignKey) {
      return rel;
    }
  }
};

/**
 * Declare hasMany relation
 *
 * @param {Model} anotherClass - class to has many
 * @param {Object} params - configuration {as:, foreignKey:}
 * @example `User.hasMany(Post, {as: 'posts', foreignKey: 'authorId'});`
 */
AbstractClass.hasMany = function hasMany(anotherClass, params){
  var thisClass = this, thisClassName = this.modelName;
  params = params || {};
  if (typeof anotherClass === 'string') {
    params.as = anotherClass;
    if (params.model) {
      anotherClass = params.model;
    } else {
      var anotherClassName = i8n.singularize(anotherClass).toLowerCase();
      for (var name in this.schema.models) {
        if (name.toLowerCase() === anotherClassName) {
          anotherClass = this.schema.models[name];
        }
      }
    }
  }
  var methodName = params.as ||
    i8n.camelize(i8n.pluralize(anotherClass.modelName), true);
  var fk = params.foreignKey || i8n.camelize(thisClassName + '_id', true);

  this.relations[methodName] = {
    type    : 'hasMany',
    keyFrom : 'id',
    keyTo   : fk,
    modelTo : anotherClass,
    multiple: true
  };
  // each instance of this class should have method named
  // pluralize(anotherClass.modelName)
  // which is actually just anotherClass.all({where: {thisModelNameId: this.id}}, cb);
  var scopeMethods = {
    find   : find,
    destroy: destroy
  };

  if (params.through) {
    var fk2 = i8n.camelize(anotherClass.modelName + '_id', true);

    scopeMethods.create = function hasManyCreate(data, done){
      if (typeof data === 'function') {
        done = data;
        data = {};
      }

      var
        self = this,
        id = this.id;

      return anotherClass.create(data).then(function (ac){
        var d = {};
        d[params.through.relationNameFor(fk)] = self;
        d[params.through.relationNameFor(fk2)] = ac;

        return params.through.create(d)
        .catch(function(){
          return ac.destroy();
        }).then(function(){
          return ac;
        });
      }).nodeify(done);
    };

    scopeMethods.add = function hasManyAdd(acInst, data, done){
      if (typeof data === 'function') {
        done = data;
        data = {};
      }

      data = data || {};

      var query = {};
      query[fk] = this.id;
      data[params.through.relationNameFor(fk)] = this;
      query[fk2] = acInst.id || acInst;
      data[params.through.relationNameFor(fk2)] = acInst;

      return params.through
        .findOrCreate({where: query}, data)
        .nodeify(done);
    };

    scopeMethods.remove = function hasManyRemove(acInst, done){
      var q = {};
      q[fk] = this.id;
      q[fk2] = acInst.id || acInst;

      return params.through.findOne({where: q}).then(function (d){
        return d.destroy();
      }).nodeify(done);
    };

    delete scopeMethods.destroy;
  }

  defineScope(this.prototype, params.through || anotherClass, methodName, function hasManyScope(){
    var filter = {};
    filter.where = {};
    filter.where[fk] = this.id;
    if (params.through) {
      filter.collect = i8n.camelize(anotherClass.modelName, true);
      filter.include = filter.collect;
    }
    return filter;
  }, scopeMethods);

  if (!params.through) {
    // obviously, anotherClass should have attribute called `fk`
    anotherClass.schema.defineForeignKey(anotherClass.modelName, fk, this.modelName);
  }

  function find(id, cb){
    /*jshint validthis:true */
    var self = this;

    return anotherClass.find(id).then(function (inst){
      if (!inst) {
        throw new Error('Not found');
      }
      if (inst[fk] && inst[fk].toString() === self.id.toString()) {
        return inst;
      } else {
        throw new Error('Permission denied');
      }
    }).nodeify(cb);
  }

  function destroy(id, cb){
    /*jshint validthis:true */
    var self = this;

    return anotherClass.find(id).then(function (inst){
      if (!inst) {
        throw new Error('Not found');
      }
      if (inst[fk] && inst[fk].toString() === self.id.toString()) {
        return inst.destroy();
      } else {
        throw new Error('Permission denied');
      }
    }).nodeify(cb);
  }

};

/**
 * Declare belongsTo relation
 *
 * @param {Class} anotherClass - class to belong
 * @param {Object} params - configuration {as: 'propertyName', foreignKey: 'keyName'}
 *
 * **Usage examples**
 * Suppose model Post have a *belongsTo* relationship with User (the author of the post). You could declare it this way:
 * Post.belongsTo(User, {as: 'author', foreignKey: 'userId'});
 *
 * When a post is loaded, you can load the related author with:
 * post.author().then(function(author) {
 *     // the user variable is your user object
 * });
 *
 * The related object is cached, so if later you try to get again the author, no additional request will be made.
 * But there is an optional boolean parameter in first position that set whether or not you want to reload the cache:
 * post.author(true).then(function(author) {
 *     // The user is reloaded, even if it was already cached.
 * });
 *
 * This optional parameter default value is false, so the related object will be loaded from cache if available.
 */
AbstractClass.belongsTo = function (anotherClass, params){
  var Model = this;
  params = params || {};
  if ('string' === typeof anotherClass) {
    params.as = anotherClass;
    if (params.model) {
      anotherClass = params.model;
    } else {
      var anotherClassName = anotherClass.toLowerCase();
      for (var name in this.schema.models) {
        if (name.toLowerCase() === anotherClassName) {
          anotherClass = this.schema.models[name];
        }
      }
    }
  }
  var methodName = params.as || i8n.camelize(anotherClass.modelName, true);
  var fk = params.foreignKey || methodName + 'Id';

  this.relations[methodName] = {
    type    : 'belongsTo',
    keyFrom : fk,
    keyTo   : 'id',
    modelTo : anotherClass,
    multiple: false
  };

  this.schema.defineForeignKey(this.modelName, fk, anotherClass.modelName);
  this.prototype['__finders__'] = this.prototype['__finders__'] || {};

  this.prototype['__finders__'][methodName] = function belongsToFinder(id, cb){
    if (id === null || id === undefined) {
      return utils.Q.resolve(null).nodeify(cb);
    }

    var
      inst = this;

    return anotherClass.find(id).then(function(_inst){
      if (!_inst) {
        return null;
      } else if (_inst.id.toString() === inst[fk].toString()) {
        return _inst;
      } else {
        throw new Error('Permission denied');
      }
    }).nodeify(cb);
  };

  this.prototype[methodName] = function belongsToPrototype(refresh, p){
    if (arguments.length === 1) {
      p = refresh;
      refresh = false;
    } else if (arguments.length > 2) {
      throw new Error('Method can\'t be called with more than two arguments');
    }

    var
      self = this,
      d = utils.defer(),
      cachedValue;

    if (!refresh && this.__cachedRelations && (typeof this.__cachedRelations[methodName] !== 'undefined')) {
      cachedValue = this.__cachedRelations[methodName];
    }

    if (p instanceof Model) { // acts as setter
      this[fk] = p.id;
      this.__cachedRelations[methodName] = p;
      d.resolve(this);
    } else if (typeof p !== 'undefined' && typeof p !== 'function') { // setter
      this[fk] = p;
      delete this.__cachedRelations[methodName];
      d.resolve(this);
    } else {
      // async getter
      if (typeof cachedValue === 'undefined') {
        this.__finders__[methodName].call(self, this[fk]).done(function (inst){
          self.__cachedRelations[methodName] = inst;
          d.resolve(inst);
        }, function(err){
          d.reject(err);
        });
      } else {
        d.resolve(cachedValue);
      }
    }

    if (typeof p === 'function') {
      d.promise.nodeify(p);
    }

    return d.promise;
  };

};

/**
 * Many-to-many relation
 *
 * Post.hasAndBelongsToMany('tags'); creates connection model 'PostTag'
 */
AbstractClass.hasAndBelongsToMany = function hasAndBelongsToMany(anotherClass, params){
  params = params || {};
  var models = this.schema.models;

  if ('string' === typeof anotherClass) {
    params.as = anotherClass;
    if (params.model) {
      anotherClass = params.model;
    } else {
      anotherClass = lookupModel(i8n.singularize(anotherClass)) ||
        anotherClass;
    }
    if (typeof anotherClass === 'string') {
      throw new Error('Could not find "' + anotherClass + '" relation for ' + this.modelName);
    }
  }

  if (!params.through) {
    var name1 = this.modelName + anotherClass.modelName;
    var name2 = anotherClass.modelName + this.modelName;
    params.through = lookupModel(name1) || lookupModel(name2) ||
      this.schema.define(name1);
  }
  params.through.belongsTo(this);
  params.through.belongsTo(anotherClass);

  this.hasMany(anotherClass, {as: params.as, through: params.through});

  function lookupModel(modelName){
    var lookupClassName = modelName.toLowerCase();
    for (var name in models) {
      if (name.toLowerCase() === lookupClassName) {
        return models[name];
      }
    }
    return null;
  }

};

},{"./model.js":11,"./scope.js":14,"./utils":15,"inflection":false}],13:[function(_dereq_,module,exports){
(function (__dirname){
'use strict';

/**
 * Module dependencies
 */
var
  AbstractClass = _dereq_('./model.js'),
  List = _dereq_('./list.js'),
  EventEmitter = _dereq_('events').EventEmitter,
  util = _dereq_('util'),
  utils = _dereq_('./utils'),
  path = _dereq_('path'),
  fs = _dereq_('fs'),
  curry = utils.curry,
  existsSync = fs.existsSync || path.existsSync;

/**
 * Export public API
 */
exports.Schema = Schema;
// exports.AbstractClass = AbstractClass;

Schema.Text = function Text(s){ return s; };
Schema.JSON = function JSON(){};

Schema.types = {};
Schema.registerType = function (type, name){
  this.types[name || type.name] = type;
};

Schema.registerType(Schema.Text, 'Text');
Schema.registerType(Schema.JSON, 'JSON');

/**
 * Schema - adapter-specific classes factory.
 *
 * All classes in single schema shares same adapter type and
 * one database connection
 *
 * @param name - type of schema adapter (mysql, mongoose, sequelize, redis)
 * @param settings - any database-specific settings which we need to
 * establish connection (of course it depends on specific adapter)
 *
 * - host
 * - port
 * - username
 * - password
 * - database
 * - debug {Boolean} = false
 *
 * @example Schema creation, waiting for connection callback
 * ```
 * var schema = new Schema('mysql', { database: 'myapp_test' });
 * schema.define(...);
 * schema.on('connected', function () {
 *     // work with database
 * });
 * ```
 */
function Schema(name, settings){
  var schema = this;

  // just save everything we get
  schema.name = name;
  schema.settings = settings || {};

  // Disconnected by default
  schema.connected = false;
  schema.connecting = false;

  // create blank models pool
  schema.models = {};
  schema.definitions = {};

  if (this.settings.log) {
    /*istanbul ignore next:untestable */
    schema.on('log', function (str, duration){
      console.log(str);
    });
  }

  // and initialize schema using adapter
  // this is only one initialization entry point of adapter
  // this module should define `adapter` member of `this` (schema)
  var adapter;
  if (typeof name === 'object') {
    adapter = name;
    this.name = adapter.name;
  } else if (name.match(/^\//)) {
    // try absolute path
    adapter = _dereq_(name);
  } else if (existsSync(__dirname + '/adapters/' + name + '.js')) {
    // try built-in adapter
    adapter = _dereq_('./adapters/' + name);
  } else {
    // try foreign adapter
    try {
      adapter = _dereq_('jugglingdb-' + name);
    } catch (e) {
      throw new Error('\nWARNING: JugglingDB adapter "' + name + '" is not installed,\nso your models cannot work, to fix run:\n\n    npm install jugglingdb-' + name, '\n');
    }
  }

  schema.connecting = true;
  adapter.initialize(schema, function (){

    schema.adapter.log = function (query, start){
      schema.log(query, start);
    };

    schema.adapter.logger = function (query){
      var t1 = Date.now();
      return function (q){
        schema.log(q || query, t1);
      };
    };

    schema.connecting = false;
    schema.connected = true;
    schema.emit('connected');
  });

  // we have an adaper now?
  if (!schema.adapter) {
    throw new Error('Adapter "' + name + '" is not defined correctly: it should define `adapter` member of schema synchronously');
  }

  schema.connect = function (cb){
    var d = utils.defer(), self = this;

    self.connecting = true;

    if (typeof self.adapter.connect === 'function') {
      self.adapter.connect(function (err){
        if (!err) {
          self.connected = true;
          self.connecting = false;
          self.emit('connected');
          d.resolve();
        } else {
          d.reject(err);
        }
      });
    } else {
      d.resolve();
    }

    return d.promise.nodeify(cb);
  };
}

util.inherits(Schema, EventEmitter);

/**
 * Define class
 *
 * @param {String} className
 * @param {Object} properties - hash of class properties in format
 *   `{property: Type, property2: Type2, ...}`
 *   or
 *   `{property: {type: Type}, property2: {type: Type2}, ...}`
 * @param {Object} settings - other configuration of class
 * @return {Object|Function} newly created class
 *
 * @example simple case
 * ```
 * var User = schema.define('User', {
 *     email: String,
 *     password: String,
 *     birthDate: Date,
 *     activated: Boolean
 * });
 * ```
 * @example more advanced case
 * ```
 * var User = schema.define('User', {
 *     email: { type: String, limit: 150, index: true },
 *     password: { type: String, limit: 50 },
 *     birthDate: Date,
 *     registrationDate: {type: Date, default: function () { return new Date }},
 *     activated: { type: Boolean, default: false }
 * });
 * ```
 */
Schema.prototype.define = function defineClass(className, properties, settings){
  var schema = this;
  var args = utils.slice.call(arguments);

  if (!className) {
    throw new Error('Class name required');
  }
  if (args.length === 1) {
    properties = {};
    args.push(properties);
  }
  if (args.length === 2) {
    settings = {};
    args.push(settings);
  }

  settings = settings || {};

  if ('function' === typeof properties) {
    var props = {};
    properties({
      property: function (name, type, settings){
        settings = settings || {};
        settings.type = type;
        props[name] = settings;
      },
      set     : function (key, val){
        settings[key] = val;
      }
    });
    properties = props;
  }

  properties = properties || {};

  // every class can receive hash of data as optional param
  var NewClass = function ModelConstructor(data, schema){
    if (!(this instanceof ModelConstructor)) {
      return new ModelConstructor(data, schema);
    }
    AbstractClass.call(this, data);
    utils.hiddenProperty(this, 'schema', schema || this.constructor.schema);
  };

  utils.hiddenProperty(NewClass, 'schema', schema);
  utils.hiddenProperty(NewClass, 'settings', settings);
  utils.hiddenProperty(NewClass, 'properties', properties);
  utils.hiddenProperty(NewClass, 'modelName', className);
  utils.hiddenProperty(NewClass, 'tableName', settings.table || className);
  utils.hiddenProperty(NewClass, 'relations', {});

  // inherit AbstractClass methods
  for (var i in AbstractClass) {
    NewClass[i] = AbstractClass[i];
  }
  for (var j in AbstractClass.prototype) {
    NewClass.prototype[j] = AbstractClass.prototype[j];
  }

  NewClass.getter = {};
  NewClass.setter = {};

  standartize(properties, settings);

  // store class in model pool
  this.models[className] = NewClass;
  this.definitions[className] = {
    properties: properties,
    settings  : settings
  };

  // pass control to adapter
  this.adapter.define({
    model     : NewClass,
    properties: properties,
    settings  : settings
  });

  NewClass.prototype.__defineGetter__('id', function (){
    return this.__data.id;
  });

  properties.id = properties.id || { type: schema.settings.slave ? String : Number };

  NewClass.forEachProperty = function (cb){
    Object.keys(properties).forEach(cb);
  };

  NewClass.registerProperty = function (attr){
    var DataType = properties[attr].type;
    if (DataType instanceof Array) {
      DataType = List;
    } else if (DataType.name === 'Date') {
      var OrigDate = Date;
      DataType = function Date(arg){
        return new OrigDate(arg);
      };
    } else if (DataType.name === 'JSON' || DataType === Schema.JSON) {
      DataType = function JSON(s){
        return s;
      };
    } else if (DataType.name === 'Text' || DataType === Schema.Text) {
      DataType = function Text(s){
        return s;
      };
    }

    Object.defineProperty(NewClass.prototype, attr, {
      get         : function (){
        if (NewClass.getter[attr]) {
          return NewClass.getter[attr].call(this);
        } else {
          return this.__data[attr];
        }
      },
      set         : function (value){
        if (NewClass.setter[attr]) {
          NewClass.setter[attr].call(this, value);
        } else {
          if (value === null || value === undefined || typeof DataType === 'object') {
            this.__data[attr] = value;
          } else if (DataType === Boolean) {
            this.__data[attr] = value === 'false' ? false : !!value;
          } else {
            this.__data[attr] = DataType(value);
          }
        }
      },
      configurable: true,
      enumerable  : true
    });

    NewClass.prototype.__defineGetter__(attr + '_was', function (){
      return this.__dataWas[attr];
    });

    Object.defineProperty(NewClass.prototype, '_' + attr, {
      get         : function (){
        return this.__data[attr];
      },
      set         : function (value){
        this.__data[attr] = value;
      },
      configurable: true,
      enumerable  : false
    });
  };

  NewClass.forEachProperty(NewClass.registerProperty);

  this.emit('define', NewClass, className, properties, settings);

  return NewClass;
};

function standartize(properties, settings){
  Object.keys(properties).forEach(function (key){
    var v = properties[key];
    if (
      typeof v === 'function' ||
        typeof v === 'object' && v && v.constructor.name === 'Array'
      ) {
      properties[key] = { type: v };
    }
  });
  // TODO: add timestamps fields
  // when present in settings: {timestamps: true}
  // or {timestamps: {created: 'created_at', updated: false}}
  // by default property names: createdAt, updatedAt
}

/**
 * Define single property named `prop` on `model`
 *
 * @param {String} model - name of model
 * @param {String} prop - name of propery
 * @param {Object} params - property settings
 */
Schema.prototype.defineProperty = function (model, prop, params){
  this.definitions[model].properties[prop] = params;
  this.models[model].registerProperty(prop);

  if (typeof this.adapter.defineProperty === 'function') {
    this.adapter.defineProperty(model, prop, params);
  }
};

/**
 * Extend existing model with bunch of properties
 *
 * @param {String} model - name of model
 * @param {Object} props - hash of properties
 *
 * Example:
 *
 *     // Instead of doing this:
 *
 *     // amend the content model with competition attributes
 *     db.defineProperty('Content', 'competitionType', { type: String });
 *     db.defineProperty('Content', 'expiryDate', { type: Date, index: true });
 *     db.defineProperty('Content', 'isExpired', { type: Boolean, index: true });
 *
 *     // schema.extend allows to
 *     // extend the content model with competition attributes
 *     db.extendModel('Content', {
 *       competitionType: String,
 *       expiryDate: { type: Date, index: true },
 *       isExpired: { type: Boolean, index: true }
 *     });
 */
Schema.prototype.extendModel = function (model, props){
  var t = this;
  standartize(props, {});
  Object.keys(props).forEach(function (propName){
    var definition = props[propName];
    t.defineProperty(model, propName, definition);
  });
};

function executeInAdapter(context, name, deferred) {

  if (typeof context.adapter[name] === 'function') {
    if (context.adapter[name].length === 1) {
      context.adapter[name](deferred.callback);
    } else {
      context.adapter[name]();
      deferred.resolve();
    }
    return true;
  } else {
    deferred.resolve();
  }

  return false;
}

/**
 * Drop each model table and re-create.
 * This method make sense only for sql adapters.
 *
 * @warning All data will be lost! Use autoupdate if you need your data.
 *
 * @param {Function} [cb] Optional callback
 * @returns {PromiseResolver.promise}
 */
Schema.prototype.automigrate = function (cb){
  var d = utils.defer();

  this.freeze();
  executeInAdapter(this, 'automigrate', d);

  return d.promise.nodeify(cb);
};

/**
 * Update existing database tables.
 * This method make sense only for sql adapters.
 *
 * @param {Function} [cb] Optional callback
 * @returns {PromiseResolver.promise}
 */
Schema.prototype.autoupdate = function (cb){
  var d = utils.defer();

  this.freeze();
  executeInAdapter(this, 'autoupdate', d);

  return d.promise.nodeify(cb);
};

/**
 * Check whether migrations needed
 * This method make sense only for sql adapters.
 *
 * @param {Function} [cb] Optional callback
 * @returns {PromiseResolver.promise}
 */
Schema.prototype.isActual = function (cb){
  var d = utils.defer();

  this.freeze();
  executeInAdapter(this, 'isActual', d);

  return d.promise.nodeify(cb);
};

/**
 * Log benchmarked message. Do not redefine this method, if you need to grab
 * schema logs, use `schema.on('log', ...)` emitter event
 *
 * @private used by adapters
 */
Schema.prototype.log = function (sql, t){
  this.emit('log', sql, t);
};

/**
 * Freeze schema. Behavior depends on adapter
 */
Schema.prototype.freeze = function freeze(){
  if (typeof this.adapter.freezeSchema === 'function') {
    this.adapter.freezeSchema();
  }
};

/**
 * Backward compatibility. Use model.tableName prop instead.
 * Return table name for specified `modelName`
 * @param {String} modelName
 */
Schema.prototype.tableName = function (modelName){
  return this.models[modelName].model.tableName;
};

/**
 * Define foreign key
 * @param {String} className
 * @param {String} key - name of key field
 * @param {String} foreignClassName
 */
Schema.prototype.defineForeignKey = function defineForeignKey(className, key, foreignClassName){
  // quit if key already defined
  if (this.definitions[className].properties[key]) {
    return;
  }

  if (typeof this.adapter.defineForeignKey === 'function') {

    var cb = curry(function (err, keyType){
      if (err) {
        throw err;
      }
      this.definitions[className].properties[key] = {type: keyType};
    }, this);

    switch (this.adapter.defineForeignKey.length) {
      case 4:
        this.adapter.defineForeignKey(className, key, foreignClassName, cb);
        break;
      default:
      case 3:
        this.adapter.defineForeignKey(className, key, cb);
        break;
    }
  } else {
    this.definitions[className].properties[key] = {type: Number};
  }
  this.models[className].registerProperty(key);
};

/**
 * Close database connection
 *
 * @param {Function} [cb] Optional callback
 * @returns {PromiseResolver.promise}
 */
Schema.prototype.disconnect = function disconnect(cb){
  var d = utils.defer();

  if (executeInAdapter(this, 'disconnect', d)) {
    this.connected = false;
  }

  return d.promise.nodeify(cb);
};

Schema.prototype.copyModel = function copyModel(Master){
  var schema = this;
  var className = Master.modelName;
  var md = Master.schema.definitions[className];
  var Slave = function SlaveModel(){
    Master.apply(this, utils.slice.call(arguments));
    this.schema = schema;
  };

  util.inherits(Slave, Master);

  Slave.__proto__ = Master;

  utils.hiddenProperty(Slave, 'schema', schema);
  utils.hiddenProperty(Slave, 'modelName', className);
  utils.hiddenProperty(Slave, 'tableName', Master.tableName);
  utils.hiddenProperty(Slave, 'relations', Master.relations);

  if (!(className in schema.models)) {

    // store class in model pool
    schema.models[className] = Slave;
    schema.definitions[className] = {
      properties: md.properties,
      settings  : md.settings
    };

    if (!schema.isTransaction) {
      schema.adapter.define({
        model     : Slave,
        properties: md.properties,
        settings  : md.settings
      });
    }

  }

  return Slave;
};

Schema.prototype.transaction = function (){
  var schema = this;
  var transaction = new EventEmitter();
  transaction.isTransaction = true;
  transaction.origin = schema;
  transaction.name = schema.name;
  transaction.settings = schema.settings;
  transaction.connected = false;
  transaction.connecting = false;
  transaction.adapter = schema.adapter.transaction();

  // create blank models pool
  transaction.models = {};
  transaction.definitions = {};

  for (var i in schema.models) {
    schema.copyModel.call(transaction, schema.models[i]);
  }

  transaction.connect = schema.connect;

  transaction.exec = function (cb){
    var d = utils.defer();

    transaction.adapter.exec(d.callback);

    return d.promise.nodeify(cb);
  };

  return transaction;
};
}).call(this,"/lib")
},{"./list.js":10,"./model.js":11,"./utils":15,"events":2,"fs":1,"path":false,"util":6}],14:[function(_dereq_,module,exports){
'use strict';

/**
 * Module exports
 */
exports.defineScope = defineScope;

/**
 * Scope mixin for ./model.js
 */
var
  Model = _dereq_('./model.js'),
  utils = _dereq_('./utils'),
  curry = utils.curry;

/**
 * Define scope
 * TODO: describe behavior and usage examples
 */
Model.scope = function (name, params){
  defineScope(this, this, name, params);
};

function defineScope(cls, targetClass, name, params, methods){

  // collect meta info about scope
  if (!cls._scopeMeta) {
    cls._scopeMeta = {};
  }

  // only makes sence to add scope in meta if base and target classes
  // are same
  if (cls === targetClass) {
    cls._scopeMeta[name] = params;
  } else {
    if (!targetClass._scopeMeta) {
      targetClass._scopeMeta = {};
    }
  }

  Object.defineProperty(cls, name, {
    enumerable  : false,
    configurable: true,
    get         : function (){
      var f = function caller(condOrRefresh, cb){
        var
          actualCond = {},
          actualRefresh = false,
          d = utils.defer(),
          saveOnCache = true;

        if (arguments.length === 1) {
          if (typeof condOrRefresh === 'function') {
            cb = condOrRefresh;
          } else if (typeof condOrRefresh === 'boolean') {
            actualRefresh = condOrRefresh;
          } else {
            actualCond = condOrRefresh;
            actualRefresh = true;
            saveOnCache = false;
          }
        } else if (arguments.length === 2) {
          if (typeof condOrRefresh === 'boolean') {
            actualRefresh = condOrRefresh;
          } else {
            actualCond = condOrRefresh;
            actualRefresh = true;
            saveOnCache = false;
          }
        } else if (arguments.length > 2) {
          throw new Error('Method can be only called with zero, one or two arguments');
        }

        if (!this.__cachedRelations || (typeof this.__cachedRelations[name] == 'undefined') || actualRefresh) {
          var self = this;
          var params = mergeParams(actualCond, caller._scope);

          targetClass.all(params).done(function (data){
            if (saveOnCache) {
              if (!self.__cachedRelations) {
                self.__cachedRelations = {};
              }
              self.__cachedRelations[name] = data;
            }

            d.resolve(data);
          }, curry(d.reject, d));
        } else {
          d.resolve(this.__cachedRelations[name]);
        }

        return d.promise.nodeify(cb);
      };
      f._scope = typeof params === 'function' ? params.call(this) : params;
      f.build = build;
      f.create = create;
      f.destroyAll = destroyAll;
      for (var i in methods) {
        f[i] = curry(methods[i], this);
      }

      // define sub-scopes
      Object.keys(targetClass._scopeMeta).forEach(function (name){
        Object.defineProperty(f, name, {
          enumerable: false,
          get       : function (){
            mergeParams(f._scope, targetClass._scopeMeta[name]);
            return f;
          }
        });
      });
      return f;
    }
  });

  // and it should have create/build methods with binded thisModelNameId param
  function build(data){
    /*jshint validthis:true */
    return new targetClass(mergeParams(this._scope, {where: data || {}}).where);
  }

  function create(data, cb){
   /*jshint validthis:true */
    return this.build(data).save().nodeify(cb);
  }

  /*
   Callback
   - The callback will be called after all elements are destroyed
   - For every destroy call which results in an error
   - If fetching the Elements on which destroyAll is called results in an error
   */
  function destroyAll(cb){
    /*jshint validthis:true */
    var inst = this;

    return targetClass.all(inst._scope).then(function (data){
      var
        d = utils.defer(),
        reject = curry(d.reject, d);

      (function loopOfDestruction(data){
        if (data.length > 0) {
          data.shift().destroy().done(function (){
            loopOfDestruction(data);
          }, reject);
        } else {
          d.resolve(inst);
        }
      })(data);

      return d.promise;
    }).nodeify(cb);
  }

  function mergeParams(base, update){
    if (update.where) {
      base.where = merge(base.where, update.where);
    }
    if (update.include) {
      base.include = update.include;
    }
    if (update.collect) {
      base.collect = update.collect;
    }

    // overwrite order
    if (update.order) {
      base.order = update.order;
    }

    return base;

  }
}

/**
 * Merge `base` and `update` params
 * @param {Object} base - base object (updating this object)
 * @param {Object} update - object with new data to update base
 * @returns {Object} `base`
 */
function merge(base, update){
  base = base || {};
  if (update) {
    Object.keys(update).forEach(function (key){
      base[key] = update[key];
    });
  }
  return base;
}


},{"./model.js":11,"./utils":15}],15:[function(_dereq_,module,exports){
(function (process){
'use strict';

var Q = _dereq_('bluebird');

var slice = exports.slice = Array.prototype.slice;

/**
 * Require a jugglingdb adapter
 * @param {String} module
 * @returns {*}
 */
exports.safeRequire = function (module){
  try {
    return _dereq_(module);
  } catch (e) {
    console.log('Run "npm install jugglingdb ' + module + '" command to use jugglingdb using ' + module + ' database engine');
    process.exit(1);
    return false;
  }
};

/**
 * Bind the context of a function
 *
 * @param {Function} fn
 * @param {Object} that
 * @returns {Function}
 */
exports.curry = function (fn, that) {
  return function () {
    return fn.apply(that, slice.call(arguments));
  };
};
/**
 * Bind the context of a function with predefined args
 *
 * @param {Function} fn
 * @param {Object} that
 * @returns {Function}
 */
exports.curryArgs = function (fn, that) {
  var args = slice.call(arguments, 2);

  return function () {
    return fn.apply(that, args.concat(slice.call(arguments)));
  };
};

/**
 * @type {Promise}
 */
exports.Q = Q;
/**
 * @returns {Promise.defer}
 */
exports.defer = function(){
  return Q.defer();
};

/**
 * Define readonly property on object
 *
 * @param {Object} obj
 * @param {String} key
 * @param {*} value
 */
exports.defineReadonlyProp = function (obj, key, value){
  Object.defineProperty(obj, key, {
    writable    : false,
    enumerable  : true,
    configurable: false,
    value       : value
  });
};

/**
 * Define hidden property, but overwritable
 *
 * @param {Object} where
 * @param {String} property
 * @param {*} value
 */
exports.hiddenProperty = function (where, property, value){
  Object.defineProperty(where, property, {
    writable    : true,
    enumerable  : false,
    configurable: true,
    value       : value
  });
};



}).call(this,_dereq_("/home/cha0s6983/dev/code/js/reddichat/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/cha0s6983/dev/code/js/reddichat/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":4,"bluebird":false}],16:[function(_dereq_,module,exports){
'use strict';

var
  utils = _dereq_('./utils'),
  curry = utils.curry
  ;

/**
 * Module exports
 */
exports.ValidationError = ValidationError;

/**
 * Validation mixins for model.js
 *
 * Basically validation configurators is just class methods, which adds validations
 * configs to AbstractClass._validations. Each of this validations run when
 * `obj.isValid()` method called.
 *
 * Each configurator can accept n params (n-1 field names and one config). Config
 * is {Object} depends on specific validation, but all of them has one common part:
 * `message` member. It can be just string, when only one situation possible,
 * e.g. `Post.validatesPresenceOf('title', { message: 'can not be blank' });`
 *
 * In more complicated cases it can be {Hash} of messages (for each case):
 * `User.validatesLengthOf('password', { min: 6, max: 20, message: {min: 'too short', max: 'too long'}});`
 */
var Validatable = _dereq_('./model.js');

/**
 * Validate presence. This validation fails when validated field is blank.
 *
 * Default error message "can't be blank"
 *
 * @example presence of title
 * ```
 * Post.validatesPresenceOf('title');
 * ```
 * @example with custom message
 * ```
 * Post.validatesPresenceOf('title', {message: 'Can not be blank'});
 * ```
 *
 * @sync
 *
 * @nocode
 * @see helper/validatePresence
 */
Validatable.validatesPresenceOf = getConfigurator('presence');

/**
 * Validate length. Three kinds of validations: min, max, is.
 *
 * Default error messages:
 *
 * - min: too short
 * - max: too long
 * - is:  length is wrong
 *
 * @example length validations
 * ```
 * User.validatesLengthOf('password', {min: 7});
 * User.validatesLengthOf('email', {max: 100});
 * User.validatesLengthOf('state', {is: 2});
 * User.validatesLengthOf('nick', {min: 3, max: 15});
 * ```
 * @example length validations with custom error messages
 * ```
 * User.validatesLengthOf('password', {min: 7, message: {min: 'too weak'}});
 * User.validatesLengthOf('state', {is: 2, message: {is: 'is not valid state name'}});
 * ```
 *
 * @sync
 * @nocode
 * @see helper/validateLength
 */
Validatable.validatesLengthOf = getConfigurator('length');

/**
 * Validate numericality.
 *
 * @example
 * ```
 * User.validatesNumericalityOf('age', { message: { number: '...' }});
 * User.validatesNumericalityOf('age', {int: true, message: { int: '...' }});
 * ```
 *
 * Default error messages:
 *
 * - number: is not a number
 * - int: is not an integer
 *
 * @sync
 * @nocode
 * @see helper/validateNumericality
 */
Validatable.validatesNumericalityOf = getConfigurator('numericality');

/**
 * Validate inclusion in set
 *
 * @example
 * ```
 * User.validatesInclusionOf('gender', {in: ['male', 'female']});
 * User.validatesInclusionOf('role', {
 *     in: ['admin', 'moderator', 'user'], message: 'is not allowed'
 * });
 * ```
 *
 * Default error message: is not included in the list
 *
 * @sync
 * @nocode
 * @see helper/validateInclusion
 */
Validatable.validatesInclusionOf = getConfigurator('inclusion');

/**
 * Validate exclusion
 *
 * @example `Company.validatesExclusionOf('domain', {in: ['www', 'admin']});`
 *
 * Default error message: is reserved
 *
 * @nocode
 * @see helper/validateExclusion
 */
Validatable.validatesExclusionOf = getConfigurator('exclusion');

/**
 * Validate format
 *
 * Default error message: is invalid
 *
 * @nocode
 * @see helper/validateFormat
 */
Validatable.validatesFormatOf = getConfigurator('format');

/**
 * Validate using custom validator
 *
 * Default error message: is invalid
 *
 * Example:
 *
 *     User.validate('name', customValidator, {message: 'Bad name'});
 *     function customValidator(err) {
 *         if (this.name === 'bad') err();
 *     });
 *     var user = new User({name: 'Peter'});
 *     user.isValid(); // true
 *     user.name = 'bad';
 *     user.isValid(); // false
 *
 * @nocode
 * @see helper/validateCustom
 */
Validatable.validate = getConfigurator('custom');

/**
 * Validate using custom async validator
 *
 * Default error message: is invalid
 *
 * Example:
 *
 *     User.validateAsync('name', customValidator, {message: 'Bad name'});
 *     function customValidator(err, done) {
 *         process.nextTick(function () {
 *             if (this.name === 'bad') err();
 *             done();
 *         });
 *     });
 *     var user = new User({name: 'Peter'});
 *     user.isValid(); // false (because async validation setup)
 *     user.isValid(function (isValid) {
 *         isValid; // true
 *     })
 *     user.name = 'bad';
 *     user.isValid(); // false
 *     user.isValid(function (isValid) {
 *         isValid; // false
 *     })
 *
 * @async
 * @nocode
 * @see helper/validateCustom
 */
Validatable.validateAsync = getConfigurator('custom', {async: true});

/**
 * Validate uniqueness
 *
 * Default error message: is not unique
 *
 * @async
 * @nocode
 * @see helper/validateUniqueness
 */
Validatable.validatesUniquenessOf = getConfigurator('uniqueness', {async: true});

// implementation of validators

/**
 * Presence validator
 */
function validatePresence(attr, conf, err, done){
  /*jshint validthis:true */
  if (blank(this[attr])) {
    err();
  }
  done();
}

/**
 * Length validator
 */
function validateLength(attr, conf, err, done){
  /*jshint validthis:true */
  if (nullCheck.call(this, attr, conf, err)) {
    done();
    return;
  }

  var len = this[attr].length;
  if (conf.min && len < conf.min) {
    err('min');
  }
  if (conf.max && len > conf.max) {
    err('max');
  }
  if (conf.is && len !== conf.is) {
    err('is');
  }
  done();
}

/**
 * Numericality validator
 */
function validateNumericality(attr, conf, err, done){
  /*jshint validthis:true */
  if (nullCheck.call(this, attr, conf, err)) {
    done();
    return;
  }

  if (typeof this[attr] !== 'number') {
    err('number');
  } else if (conf.int && this[attr] !== Math.round(this[attr])) {
    err('int');
  }
  done();
}

/**
 * Inclusion validator
 */
function validateInclusion(attr, conf, err, done){
  /*jshint validthis:true */
  if (nullCheck.call(this, attr, conf, err)) {
    done();
    return;
  }

  if (conf.in.indexOf(this[attr]) === -1) {
    err();
  }
  done();
}

/**
 * Exclusion validator
 */
function validateExclusion(attr, conf, err, done){
  /*jshint validthis:true */
  if (nullCheck.call(this, attr, conf, err)) {
    done();
    return;
  }

  if (conf.in.indexOf(this[attr]) > -1) {
    err();
  }
  done();
}

/**
 * Format validator
 */
function validateFormat(attr, conf, err, done){
  /*jshint validthis:true */
  if (nullCheck.call(this, attr, conf, err)) {
    done();
    return;
  }

  if (typeof this[attr] === 'string') {
    if (!this[attr].match(conf['with'])) {
      err();
    }
  } else {
    err();
  }
  done();
}

/**
 * Custom validator
 */
function validateCustom(attr, conf, err, done){
  /*jshint validthis:true */
  conf.customValidator.call(this, attr, conf, err, done);
}

/**
 * Uniqueness validator
 */
function validateUniqueness(attr, conf, err, done){
  /*jshint validthis:true */
  if (nullCheck.call(this, attr, conf, err)) {
    done();
    return;
  }

  var cond = {where: {}};
  cond.where[attr] = this[attr];
  var inst = this;

  inst.constructor
  .all(cond)
  .then(curry(function (found){
    if (found.length > 1) {
      err();
    } else if (found.length === 1 && (!inst.id || !found[0].id || found[0].id.toString() != inst.id.toString())) {
      err();
    }
    done();
  }, this), err)
  .done();
}

var validators = {
  presence    : validatePresence,
  length      : validateLength,
  numericality: validateNumericality,
  inclusion   : validateInclusion,
  exclusion   : validateExclusion,
  format      : validateFormat,
  custom      : validateCustom,
  uniqueness  : validateUniqueness
};

function getConfigurator(name, opts){
  return function (){
    configure(this, name, arguments, opts);
  };
}

/**
 * This method performs validation, triggers validation hooks.
 * Before validation `obj.errors` collection cleaned.
 * Each validation can add errors to `obj.errors` collection.
 * If collection is not blank, validation failed.
 *
 * @warning This method can be called as sync only when no async validation
 * configured. It's strongly recommended to run all validations as asyncronous.
 *
 * @param {Object} data
 * @param {Function|Object} callback
 * @return {PromiseResolver.promise}
 *
 * @example ExpressJS controller: render user if valid, show flash otherwise
 *
 * ```
 * user
 * .isValid()
 * .catch(function (){
 *    res.flash('error', 'User is not valid'), console.log(user.errors), res.redirect('/users');
 * })
 * .done(function (){
 *    res.render({user: user});
 * });
 * ```
 */
Validatable.prototype.isValid = function (callback, data){
  var
    valid = true,
    inst = this,
    wait = 0,
    d = utils.defer();

  if (typeof callback !== 'function') {
    data = callback;
  } else {
    d.promise.nodeify(callback);
  }

  // exit with success when no errors
  if (!inst.constructor._validations) {
    cleanErrors(inst);

    inst.trigger('validate', function (validationsDone){
      validationsDone.call(inst, function (){
        d.resolve(inst);
      });
    });
  } else {
    utils.hiddenProperty(inst, 'errors', new Errors(inst));

    inst.trigger('validate', function (validationsDone){
      var
        asyncFail = false,
        done = function (fail){
          asyncFail = asyncFail || fail;

          if (--wait === 0) {
            validationsDone.call(inst, function (){
              if (valid && !asyncFail) {
                cleanErrors(inst);
                d.resolve(inst);
              } else {
                d.reject(new ValidationError(inst));
              }
            });
          }
        };

      inst.constructor._validations.forEach(function (v){
        wait += 1;
        validationFailed(inst, v, done);
      });
    }, data);
  }

  return d.promise;
};

function cleanErrors(inst){
  Object.defineProperty(inst, 'errors', {
    enumerable  : false,
    configurable: true,
    value       : false
  });
}

function validationFailed(inst, v, cb){
  var attr = v[0];
  var conf = v[1];
  var opts = v[2] || {};

  if (typeof attr !== 'string') {
    return cb(false);
  }

  // here we should check skip validation conditions (if, unless)
  // that can be specified in conf
  if (skipValidation(inst, conf, 'if')) {
    return cb(false);
  }
  if (skipValidation(inst, conf, 'unless')) {
    return cb(false);
  }

  var fail = false;
  var validator = validators[conf.validation];
  var validatorArguments = [];
  validatorArguments.push(attr);
  validatorArguments.push(conf);
  validatorArguments.push(function onerror(kind){
    var message, code = conf.validation;
    if (conf.message) {
      message = conf.message;
    }
    if (!message && defaultMessages[conf.validation]) {
      message = defaultMessages[conf.validation];
    }
    if (!message) {
      message = 'is invalid';
    }
    if (kind) {
      code += '.' + kind;
      if (message[kind]) {
        // get deeper
        message = message[kind];
      } else if (defaultMessages.common[kind]) {
        message = defaultMessages.common[kind];
      } else {
        message = 'is invalid';
      }
    }
    inst.errors.add(attr, message, code);
    fail = true;
  });

  validatorArguments.push(function (){
    cb(fail);
  });

  validator.apply(inst, validatorArguments);

  return fail;
}

function skipValidation(inst, conf, kind){
  var doValidate = true;
  if (typeof conf[kind] === 'function') {
    doValidate = conf[kind].call(inst);
    if (kind === 'unless') {
      doValidate = !doValidate;
    }
  } else if (typeof conf[kind] === 'string') {
    if (typeof inst[conf[kind]] === 'function') {
      doValidate = inst[conf[kind]].call(inst);
      if (kind === 'unless') {
        doValidate = !doValidate;
      }
    } else if (inst.__data.hasOwnProperty(conf[kind])) {
      doValidate = inst[conf[kind]];
      if (kind === 'unless') {
        doValidate = !doValidate;
      }
    } else {
      doValidate = kind === 'if';
    }
  }
  return !doValidate;
}

var defaultMessages = {
  presence    : 'can\'t be blank',
  length      : {
    min: 'too short',
    max: 'too long',
    is : 'length is wrong'
  },
  common      : {
    blank : 'is blank',
    'null': 'is null'
  },
  numericality: {
    'int'   : 'is not an integer',
    'number': 'is not a number'
  },
  inclusion   : 'is not included in the list',
  exclusion   : 'is reserved',
  uniqueness  : 'is not unique'
};

function nullCheck(attr, conf, err){
  /*jshint validthis:true */
  var isNull = this[attr] === null || !(attr in this);
  if (isNull) {
    if (!conf.allowNull) {
      err('null');
    }
    return true;
  } else {
    if (blank(this[attr])) {
      if (!conf.allowBlank) {
        err('blank');
      }
      return true;
    }
  }
  return false;
}

/**
 * Return true when v is undefined, blank array, null or empty string
 * otherwise returns false
 *
 * @param {*} v
 * @returns {Boolean} whether `v` blank or not
 */
function blank(v){
  if (typeof v === 'undefined') {
    return true;
  }
  if (v instanceof Array && v.length === 0) {
    return true;
  }
  if (v === null) {
    return true;
  }
  return typeof v == 'string' && v === '';

}

function configure(cls, validation, args, opts){
  if (!cls._validations) {
    utils.hiddenProperty(cls, '_validations', []);
  }
  args = utils.slice.call(args);
  var conf;
  if (typeof args[args.length - 1] === 'object') {
    conf = args.pop();
  } else {
    conf = {};
  }
  if (validation === 'custom' && typeof args[args.length - 1] === 'function') {
    conf.customValidator = args.pop();
  }
  conf.validation = validation;
  args.forEach(function (attr){
    cls._validations.push([attr, conf, opts]);
  });
}

function Errors(obj){
  utils.hiddenProperty(this, '__codes', {});
  utils.hiddenProperty(this, '__obj', obj);
}

Errors.prototype.add = function (field, message, code){
  code = code || 'invalid';
  if (!this[field]) {
    this[field] = [];
    this.__codes[field] = [];
  }
  this[field].push(message);
  this.__codes[field].push(code);
};

Errors.prototype.__localize = function localize(locale){
  var errors = this, result = {}, i18n, v, codes = this.__codes;
  i18n = this.__obj.constructor.i18n;
  v = i18n && i18n[locale] && i18n[locale].validation;

  Object.keys(codes).forEach(function (prop){
    result[prop] = codes[prop].map(function (code, i){
      return v && v[prop] && v[prop][code] || errors[prop][i];
    });
  });
  return result;
};

function ErrorCodes(messages){
  var c = this;
  Object.keys(messages).forEach(function (field){
    c[field] = messages[field].__codes;
  });
}

function ValidationError(obj){
  this.name = 'ValidationError';
  this.message = 'Validation error';
  this.statusCode = 400;
  this.obj = obj;
  this.codes = this.obj.errors && this.obj.errors.__codes;
  this.context = this.obj && this.obj.constructor && this.obj.constructor.modelName;

  Error.call(this);
}

ValidationError.prototype.__proto__ = Error.prototype;

},{"./model.js":11,"./utils":15}]},{},[7])
(7)
});