(function() {

  var requires_ = {};

  requires_['bluebird'] = function(module, exports, require, __dirname, __filename) {
  
    !function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.bluebird=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, Promise$_CreatePromiseArray, PromiseArray) {
    
        var SomePromiseArray = _dereq_("./some_promise_array.js")(PromiseArray);
        var ASSERT = _dereq_("./assert.js");
    
        function Promise$_Any(promises, useBound, caller) {
            var ret = Promise$_CreatePromiseArray(
                promises,
                SomePromiseArray,
                caller,
                useBound === true && promises._isBound()
                    ? promises._boundTo
                    : void 0
           );
            var promise = ret.promise();
            if (promise.isRejected()) {
                return promise;
            }
            ret.setHowMany(1);
            ret.setUnwrap();
            ret.init();
            return promise;
        }
    
        Promise.any = function Promise$Any(promises) {
            return Promise$_Any(promises, false, Promise.any);
        };
    
        Promise.prototype.any = function Promise$any() {
            return Promise$_Any(this, true, this.any);
        };
    
    };
    
    },{"./assert.js":2,"./some_promise_array.js":35}],2:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = (function(){
        var AssertionError = (function() {
            function AssertionError(a) {
                this.constructor$(a);
                this.message = a;
                this.name = "AssertionError";
            }
            AssertionError.prototype = new Error();
            AssertionError.prototype.constructor = AssertionError;
            AssertionError.prototype.constructor$ = Error;
            return AssertionError;
        })();
    
        return function assert(boolExpr, message) {
            if (boolExpr === true) return;
    
            var ret = new AssertionError(message);
            if (Error.captureStackTrace) {
                Error.captureStackTrace(ret, assert);
            }
            if (console && console.error) {
                console.error(ret.stack + "");
            }
            throw ret;
    
        };
    })();
    
    },{}],3:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var ASSERT = _dereq_("./assert.js");
    var schedule = _dereq_("./schedule.js");
    var Queue = _dereq_("./queue.js");
    var errorObj = _dereq_("./util.js").errorObj;
    var tryCatch1 = _dereq_("./util.js").tryCatch1;
    
    function Async() {
        this._isTickUsed = false;
        this._length = 0;
        this._lateBuffer = new Queue();
        this._functionBuffer = new Queue(25000 * 3);
        var self = this;
        this.consumeFunctionBuffer = function Async$consumeFunctionBuffer() {
            self._consumeFunctionBuffer();
        };
    }
    
    Async.prototype.haveItemsQueued = function Async$haveItemsQueued() {
        return this._length > 0;
    };
    
    Async.prototype.invokeLater = function Async$invokeLater(fn, receiver, arg) {
        this._lateBuffer.push(fn, receiver, arg);
        this._queueTick();
    };
    
    Async.prototype.invoke = function Async$invoke(fn, receiver, arg) {
        var functionBuffer = this._functionBuffer;
        functionBuffer.push(fn, receiver, arg);
        this._length = functionBuffer.length();
        this._queueTick();
    };
    
    Async.prototype._consumeFunctionBuffer =
    function Async$_consumeFunctionBuffer() {
        var functionBuffer = this._functionBuffer;
        while(functionBuffer.length() > 0) {
            var fn = functionBuffer.shift();
            var receiver = functionBuffer.shift();
            var arg = functionBuffer.shift();
            fn.call(receiver, arg);
        }
        this._reset();
        this._consumeLateBuffer();
    };
    
    Async.prototype._consumeLateBuffer = function Async$_consumeLateBuffer() {
        var buffer = this._lateBuffer;
        while(buffer.length() > 0) {
            var fn = buffer.shift();
            var receiver = buffer.shift();
            var arg = buffer.shift();
            var res = tryCatch1(fn, receiver, arg);
            if (res === errorObj) {
                this._queueTick();
                throw res.e;
            }
        }
    };
    
    Async.prototype._queueTick = function Async$_queue() {
        if (!this._isTickUsed) {
            schedule(this.consumeFunctionBuffer);
            this._isTickUsed = true;
        }
    };
    
    Async.prototype._reset = function Async$_reset() {
        this._isTickUsed = false;
        this._length = 0;
    };
    
    module.exports = new Async();
    
    },{"./assert.js":2,"./queue.js":28,"./schedule.js":31,"./util.js":39}],4:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var Promise = _dereq_("./promise.js")();
    module.exports = Promise;
    },{"./promise.js":20}],5:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise) {
        Promise.prototype.call = function Promise$call(propertyName) {
            var $_len = arguments.length;var args = new Array($_len - 1); for(var $_i = 1; $_i < $_len; ++$_i) {args[$_i - 1] = arguments[$_i];}
    
            return this._then(function(obj) {
                    return obj[propertyName].apply(obj, args);
                },
                void 0,
                void 0,
                void 0,
                void 0,
                this.call
           );
        };
    
        function Promise$getter(obj) {
            var prop = typeof this === "string"
                ? this
                : ("" + this);
            return obj[prop];
        }
        Promise.prototype.get = function Promise$get(propertyName) {
            return this._then(
                Promise$getter,
                void 0,
                void 0,
                propertyName,
                void 0,
                this.get
           );
        };
    };
    
    },{}],6:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, INTERNAL) {
        var errors = _dereq_("./errors.js");
        var async = _dereq_("./async.js");
        var ASSERT = _dereq_("./assert.js");
        var CancellationError = errors.CancellationError;
        var SYNC_TOKEN = {};
    
        Promise.prototype._cancel = function Promise$_cancel() {
            if (!this.isCancellable()) return this;
            var parent;
            if ((parent = this._cancellationParent) !== void 0) {
                parent.cancel(SYNC_TOKEN);
                return;
            }
            var err = new CancellationError();
            this._attachExtraTrace(err);
            this._rejectUnchecked(err);
        };
    
        Promise.prototype.cancel = function Promise$cancel(token) {
            if (!this.isCancellable()) return this;
            if (token === SYNC_TOKEN) {
                this._cancel();
                return this;
            }
            async.invokeLater(this._cancel, this, void 0);
            return this;
        };
    
        Promise.prototype.cancellable = function Promise$cancellable() {
            if (this._cancellable()) return this;
            this._setCancellable();
            this._cancellationParent = void 0;
            return this;
        };
    
        Promise.prototype.uncancellable = function Promise$uncancellable() {
            var ret = new Promise(INTERNAL);
            ret._setTrace(this.uncancellable, this);
            ret._follow(this);
            ret._unsetCancellable();
            if (this._isBound()) ret._setBoundTo(this._boundTo);
            return ret;
        };
    
        Promise.prototype.fork =
        function Promise$fork(didFulfill, didReject, didProgress) {
            var ret = this._then(didFulfill, didReject, didProgress,
                void 0, void 0, this.fork);
    
            ret._setCancellable();
            ret._cancellationParent = void 0;
            return ret;
        };
    };
    
    },{"./assert.js":2,"./async.js":3,"./errors.js":10}],7:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function() {
    var ASSERT = _dereq_("./assert.js");
    var inherits = _dereq_("./util.js").inherits;
    var defineProperty = _dereq_("./es5.js").defineProperty;
    
    var rignore = new RegExp(
        "\\b(?:[\\w.]*Promise(?:Array|Spawn)?\\$_\\w+|" +
        "tryCatch(?:1|2|Apply)|new \\w*PromiseArray|" +
        "\\w*PromiseArray\\.\\w*PromiseArray|" +
        "setTimeout|CatchFilter\\$_\\w+|makeNodePromisified|processImmediate|" +
        "process._tickCallback|nextTick|Async\\$\\w+)\\b"
    );
    
    var rtraceline = null;
    var formatStack = null;
    var areNamesMangled = false;
    
    function formatNonError(obj) {
        var str;
        if (typeof obj === "function") {
            str = "[function " +
                (obj.name || "anonymous") +
                "]";
        }
        else {
            str = obj.toString();
            var ruselessToString = /\[object [a-zA-Z0-9$_]+\]/;
            if (ruselessToString.test(str)) {
                try {
                    var newStr = JSON.stringify(obj);
                    str = newStr;
                }
                catch(e) {
    
                }
            }
            if (str.length === 0) {
                str = "(empty array)";
            }
        }
        return ("(<" + snip(str) + ">, no stack trace)");
    }
    
    function snip(str) {
        var maxChars = 41;
        if (str.length < maxChars) {
            return str;
        }
        return str.substr(0, maxChars - 3) + "...";
    }
    
    function CapturedTrace(ignoreUntil, isTopLevel) {
        if (!areNamesMangled) {
        }
        this.captureStackTrace(ignoreUntil, isTopLevel);
    
    }
    inherits(CapturedTrace, Error);
    
    CapturedTrace.prototype.captureStackTrace =
    function CapturedTrace$captureStackTrace(ignoreUntil, isTopLevel) {
        captureStackTrace(this, ignoreUntil, isTopLevel);
    };
    
    CapturedTrace.possiblyUnhandledRejection =
    function CapturedTrace$PossiblyUnhandledRejection(reason) {
        if (typeof console === "object") {
            var message;
            if (typeof reason === "object" || typeof reason === "function") {
                var stack = reason.stack;
                message = "Possibly unhandled " + formatStack(stack, reason);
            }
            else {
                message = "Possibly unhandled " + String(reason);
            }
            if (typeof console.error === "function" ||
                typeof console.error === "object") {
                console.error(message);
            }
            else if (typeof console.log === "function" ||
                typeof console.error === "object") {
                console.log(message);
            }
        }
    };
    
    areNamesMangled = CapturedTrace.prototype.captureStackTrace.name !==
        "CapturedTrace$captureStackTrace";
    
    CapturedTrace.combine = function CapturedTrace$Combine(current, prev) {
        var curLast = current.length - 1;
        for (var i = prev.length - 1; i >= 0; --i) {
            var line = prev[i];
            if (current[curLast] === line) {
                current.pop();
                curLast--;
            }
            else {
                break;
            }
        }
    
        current.push("From previous event:");
        var lines = current.concat(prev);
    
        var ret = [];
    
    
        for (var i = 0, len = lines.length; i < len; ++i) {
    
            if ((rignore.test(lines[i]) ||
                (i > 0 && !rtraceline.test(lines[i])) &&
                lines[i] !== "From previous event:")
           ) {
                continue;
            }
            ret.push(lines[i]);
        }
        return ret;
    };
    
    CapturedTrace.isSupported = function CapturedTrace$IsSupported() {
        return typeof captureStackTrace === "function";
    };
    
    var captureStackTrace = (function stackDetection() {
        if (typeof Error.stackTraceLimit === "number" &&
            typeof Error.captureStackTrace === "function") {
            rtraceline = /^\s*at\s*/;
            formatStack = function(stack, error) {
                if (typeof stack === "string") return stack;
    
                if (error.name !== void 0 &&
                    error.message !== void 0) {
                    return error.name + ". " + error.message;
                }
                return formatNonError(error);
    
    
            };
            var captureStackTrace = Error.captureStackTrace;
            return function CapturedTrace$_captureStackTrace(
                receiver, ignoreUntil) {
                captureStackTrace(receiver, ignoreUntil);
            };
        }
        var err = new Error();
    
        if (!areNamesMangled && typeof err.stack === "string" &&
            typeof "".startsWith === "function" &&
            (err.stack.startsWith("stackDetection@")) &&
            stackDetection.name === "stackDetection") {
    
            defineProperty(Error, "stackTraceLimit", {
                writable: true,
                enumerable: false,
                configurable: false,
                value: 25
            });
            rtraceline = /@/;
            var rline = /[@\n]/;
    
            formatStack = function(stack, error) {
                if (typeof stack === "string") {
                    return (error.name + ". " + error.message + "\n" + stack);
                }
    
                if (error.name !== void 0 &&
                    error.message !== void 0) {
                    return error.name + ". " + error.message;
                }
                return formatNonError(error);
            };
    
            return function captureStackTrace(o, fn) {
                var name = fn.name;
                var stack = new Error().stack;
                var split = stack.split(rline);
                var i, len = split.length;
                for (i = 0; i < len; i += 2) {
                    if (split[i] === name) {
                        break;
                    }
                }
                split = split.slice(i + 2);
                len = split.length - 2;
                var ret = "";
                for (i = 0; i < len; i += 2) {
                    ret += split[i];
                    ret += "@";
                    ret += split[i + 1];
                    ret += "\n";
                }
                o.stack = ret;
            };
        }
        else {
            formatStack = function(stack, error) {
                if (typeof stack === "string") return stack;
    
                if ((typeof error === "object" ||
                    typeof error === "function") &&
                    error.name !== void 0 &&
                    error.message !== void 0) {
                    return error.name + ". " + error.message;
                }
                return formatNonError(error);
            };
    
            return null;
        }
    })();
    
    return CapturedTrace;
    };
    
    },{"./assert.js":2,"./es5.js":12,"./util.js":39}],8:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(NEXT_FILTER) {
    var util = _dereq_("./util.js");
    var errors = _dereq_("./errors.js");
    var tryCatch1 = util.tryCatch1;
    var errorObj = util.errorObj;
    var keys = _dereq_("./es5.js").keys;
    
    function CatchFilter(instances, callback, promise) {
        this._instances = instances;
        this._callback = callback;
        this._promise = promise;
    }
    
    function CatchFilter$_safePredicate(predicate, e) {
        var safeObject = {};
        var retfilter = tryCatch1(predicate, safeObject, e);
    
        if (retfilter === errorObj) return retfilter;
    
        var safeKeys = keys(safeObject);
        if (safeKeys.length) {
            errorObj.e = new TypeError(
                "Catch filter must inherit from Error "
              + "or be a simple predicate function");
            return errorObj;
        }
        return retfilter;
    }
    
    CatchFilter.prototype.doFilter = function CatchFilter$_doFilter(e) {
        var cb = this._callback;
        var promise = this._promise;
        var boundTo = promise._isBound() ? promise._boundTo : void 0;
        for (var i = 0, len = this._instances.length; i < len; ++i) {
            var item = this._instances[i];
            var itemIsErrorType = item === Error ||
                (item != null && item.prototype instanceof Error);
    
            if (itemIsErrorType && e instanceof item) {
                var ret = tryCatch1(cb, boundTo, e);
                if (ret === errorObj) {
                    NEXT_FILTER.e = ret.e;
                    return NEXT_FILTER;
                }
                return ret;
            } else if (typeof item === "function" && !itemIsErrorType) {
                var shouldHandle = CatchFilter$_safePredicate(item, e);
                if (shouldHandle === errorObj) {
                    var trace = errors.canAttach(errorObj.e)
                        ? errorObj.e
                        : new Error(errorObj.e + "");
                    this._promise._attachExtraTrace(trace);
                    e = errorObj.e;
                    break;
                } else if (shouldHandle) {
                    var ret = tryCatch1(cb, boundTo, e);
                    if (ret === errorObj) {
                        NEXT_FILTER.e = ret.e;
                        return NEXT_FILTER;
                    }
                    return ret;
                }
            }
        }
        NEXT_FILTER.e = e;
        return NEXT_FILTER;
    };
    
    return CatchFilter;
    };
    
    },{"./errors.js":10,"./es5.js":12,"./util.js":39}],9:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var util = _dereq_("./util.js");
    var ASSERT = _dereq_("./assert.js");
    var isPrimitive = util.isPrimitive;
    var wrapsPrimitiveReceiver = util.wrapsPrimitiveReceiver;
    
    module.exports = function(Promise) {
    var returner = function Promise$_returner() {
        return this;
    };
    var thrower = function Promise$_thrower() {
        throw this;
    };
    
    var wrapper = function Promise$_wrapper(value, action) {
        if (action === 1) {
            return function Promise$_thrower() {
                throw value;
            };
        }
        else if (action === 2) {
            return function Promise$_returner() {
                return value;
            };
        }
    };
    
    
    Promise.prototype["return"] =
    Promise.prototype.thenReturn =
    function Promise$thenReturn(value) {
        if (wrapsPrimitiveReceiver && isPrimitive(value)) {
            return this._then(
                wrapper(value, 2),
                void 0,
                void 0,
                void 0,
                void 0,
                this.thenReturn
           );
        }
        return this._then(returner, void 0, void 0,
                            value, void 0, this.thenReturn);
    };
    
    Promise.prototype["throw"] =
    Promise.prototype.thenThrow =
    function Promise$thenThrow(reason) {
        if (wrapsPrimitiveReceiver && isPrimitive(reason)) {
            return this._then(
                wrapper(reason, 1),
                void 0,
                void 0,
                void 0,
                void 0,
                this.thenThrow
           );
        }
        return this._then(thrower, void 0, void 0,
                            reason, void 0, this.thenThrow);
    };
    };
    
    },{"./assert.js":2,"./util.js":39}],10:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var global = _dereq_("./global.js");
    var Objectfreeze = _dereq_("./es5.js").freeze;
    var util = _dereq_("./util.js");
    var inherits = util.inherits;
    var notEnumerableProp = util.notEnumerableProp;
    var Error = global.Error;
    
    function markAsOriginatingFromRejection(e) {
        try {
            notEnumerableProp(e, "isAsync", true);
        }
        catch(ignore) {}
    }
    
    function originatesFromRejection(e) {
        if (e == null) return false;
        return ((e instanceof RejectionError) ||
            e["isAsync"] === true);
    }
    
    function isError(obj) {
        return obj instanceof Error;
    }
    
    function canAttach(obj) {
        return isError(obj);
    }
    
    function subError(nameProperty, defaultMessage) {
        function SubError(message) {
            if (!(this instanceof SubError)) return new SubError(message);
            this.message = typeof message === "string" ? message : defaultMessage;
            this.name = nameProperty;
            if (Error.captureStackTrace) {
                Error.captureStackTrace(this, this.constructor);
            }
        }
        inherits(SubError, Error);
        return SubError;
    }
    
    var TypeError = global.TypeError;
    if (typeof TypeError !== "function") {
        TypeError = subError("TypeError", "type error");
    }
    var RangeError = global.RangeError;
    if (typeof RangeError !== "function") {
        RangeError = subError("RangeError", "range error");
    }
    var CancellationError = subError("CancellationError", "cancellation error");
    var TimeoutError = subError("TimeoutError", "timeout error");
    
    function RejectionError(message) {
        this.name = "RejectionError";
        this.message = message;
        this.cause = message;
        this.isAsync = true;
    
        if (message instanceof Error) {
            this.message = message.message;
            this.stack = message.stack;
        }
        else if (Error.captureStackTrace) {
            Error.captureStackTrace(this, this.constructor);
        }
    
    }
    inherits(RejectionError, Error);
    
    var key = "__BluebirdErrorTypes__";
    var errorTypes = global[key];
    if (!errorTypes) {
        errorTypes = Objectfreeze({
            CancellationError: CancellationError,
            TimeoutError: TimeoutError,
            RejectionError: RejectionError
        });
        notEnumerableProp(global, key, errorTypes);
    }
    
    module.exports = {
        Error: Error,
        TypeError: TypeError,
        RangeError: RangeError,
        CancellationError: errorTypes.CancellationError,
        RejectionError: errorTypes.RejectionError,
        TimeoutError: errorTypes.TimeoutError,
        originatesFromRejection: originatesFromRejection,
        markAsOriginatingFromRejection: markAsOriginatingFromRejection,
        canAttach: canAttach
    };
    
    },{"./es5.js":12,"./global.js":16,"./util.js":39}],11:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise) {
    var TypeError = _dereq_('./errors.js').TypeError;
    
    function apiRejection(msg) {
        var error = new TypeError(msg);
        var ret = Promise.rejected(error);
        var parent = ret._peekContext();
        if (parent != null) {
            parent._attachExtraTrace(error);
        }
        return ret;
    }
    
    return apiRejection;
    };
    
    },{"./errors.js":10}],12:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    var isES5 = (function(){
        "use strict";
        return this === void 0;
    })();
    
    if (isES5) {
        module.exports = {
            freeze: Object.freeze,
            defineProperty: Object.defineProperty,
            keys: Object.keys,
            getPrototypeOf: Object.getPrototypeOf,
            isArray: Array.isArray,
            isES5: isES5
        };
    }
    
    else {
        var has = {}.hasOwnProperty;
        var str = {}.toString;
        var proto = {}.constructor.prototype;
    
        function ObjectKeys(o) {
            var ret = [];
            for (var key in o) {
                if (has.call(o, key)) {
                    ret.push(key);
                }
            }
            return ret;
        }
    
        function ObjectDefineProperty(o, key, desc) {
            o[key] = desc.value;
            return o;
        }
    
        function ObjectFreeze(obj) {
            return obj;
        }
    
        function ObjectGetPrototypeOf(obj) {
            try {
                return Object(obj).constructor.prototype;
            }
            catch (e) {
                return proto;
            }
        }
    
        function ArrayIsArray(obj) {
            try {
                return str.call(obj) === "[object Array]";
            }
            catch(e) {
                return false;
            }
        }
    
        module.exports = {
            isArray: ArrayIsArray,
            keys: ObjectKeys,
            defineProperty: ObjectDefineProperty,
            freeze: ObjectFreeze,
            getPrototypeOf: ObjectGetPrototypeOf,
            isES5: isES5
        };
    }
    
    },{}],13:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise) {
        var ASSERT = _dereq_("./assert.js");
        var isArray = _dereq_("./util.js").isArray;
    
        function Promise$_filter(booleans) {
            var values = this._settledValue;
            var len = values.length;
            var ret = new Array(len);
            var j = 0;
    
            for (var i = 0; i < len; ++i) {
                if (booleans[i]) ret[j++] = values[i];
    
            }
            ret.length = j;
            return ret;
        }
    
        var ref = {ref: null};
        Promise.filter = function Promise$Filter(promises, fn) {
            return Promise.map(promises, fn, ref)
                ._then(Promise$_filter, void 0, void 0,
                        ref.ref, void 0, Promise.filter);
        };
    
        Promise.prototype.filter = function Promise$filter(fn) {
            return this.map(fn, ref)
                ._then(Promise$_filter, void 0, void 0,
                        ref.ref, void 0, this.filter);
        };
    };
    
    },{"./assert.js":2,"./util.js":39}],14:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    module.exports = function(Promise, NEXT_FILTER) {
        var util = _dereq_("./util.js");
        var wrapsPrimitiveReceiver = util.wrapsPrimitiveReceiver;
        var isPrimitive = util.isPrimitive;
        var thrower = util.thrower;
    
    
        function returnThis() {
            return this;
        }
        function throwThis() {
            throw this;
        }
        function makeReturner(r) {
            return function Promise$_returner() {
                return r;
            };
        }
        function makeThrower(r) {
            return function Promise$_thrower() {
                throw r;
            };
        }
        function promisedFinally(ret, reasonOrValue, isFulfilled) {
            var useConstantFunction =
                            wrapsPrimitiveReceiver && isPrimitive(reasonOrValue);
    
            if (isFulfilled) {
                return ret._then(
                    useConstantFunction
                        ? returnThis
                        : makeReturner(reasonOrValue),
                    thrower, void 0, reasonOrValue, void 0, promisedFinally);
            }
            else {
                return ret._then(
                    useConstantFunction
                        ? throwThis
                        : makeThrower(reasonOrValue),
                    thrower, void 0, reasonOrValue, void 0, promisedFinally);
            }
        }
    
        function finallyHandler(reasonOrValue) {
            var promise = this.promise;
            var handler = this.handler;
    
            var ret = promise._isBound()
                            ? handler.call(promise._boundTo)
                            : handler();
    
            if (ret !== void 0) {
                var maybePromise = Promise._cast(ret, finallyHandler, void 0);
                if (Promise.is(maybePromise)) {
                    return promisedFinally(maybePromise, reasonOrValue,
                                            promise.isFulfilled());
                }
            }
    
            if (promise.isRejected()) {
                NEXT_FILTER.e = reasonOrValue;
                return NEXT_FILTER;
            }
            else {
                return reasonOrValue;
            }
        }
    
        Promise.prototype.lastly = Promise.prototype["finally"] =
        function Promise$finally(handler) {
            if (typeof handler !== "function") return this.then();
    
            var promiseAndHandler = {
                promise: this,
                handler: handler
            };
    
            return this._then(finallyHandler, finallyHandler, void 0,
                    promiseAndHandler, void 0, this.lastly);
        };
    };
    
    },{"./util.js":39}],15:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, apiRejection, INTERNAL) {
        var PromiseSpawn = _dereq_("./promise_spawn.js")(Promise, INTERNAL);
        var errors = _dereq_("./errors.js");
        var TypeError = errors.TypeError;
    
        Promise.coroutine = function Promise$Coroutine(generatorFunction) {
            if (typeof generatorFunction !== "function") {
                throw new TypeError("generatorFunction must be a function");
            }
            var PromiseSpawn$ = PromiseSpawn;
            return function anonymous() {
                var generator = generatorFunction.apply(this, arguments);
                var spawn = new PromiseSpawn$(void 0, void 0, anonymous);
                spawn._generator = generator;
                spawn._next(void 0);
                return spawn.promise();
            };
        };
    
        Promise.spawn = function Promise$Spawn(generatorFunction) {
            if (typeof generatorFunction !== "function") {
                return apiRejection("generatorFunction must be a function");
            }
            var spawn = new PromiseSpawn(generatorFunction, this, Promise.spawn);
            var ret = spawn.promise();
            spawn._run(Promise.spawn);
            return ret;
        };
    };
    
    },{"./errors.js":10,"./promise_spawn.js":24}],16:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = (function(){
        if (typeof this !== "undefined") {
            return this;
        }
        if (typeof process !== "undefined" &&
            typeof global !== "undefined" &&
            typeof process.execPath === "string") {
            return global;
        }
        if (typeof window !== "undefined" &&
            typeof document !== "undefined" &&
            typeof navigator !== "undefined" && navigator !== null &&
            typeof navigator.appName === "string") {
                if(window.wrappedJSObject !== undefined){
                    return window.wrappedJSObject;
                }
            return window;
        }
    })();
    
    },{}],17:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(
        Promise, Promise$_CreatePromiseArray, PromiseArray, apiRejection) {
    
        var ASSERT = _dereq_("./assert.js");
    
        function Promise$_mapper(values) {
            var fn = this;
            var receiver = void 0;
    
            if (typeof fn !== "function")  {
                receiver = fn.receiver;
                fn = fn.fn;
            }
            var shouldDefer = false;
    
            var ret = new Array(values.length);
    
            if (receiver === void 0) {
                for (var i = 0, len = values.length; i < len; ++i) {
                    var value = fn(values[i], i, len);
                    if (!shouldDefer) {
                        var maybePromise = Promise._cast(value,
                                Promise$_mapper, void 0);
                        if (maybePromise instanceof Promise) {
                            if (maybePromise.isFulfilled()) {
                                ret[i] = maybePromise._settledValue;
                                continue;
                            }
                            else {
                                shouldDefer = true;
                            }
                            value = maybePromise;
                        }
                    }
                    ret[i] = value;
                }
            }
            else {
                for (var i = 0, len = values.length; i < len; ++i) {
                    var value = fn.call(receiver, values[i], i, len);
                    if (!shouldDefer) {
                        var maybePromise = Promise._cast(value,
                                Promise$_mapper, void 0);
                        if (maybePromise instanceof Promise) {
                            if (maybePromise.isFulfilled()) {
                                ret[i] = maybePromise._settledValue;
                                continue;
                            }
                            else {
                                shouldDefer = true;
                            }
                            value = maybePromise;
                        }
                    }
                    ret[i] = value;
                }
            }
            return shouldDefer
                ? Promise$_CreatePromiseArray(ret, PromiseArray,
                    Promise$_mapper, void 0).promise()
                : ret;
        }
    
        function Promise$_Map(promises, fn, useBound, caller, ref) {
            if (typeof fn !== "function") {
                return apiRejection("fn must be a function");
            }
    
            if (useBound === true && promises._isBound()) {
                fn = {
                    fn: fn,
                    receiver: promises._boundTo
                };
            }
    
            var ret = Promise$_CreatePromiseArray(
                promises,
                PromiseArray,
                caller,
                useBound === true && promises._isBound()
                    ? promises._boundTo
                    : void 0
           ).promise();
    
            if (ref !== void 0) {
                ref.ref = ret;
            }
    
            return ret._then(
                Promise$_mapper,
                void 0,
                void 0,
                fn,
                void 0,
                caller
           );
        }
    
        Promise.prototype.map = function Promise$map(fn, ref) {
            return Promise$_Map(this, fn, true, this.map, ref);
        };
    
        Promise.map = function Promise$Map(promises, fn, ref) {
            return Promise$_Map(promises, fn, false, Promise.map, ref);
        };
    };
    
    },{"./assert.js":2}],18:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise) {
        var util = _dereq_("./util.js");
        var async = _dereq_("./async.js");
        var ASSERT = _dereq_("./assert.js");
        var tryCatch2 = util.tryCatch2;
        var tryCatch1 = util.tryCatch1;
        var errorObj = util.errorObj;
    
        function thrower(r) {
            throw r;
        }
    
        function Promise$_successAdapter(val, receiver) {
            var nodeback = this;
            var ret = tryCatch2(nodeback, receiver, null, val);
            if (ret === errorObj) {
                async.invokeLater(thrower, void 0, ret.e);
            }
        }
        function Promise$_errorAdapter(reason, receiver) {
            var nodeback = this;
            var ret = tryCatch1(nodeback, receiver, reason);
            if (ret === errorObj) {
                async.invokeLater(thrower, void 0, ret.e);
            }
        }
    
        Promise.prototype.nodeify = function Promise$nodeify(nodeback) {
            if (typeof nodeback == "function") {
                this._then(
                    Promise$_successAdapter,
                    Promise$_errorAdapter,
                    void 0,
                    nodeback,
                    this._isBound() ? this._boundTo : null,
                    this.nodeify
               );
            }
            return this;
        };
    };
    
    },{"./assert.js":2,"./async.js":3,"./util.js":39}],19:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, isPromiseArrayProxy) {
        var ASSERT = _dereq_("./assert.js");
        var util = _dereq_("./util.js");
        var async = _dereq_("./async.js");
        var errors = _dereq_("./errors.js");
        var tryCatch1 = util.tryCatch1;
        var errorObj = util.errorObj;
    
        Promise.prototype.progressed = function Promise$progressed(handler) {
            return this._then(void 0, void 0, handler,
                                void 0, void 0, this.progressed);
        };
    
        Promise.prototype._progress = function Promise$_progress(progressValue) {
            if (this._isFollowingOrFulfilledOrRejected()) return;
            this._progressUnchecked(progressValue);
    
        };
    
        Promise.prototype._progressHandlerAt =
        function Promise$_progressHandlerAt(index) {
            if (index === 0) return this._progressHandler0;
            return this[index + 2 - 5];
        };
    
        Promise.prototype._doProgressWith =
        function Promise$_doProgressWith(progression) {
            var progressValue = progression.value;
            var handler = progression.handler;
            var promise = progression.promise;
            var receiver = progression.receiver;
    
            this._pushContext();
            var ret = tryCatch1(handler, receiver, progressValue);
            this._popContext();
    
            if (ret === errorObj) {
                if (ret.e != null &&
                    ret.e.name !== "StopProgressPropagation") {
                    var trace = errors.canAttach(ret.e)
                        ? ret.e : new Error(ret.e + "");
                    promise._attachExtraTrace(trace);
                    promise._progress(ret.e);
                }
            }
            else if (Promise.is(ret)) {
                ret._then(promise._progress, null, null, promise, void 0,
                    this._progress);
            }
            else {
                promise._progress(ret);
            }
        };
    
    
        Promise.prototype._progressUnchecked =
        function Promise$_progressUnchecked(progressValue) {
            if (!this.isPending()) return;
            var len = this._length();
    
            for (var i = 0; i < len; i += 5) {
                var handler = this._progressHandlerAt(i);
                var promise = this._promiseAt(i);
                if (!Promise.is(promise)) {
                    var receiver = this._receiverAt(i);
                    if (typeof handler === "function") {
                        handler.call(receiver, progressValue, promise);
                    }
                    else if (Promise.is(receiver) && receiver._isProxied()) {
                        receiver._progressUnchecked(progressValue);
                    }
                    else if (isPromiseArrayProxy(receiver, promise)) {
                        receiver._promiseProgressed(progressValue, promise);
                    }
                    continue;
                }
    
                if (typeof handler === "function") {
                    async.invoke(this._doProgressWith, this, {
                        handler: handler,
                        promise: promise,
                        receiver: this._receiverAt(i),
                        value: progressValue
                    });
                }
                else {
                    async.invoke(promise._progress, promise, progressValue);
                }
            }
        };
    };
    
    },{"./assert.js":2,"./async.js":3,"./errors.js":10,"./util.js":39}],20:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function() {
    var global = _dereq_("./global.js");
    var ASSERT = _dereq_("./assert.js");
    var util = _dereq_("./util.js");
    var async = _dereq_("./async.js");
    var errors = _dereq_("./errors.js");
    
    var INTERNAL = function(){};
    var APPLY = {};
    var NEXT_FILTER = {e: null};
    
    var PromiseArray = _dereq_("./promise_array.js")(Promise, INTERNAL);
    var CapturedTrace = _dereq_("./captured_trace.js")();
    var CatchFilter = _dereq_("./catch_filter.js")(NEXT_FILTER);
    var PromiseResolver = _dereq_("./promise_resolver.js");
    
    var isArray = util.isArray;
    
    var errorObj = util.errorObj;
    var tryCatch1 = util.tryCatch1;
    var tryCatch2 = util.tryCatch2;
    var tryCatchApply = util.tryCatchApply;
    var RangeError = errors.RangeError;
    var TypeError = errors.TypeError;
    var CancellationError = errors.CancellationError;
    var TimeoutError = errors.TimeoutError;
    var RejectionError = errors.RejectionError;
    var originatesFromRejection = errors.originatesFromRejection;
    var markAsOriginatingFromRejection = errors.markAsOriginatingFromRejection;
    var canAttach = errors.canAttach;
    var thrower = util.thrower;
    var apiRejection = _dereq_("./errors_api_rejection")(Promise);
    
    
    var makeSelfResolutionError = function Promise$_makeSelfResolutionError() {
        return new TypeError("circular promise resolution chain");
    };
    
    function isPromise(obj) {
        if (obj === void 0) return false;
        return obj instanceof Promise;
    }
    
    function isPromiseArrayProxy(receiver, promiseSlotValue) {
        if (receiver instanceof PromiseArray) {
            return promiseSlotValue >= 0;
        }
        return false;
    }
    
    function Promise(resolver) {
        if (typeof resolver !== "function") {
            throw new TypeError("the promise constructor requires a resolver function");
        }
        if (this.constructor !== Promise) {
            throw new TypeError("the promise constructor cannot be invoked directly");
        }
        this._bitField = 0;
        this._fulfillmentHandler0 = void 0;
        this._rejectionHandler0 = void 0;
        this._promise0 = void 0;
        this._receiver0 = void 0;
        this._settledValue = void 0;
        this._boundTo = void 0;
        if (resolver !== INTERNAL) this._resolveFromResolver(resolver);
    }
    
    Promise.prototype.bind = function Promise$bind(thisArg) {
        var ret = new Promise(INTERNAL);
        if (debugging) ret._setTrace(this.bind, this);
        ret._follow(this);
        ret._setBoundTo(thisArg);
        if (this._cancellable()) {
            ret._setCancellable();
            ret._cancellationParent = this;
        }
        return ret;
    };
    
    Promise.prototype.toString = function Promise$toString() {
        return "[object Promise]";
    };
    
    Promise.prototype.caught = Promise.prototype["catch"] =
    function Promise$catch(fn) {
        var len = arguments.length;
        if (len > 1) {
            var catchInstances = new Array(len - 1),
                j = 0, i;
            for (i = 0; i < len - 1; ++i) {
                var item = arguments[i];
                if (typeof item === "function") {
                    catchInstances[j++] = item;
                }
                else {
                    var catchFilterTypeError =
                        new TypeError(
                            "A catch filter must be an error constructor "
                            + "or a filter function");
    
                    this._attachExtraTrace(catchFilterTypeError);
                    async.invoke(this._reject, this, catchFilterTypeError);
                    return;
                }
            }
            catchInstances.length = j;
            fn = arguments[i];
    
            this._resetTrace(this.caught);
            var catchFilter = new CatchFilter(catchInstances, fn, this);
            return this._then(void 0, catchFilter.doFilter, void 0,
                catchFilter, void 0, this.caught);
        }
        return this._then(void 0, fn, void 0, void 0, void 0, this.caught);
    };
    
    Promise.prototype.then =
    function Promise$then(didFulfill, didReject, didProgress) {
        return this._then(didFulfill, didReject, didProgress,
            void 0, void 0, this.then);
    };
    
    
    Promise.prototype.done =
    function Promise$done(didFulfill, didReject, didProgress) {
        var promise = this._then(didFulfill, didReject, didProgress,
            void 0, void 0, this.done);
        promise._setIsFinal();
    };
    
    Promise.prototype.spread = function Promise$spread(didFulfill, didReject) {
        return this._then(didFulfill, didReject, void 0,
            APPLY, void 0, this.spread);
    };
    
    Promise.prototype.isFulfilled = function Promise$isFulfilled() {
        return (this._bitField & 268435456) > 0;
    };
    
    
    Promise.prototype.isRejected = function Promise$isRejected() {
        return (this._bitField & 134217728) > 0;
    };
    
    Promise.prototype.isPending = function Promise$isPending() {
        return !this.isResolved();
    };
    
    
    Promise.prototype.isResolved = function Promise$isResolved() {
        return (this._bitField & 402653184) > 0;
    };
    
    
    Promise.prototype.isCancellable = function Promise$isCancellable() {
        return !this.isResolved() &&
            this._cancellable();
    };
    
    Promise.prototype.toJSON = function Promise$toJSON() {
        var ret = {
            isFulfilled: false,
            isRejected: false,
            fulfillmentValue: void 0,
            rejectionReason: void 0
        };
        if (this.isFulfilled()) {
            ret.fulfillmentValue = this._settledValue;
            ret.isFulfilled = true;
        }
        else if (this.isRejected()) {
            ret.rejectionReason = this._settledValue;
            ret.isRejected = true;
        }
        return ret;
    };
    
    Promise.prototype.all = function Promise$all() {
        return Promise$_all(this, true, this.all);
    };
    
    
    Promise.is = isPromise;
    
    function Promise$_all(promises, useBound, caller) {
        return Promise$_CreatePromiseArray(
            promises,
            PromiseArray,
            caller,
            useBound === true && promises._isBound()
                ? promises._boundTo
                : void 0
       ).promise();
    }
    Promise.all = function Promise$All(promises) {
        return Promise$_all(promises, false, Promise.all);
    };
    
    Promise.join = function Promise$Join() {
        var $_len = arguments.length;var args = new Array($_len); for(var $_i = 0; $_i < $_len; ++$_i) {args[$_i] = arguments[$_i];}
        return Promise$_CreatePromiseArray(
            args, PromiseArray, Promise.join, void 0).promise();
    };
    
    Promise.resolve = Promise.fulfilled =
    function Promise$Resolve(value, caller) {
        var ret = new Promise(INTERNAL);
        if (debugging) ret._setTrace(typeof caller === "function"
            ? caller
            : Promise.resolve, void 0);
        if (ret._tryFollow(value)) {
            return ret;
        }
        ret._cleanValues();
        ret._setFulfilled();
        ret._settledValue = value;
        return ret;
    };
    
    Promise.reject = Promise.rejected = function Promise$Reject(reason) {
        var ret = new Promise(INTERNAL);
        if (debugging) ret._setTrace(Promise.reject, void 0);
        markAsOriginatingFromRejection(reason);
        ret._cleanValues();
        ret._setRejected();
        ret._settledValue = reason;
        if (!canAttach(reason)) {
            var trace = new Error(reason + "");
            ret._setCarriedStackTrace(trace);
        }
        ret._ensurePossibleRejectionHandled();
        return ret;
    };
    
    Promise.prototype.error = function Promise$_error(fn) {
        return this.caught(originatesFromRejection, fn);
    };
    
    Promise.prototype._resolveFromSyncValue =
    function Promise$_resolveFromSyncValue(value, caller) {
        if (value === errorObj) {
            this._cleanValues();
            this._setRejected();
            this._settledValue = value.e;
            this._ensurePossibleRejectionHandled();
        }
        else {
            var maybePromise = Promise._cast(value, caller, void 0);
            if (maybePromise instanceof Promise) {
                this._follow(maybePromise);
            }
            else {
                this._cleanValues();
                this._setFulfilled();
                this._settledValue = value;
            }
        }
    };
    
    Promise.method = function Promise$_Method(fn) {
        if (typeof fn !== "function") {
            throw new TypeError("fn must be a function");
        }
        return function Promise$_method() {
            var value;
            switch(arguments.length) {
            case 0: value = tryCatch1(fn, this, void 0); break;
            case 1: value = tryCatch1(fn, this, arguments[0]); break;
            case 2: value = tryCatch2(fn, this, arguments[0], arguments[1]); break;
            default:
                var $_len = arguments.length;var args = new Array($_len); for(var $_i = 0; $_i < $_len; ++$_i) {args[$_i] = arguments[$_i];}
                value = tryCatchApply(fn, args, this); break;
            }
            var ret = new Promise(INTERNAL);
            if (debugging) ret._setTrace(Promise$_method, void 0);
            ret._resolveFromSyncValue(value, Promise$_method);
            return ret;
        };
    };
    
    Promise.attempt = Promise["try"] = function Promise$_Try(fn, args, ctx) {
    
        if (typeof fn !== "function") {
            return apiRejection("fn must be a function");
        }
        var value = isArray(args)
            ? tryCatchApply(fn, args, ctx)
            : tryCatch1(fn, ctx, args);
    
        var ret = new Promise(INTERNAL);
        if (debugging) ret._setTrace(Promise.attempt, void 0);
        ret._resolveFromSyncValue(value, Promise.attempt);
        return ret;
    };
    
    Promise.defer = Promise.pending = function Promise$Defer(caller) {
        var promise = new Promise(INTERNAL);
        if (debugging) promise._setTrace(typeof caller === "function"
                                  ? caller : Promise.defer, void 0);
        return new PromiseResolver(promise);
    };
    
    Promise.bind = function Promise$Bind(thisArg) {
        var ret = new Promise(INTERNAL);
        if (debugging) ret._setTrace(Promise.bind, void 0);
        ret._setFulfilled();
        ret._setBoundTo(thisArg);
        return ret;
    };
    
    Promise.cast = function Promise$_Cast(obj, caller) {
        if (typeof caller !== "function") {
            caller = Promise.cast;
        }
        var ret = Promise._cast(obj, caller, void 0);
        if (!(ret instanceof Promise)) {
            return Promise.resolve(ret, caller);
        }
        return ret;
    };
    
    Promise.onPossiblyUnhandledRejection =
    function Promise$OnPossiblyUnhandledRejection(fn) {
        if (typeof fn === "function") {
            CapturedTrace.possiblyUnhandledRejection = fn;
        }
        else {
            CapturedTrace.possiblyUnhandledRejection = void 0;
        }
    };
    
    var debugging = false || !!(
        typeof process !== "undefined" &&
        typeof process.execPath === "string" &&
        typeof process.env === "object" &&
        (process.env["BLUEBIRD_DEBUG"] ||
            process.env["NODE_ENV"] === "development")
    );
    
    
    Promise.longStackTraces = function Promise$LongStackTraces() {
        if (async.haveItemsQueued() &&
            debugging === false
       ) {
            throw new Error("cannot enable long stack traces after promises have been created");
        }
        debugging = CapturedTrace.isSupported();
    };
    
    Promise.hasLongStackTraces = function Promise$HasLongStackTraces() {
        return debugging && CapturedTrace.isSupported();
    };
    
    Promise.prototype._setProxyHandlers =
    function Promise$_setProxyHandlers(receiver, promiseSlotValue) {
        var index = this._length();
    
        if (index >= 1048575 - 5) {
            index = 0;
            this._setLength(0);
        }
        if (index === 0) {
            this._promise0 = promiseSlotValue;
            this._receiver0 = receiver;
        }
        else {
            var i = index - 5;
            this[i + 3] = promiseSlotValue;
            this[i + 4] = receiver;
            this[i + 0] =
            this[i + 1] =
            this[i + 2] = void 0;
        }
        this._setLength(index + 5);
    };
    
    Promise.prototype._proxyPromiseArray =
    function Promise$_proxyPromiseArray(promiseArray, index) {
        this._setProxyHandlers(promiseArray, index);
    };
    
    Promise.prototype._proxyPromise = function Promise$_proxyPromise(promise) {
        promise._setProxied();
        this._setProxyHandlers(promise, -1);
    };
    
    Promise.prototype._then =
    function Promise$_then(
        didFulfill,
        didReject,
        didProgress,
        receiver,
        internalData,
        caller
    ) {
        var haveInternalData = internalData !== void 0;
        var ret = haveInternalData ? internalData : new Promise(INTERNAL);
    
        if (debugging && !haveInternalData) {
            var haveSameContext = this._peekContext() === this._traceParent;
            ret._traceParent = haveSameContext ? this._traceParent : this;
            ret._setTrace(typeof caller === "function"
                    ? caller
                    : this._then, this);
        }
    
        if (!haveInternalData && this._isBound()) {
            ret._setBoundTo(this._boundTo);
        }
    
        var callbackIndex =
            this._addCallbacks(didFulfill, didReject, didProgress, ret, receiver);
    
        if (!haveInternalData && this._cancellable()) {
            ret._setCancellable();
            ret._cancellationParent = this;
        }
    
        if (this.isResolved()) {
            async.invoke(this._queueSettleAt, this, callbackIndex);
        }
    
        return ret;
    };
    
    Promise.prototype._length = function Promise$_length() {
        return this._bitField & 1048575;
    };
    
    Promise.prototype._isFollowingOrFulfilledOrRejected =
    function Promise$_isFollowingOrFulfilledOrRejected() {
        return (this._bitField & 939524096) > 0;
    };
    
    Promise.prototype._isFollowing = function Promise$_isFollowing() {
        return (this._bitField & 536870912) === 536870912;
    };
    
    Promise.prototype._setLength = function Promise$_setLength(len) {
        this._bitField = (this._bitField & -1048576) |
            (len & 1048575);
    };
    
    Promise.prototype._setFulfilled = function Promise$_setFulfilled() {
        this._bitField = this._bitField | 268435456;
    };
    
    Promise.prototype._setRejected = function Promise$_setRejected() {
        this._bitField = this._bitField | 134217728;
    };
    
    Promise.prototype._setFollowing = function Promise$_setFollowing() {
        this._bitField = this._bitField | 536870912;
    };
    
    Promise.prototype._setIsFinal = function Promise$_setIsFinal() {
        this._bitField = this._bitField | 33554432;
    };
    
    Promise.prototype._isFinal = function Promise$_isFinal() {
        return (this._bitField & 33554432) > 0;
    };
    
    Promise.prototype._cancellable = function Promise$_cancellable() {
        return (this._bitField & 67108864) > 0;
    };
    
    Promise.prototype._setCancellable = function Promise$_setCancellable() {
        this._bitField = this._bitField | 67108864;
    };
    
    Promise.prototype._unsetCancellable = function Promise$_unsetCancellable() {
        this._bitField = this._bitField & (~67108864);
    };
    
    Promise.prototype._setRejectionIsUnhandled =
    function Promise$_setRejectionIsUnhandled() {
        this._bitField = this._bitField | 2097152;
    };
    
    Promise.prototype._unsetRejectionIsUnhandled =
    function Promise$_unsetRejectionIsUnhandled() {
        this._bitField = this._bitField & (~2097152);
    };
    
    Promise.prototype._isRejectionUnhandled =
    function Promise$_isRejectionUnhandled() {
        return (this._bitField & 2097152) > 0;
    };
    
    Promise.prototype._setCarriedStackTrace =
    function Promise$_setCarriedStackTrace(capturedTrace) {
        this._bitField = this._bitField | 1048576;
        this._fulfillmentHandler0 = capturedTrace;
    };
    
    Promise.prototype._unsetCarriedStackTrace =
    function Promise$_unsetCarriedStackTrace() {
        this._bitField = this._bitField & (~1048576);
        this._fulfillmentHandler0 = void 0;
    };
    
    Promise.prototype._isCarryingStackTrace =
    function Promise$_isCarryingStackTrace() {
        return (this._bitField & 1048576) > 0;
    };
    
    Promise.prototype._getCarriedStackTrace =
    function Promise$_getCarriedStackTrace() {
        return this._isCarryingStackTrace()
            ? this._fulfillmentHandler0
            : void 0;
    };
    
    Promise.prototype._receiverAt = function Promise$_receiverAt(index) {
        var ret;
        if (index === 0) {
            ret = this._receiver0;
        }
        else {
            ret = this[index + 4 - 5];
        }
        if (this._isBound() && ret === void 0) {
            return this._boundTo;
        }
        return ret;
    };
    
    Promise.prototype._promiseAt = function Promise$_promiseAt(index) {
        if (index === 0) return this._promise0;
        return this[index + 3 - 5];
    };
    
    Promise.prototype._fulfillmentHandlerAt =
    function Promise$_fulfillmentHandlerAt(index) {
        if (index === 0) return this._fulfillmentHandler0;
        return this[index + 0 - 5];
    };
    
    Promise.prototype._rejectionHandlerAt =
    function Promise$_rejectionHandlerAt(index) {
        if (index === 0) return this._rejectionHandler0;
        return this[index + 1 - 5];
    };
    
    Promise.prototype._unsetAt = function Promise$_unsetAt(index) {
         if (index === 0) {
            this._rejectionHandler0 =
            this._progressHandler0 =
            this._promise0 =
            this._receiver0 = void 0;
            if (!this._isCarryingStackTrace()) {
                this._fulfillmentHandler0 = void 0;
            }
        }
        else {
            this[index - 5 + 0] =
            this[index - 5 + 1] =
            this[index - 5 + 2] =
            this[index - 5 + 3] =
            this[index - 5 + 4] = void 0;
        }
    };
    
    Promise.prototype._resolveFromResolver =
    function Promise$_resolveFromResolver(resolver) {
        var promise = this;
        var localDebugging = debugging;
        if (localDebugging) {
            this._setTrace(this._resolveFromResolver, void 0);
            this._pushContext();
        }
        function Promise$_resolver(val) {
            if (promise._tryFollow(val)) {
                return;
            }
            promise._fulfill(val);
        }
        function Promise$_rejecter(val) {
            var trace = canAttach(val) ? val : new Error(val + "");
            promise._attachExtraTrace(trace);
            markAsOriginatingFromRejection(val);
            promise._reject(val, trace === val ? void 0 : trace);
        }
        var r = tryCatch2(resolver, void 0, Promise$_resolver, Promise$_rejecter);
        if (localDebugging) this._popContext();
    
        if (r !== void 0 && r === errorObj) {
            var trace = canAttach(r.e) ? r.e : new Error(r.e + "");
            promise._reject(r.e, trace);
        }
    };
    
    Promise.prototype._addCallbacks = function Promise$_addCallbacks(
        fulfill,
        reject,
        progress,
        promise,
        receiver
    ) {
        var index = this._length();
    
        if (index >= 1048575 - 5) {
            index = 0;
            this._setLength(0);
        }
    
        if (index === 0) {
            this._promise0 = promise;
            if (receiver !== void 0) this._receiver0 = receiver;
            if (typeof fulfill === "function" && !this._isCarryingStackTrace())
                this._fulfillmentHandler0 = fulfill;
            if (typeof reject === "function") this._rejectionHandler0 = reject;
            if (typeof progress === "function") this._progressHandler0 = progress;
        }
        else {
            var i = index - 5;
            this[i + 3] = promise;
            this[i + 4] = receiver;
            this[i + 0] = typeof fulfill === "function"
                                                ? fulfill : void 0;
            this[i + 1] = typeof reject === "function"
                                                ? reject : void 0;
            this[i + 2] = typeof progress === "function"
                                                ? progress : void 0;
        }
        this._setLength(index + 5);
        return index;
    };
    
    
    
    Promise.prototype._setBoundTo = function Promise$_setBoundTo(obj) {
        if (obj !== void 0) {
            this._bitField = this._bitField | 8388608;
            this._boundTo = obj;
        }
        else {
            this._bitField = this._bitField & (~8388608);
        }
    };
    
    Promise.prototype._isBound = function Promise$_isBound() {
        return (this._bitField & 8388608) === 8388608;
    };
    
    Promise.prototype._spreadSlowCase =
    function Promise$_spreadSlowCase(targetFn, promise, values, boundTo) {
        var promiseForAll =
                Promise$_CreatePromiseArray
                    (values, PromiseArray, this._spreadSlowCase, boundTo)
                .promise()
                ._then(function() {
                    return targetFn.apply(boundTo, arguments);
                }, void 0, void 0, APPLY, void 0, this._spreadSlowCase);
    
        promise._follow(promiseForAll);
    };
    
    Promise.prototype._callSpread =
    function Promise$_callSpread(handler, promise, value, localDebugging) {
        var boundTo = this._isBound() ? this._boundTo : void 0;
        if (isArray(value)) {
            var caller = this._settlePromiseFromHandler;
            for (var i = 0, len = value.length; i < len; ++i) {
                if (isPromise(Promise._cast(value[i], caller, void 0))) {
                    this._spreadSlowCase(handler, promise, value, boundTo);
                    return;
                }
            }
        }
        if (localDebugging) promise._pushContext();
        return tryCatchApply(handler, value, boundTo);
    };
    
    Promise.prototype._callHandler =
    function Promise$_callHandler(
        handler, receiver, promise, value, localDebugging) {
        var x;
        if (receiver === APPLY && !this.isRejected()) {
            x = this._callSpread(handler, promise, value, localDebugging);
        }
        else {
            if (localDebugging) promise._pushContext();
            x = tryCatch1(handler, receiver, value);
        }
        if (localDebugging) promise._popContext();
        return x;
    };
    
    Promise.prototype._settlePromiseFromHandler =
    function Promise$_settlePromiseFromHandler(
        handler, receiver, value, promise
    ) {
        if (!isPromise(promise)) {
            handler.call(receiver, value, promise);
            return;
        }
    
        var localDebugging = debugging;
        var x = this._callHandler(handler, receiver,
                                    promise, value, localDebugging);
    
        if (promise._isFollowing()) return;
    
        if (x === errorObj || x === promise || x === NEXT_FILTER) {
            var err = x === promise
                        ? makeSelfResolutionError()
                        : x.e;
            var trace = canAttach(err) ? err : new Error(err + "");
            if (x !== NEXT_FILTER) promise._attachExtraTrace(trace);
            promise._rejectUnchecked(err, trace);
        }
        else {
            var castValue = Promise._cast(x,
                        localDebugging ? this._settlePromiseFromHandler : void 0,
                        promise);
    
            if (isPromise(castValue)) {
                if (castValue.isRejected() &&
                    !castValue._isCarryingStackTrace() &&
                    !canAttach(castValue._settledValue)) {
                    var trace = new Error(castValue._settledValue + "");
                    promise._attachExtraTrace(trace);
                    castValue._setCarriedStackTrace(trace);
                }
                promise._follow(castValue);
                if (castValue._cancellable()) {
                    promise._cancellationParent = castValue;
                    promise._setCancellable();
                }
            }
            else {
                promise._fulfillUnchecked(x);
            }
        }
    };
    
    Promise.prototype._follow =
    function Promise$_follow(promise) {
        this._setFollowing();
    
        if (promise.isPending()) {
            if (promise._cancellable() ) {
                this._cancellationParent = promise;
                this._setCancellable();
            }
            promise._proxyPromise(this);
        }
        else if (promise.isFulfilled()) {
            this._fulfillUnchecked(promise._settledValue);
        }
        else {
            this._rejectUnchecked(promise._settledValue,
                promise._getCarriedStackTrace());
        }
    
        if (promise._isRejectionUnhandled()) promise._unsetRejectionIsUnhandled();
    
        if (debugging &&
            promise._traceParent == null) {
            promise._traceParent = this;
        }
    };
    
    Promise.prototype._tryFollow =
    function Promise$_tryFollow(value) {
        if (this._isFollowingOrFulfilledOrRejected() ||
            value === this) {
            return false;
        }
        var maybePromise = Promise._cast(value, this._tryFollow, void 0);
        if (!isPromise(maybePromise)) {
            return false;
        }
        this._follow(maybePromise);
        return true;
    };
    
    Promise.prototype._resetTrace = function Promise$_resetTrace(caller) {
        if (debugging) {
            var context = this._peekContext();
            var isTopLevel = context === void 0;
            this._trace = new CapturedTrace(
                typeof caller === "function"
                ? caller
                : this._resetTrace,
                isTopLevel
           );
        }
    };
    
    Promise.prototype._setTrace = function Promise$_setTrace(caller, parent) {
        if (debugging) {
            var context = this._peekContext();
            this._traceParent = context;
            var isTopLevel = context === void 0;
            if (parent !== void 0 &&
                parent._traceParent === context) {
                this._trace = parent._trace;
            }
            else {
                this._trace = new CapturedTrace(
                    typeof caller === "function"
                    ? caller
                    : this._setTrace,
                    isTopLevel
               );
            }
        }
        return this;
    };
    
    Promise.prototype._attachExtraTrace =
    function Promise$_attachExtraTrace(error) {
        if (debugging) {
            var promise = this;
            var stack = error.stack;
            stack = typeof stack === "string"
                ? stack.split("\n") : [];
            var headerLineCount = 1;
    
            while(promise != null &&
                promise._trace != null) {
                stack = CapturedTrace.combine(
                    stack,
                    promise._trace.stack.split("\n")
               );
                promise = promise._traceParent;
            }
    
            var max = Error.stackTraceLimit + headerLineCount;
            var len = stack.length;
            if (len  > max) {
                stack.length = max;
            }
            if (stack.length <= headerLineCount) {
                error.stack = "(No stack trace)";
            }
            else {
                error.stack = stack.join("\n");
            }
        }
    };
    
    Promise.prototype._cleanValues = function Promise$_cleanValues() {
        if (this._cancellable()) {
            this._cancellationParent = void 0;
        }
    };
    
    Promise.prototype._fulfill = function Promise$_fulfill(value) {
        if (this._isFollowingOrFulfilledOrRejected()) return;
        this._fulfillUnchecked(value);
    };
    
    Promise.prototype._reject =
    function Promise$_reject(reason, carriedStackTrace) {
        if (this._isFollowingOrFulfilledOrRejected()) return;
        this._rejectUnchecked(reason, carriedStackTrace);
    };
    
    Promise.prototype._settlePromiseAt = function Promise$_settlePromiseAt(index) {
        var handler = this.isFulfilled()
            ? this._fulfillmentHandlerAt(index)
            : this._rejectionHandlerAt(index);
    
        var value = this._settledValue;
        var receiver = this._receiverAt(index);
        var promise = this._promiseAt(index);
    
        if (typeof handler === "function") {
            this._settlePromiseFromHandler(handler, receiver, value, promise);
        }
        else {
            var done = false;
            var isFulfilled = this.isFulfilled();
            if (receiver !== void 0) {
                if (receiver instanceof Promise &&
                    receiver._isProxied()) {
                    receiver._unsetProxied();
    
                    if (isFulfilled) receiver._fulfillUnchecked(value);
                    else receiver._rejectUnchecked(value,
                        this._getCarriedStackTrace());
                    done = true;
                }
                else if (isPromiseArrayProxy(receiver, promise)) {
    
                    if (isFulfilled) receiver._promiseFulfilled(value, promise);
                    else receiver._promiseRejected(value, promise);
    
                    done = true;
                }
            }
    
            if (!done) {
    
                if (isFulfilled) promise._fulfill(value);
                else promise._reject(value, this._getCarriedStackTrace());
    
            }
        }
    
        if (index >= 256) {
            this._queueGC();
        }
    };
    
    Promise.prototype._isProxied = function Promise$_isProxied() {
        return (this._bitField & 4194304) === 4194304;
    };
    
    Promise.prototype._setProxied = function Promise$_setProxied() {
        this._bitField = this._bitField | 4194304;
    };
    
    Promise.prototype._unsetProxied = function Promise$_unsetProxied() {
        this._bitField = this._bitField & (~4194304);
    };
    
    Promise.prototype._isGcQueued = function Promise$_isGcQueued() {
        return (this._bitField & -1073741824) === -1073741824;
    };
    
    Promise.prototype._setGcQueued = function Promise$_setGcQueued() {
        this._bitField = this._bitField | -1073741824;
    };
    
    Promise.prototype._unsetGcQueued = function Promise$_unsetGcQueued() {
        this._bitField = this._bitField & (~-1073741824);
    };
    
    Promise.prototype._queueGC = function Promise$_queueGC() {
        if (this._isGcQueued()) return;
        this._setGcQueued();
        async.invokeLater(this._gc, this, void 0);
    };
    
    Promise.prototype._gc = function Promise$gc() {
        var len = this._length();
        this._unsetAt(0);
        for (var i = 0; i < len; i++) {
            delete this[i];
        }
        this._setLength(0);
        this._unsetGcQueued();
    };
    
    Promise.prototype._queueSettleAt = function Promise$_queueSettleAt(index) {
        if (this._isRejectionUnhandled()) this._unsetRejectionIsUnhandled();
        async.invoke(this._settlePromiseAt, this, index);
    };
    
    Promise.prototype._fulfillUnchecked =
    function Promise$_fulfillUnchecked(value) {
        if (!this.isPending()) return;
        if (value === this) {
            var err = makeSelfResolutionError();
            this._attachExtraTrace(err);
            return this._rejectUnchecked(err, void 0);
        }
        this._cleanValues();
        this._setFulfilled();
        this._settledValue = value;
        var len = this._length();
    
        if (len > 0) {
            async.invoke(this._fulfillPromises, this, len);
        }
    };
    
    Promise.prototype._rejectUncheckedCheckError =
    function Promise$_rejectUncheckedCheckError(reason) {
        var trace = canAttach(reason) ? reason : new Error(reason + "");
        this._rejectUnchecked(reason, trace === reason ? void 0 : trace);
    };
    
    Promise.prototype._rejectUnchecked =
    function Promise$_rejectUnchecked(reason, trace) {
        if (!this.isPending()) return;
        if (reason === this) {
            var err = makeSelfResolutionError();
            this._attachExtraTrace(err);
            return this._rejectUnchecked(err);
        }
        this._cleanValues();
        this._setRejected();
        this._settledValue = reason;
    
        if (this._isFinal()) {
            async.invokeLater(thrower, void 0, trace === void 0 ? reason : trace);
            return;
        }
        var len = this._length();
    
        if (trace !== void 0) this._setCarriedStackTrace(trace);
    
        if (len > 0) {
            async.invoke(this._rejectPromises, this, len);
        }
        else {
            this._ensurePossibleRejectionHandled();
        }
    };
    
    Promise.prototype._rejectPromises = function Promise$_rejectPromises(len) {
        len = this._length();
        for (var i = 0; i < len; i+= 5) {
            this._settlePromiseAt(i);
        }
        this._unsetCarriedStackTrace();
    };
    
    Promise.prototype._fulfillPromises = function Promise$_fulfillPromises(len) {
        len = this._length();
        for (var i = 0; i < len; i+= 5) {
            this._settlePromiseAt(i);
        }
    };
    
    Promise.prototype._ensurePossibleRejectionHandled =
    function Promise$_ensurePossibleRejectionHandled() {
        this._setRejectionIsUnhandled();
        if (CapturedTrace.possiblyUnhandledRejection !== void 0) {
            async.invokeLater(this._notifyUnhandledRejection, this, void 0);
        }
    };
    
    Promise.prototype._notifyUnhandledRejection =
    function Promise$_notifyUnhandledRejection() {
        if (this._isRejectionUnhandled()) {
            var reason = this._settledValue;
            var trace = this._getCarriedStackTrace();
    
            this._unsetRejectionIsUnhandled();
    
            if (trace !== void 0) {
                this._unsetCarriedStackTrace();
                reason = trace;
            }
            if (typeof CapturedTrace.possiblyUnhandledRejection === "function") {
                CapturedTrace.possiblyUnhandledRejection(reason, this);
            }
        }
    };
    
    var contextStack = [];
    Promise.prototype._peekContext = function Promise$_peekContext() {
        var lastIndex = contextStack.length - 1;
        if (lastIndex >= 0) {
            return contextStack[lastIndex];
        }
        return void 0;
    
    };
    
    Promise.prototype._pushContext = function Promise$_pushContext() {
        if (!debugging) return;
        contextStack.push(this);
    };
    
    Promise.prototype._popContext = function Promise$_popContext() {
        if (!debugging) return;
        contextStack.pop();
    };
    
    function Promise$_CreatePromiseArray(
        promises, PromiseArrayConstructor, caller, boundTo) {
    
        var list = null;
        if (isArray(promises)) {
            list = promises;
        }
        else {
            list = Promise._cast(promises, caller, void 0);
            if (list !== promises) {
                list._setBoundTo(boundTo);
            }
            else if (!isPromise(list)) {
                list = null;
            }
        }
        if (list !== null) {
            return new PromiseArrayConstructor(
                list,
                typeof caller === "function"
                    ? caller
                    : Promise$_CreatePromiseArray,
                boundTo
           );
        }
        return {
            promise: function() {return apiRejection("expecting an array, a promise or a thenable");}
        };
    }
    
    var old = global.Promise;
    
    Promise.noConflict = function() {
        if (global.Promise === Promise) {
            global.Promise = old;
        }
        return Promise;
    };
    
    if (!CapturedTrace.isSupported()) {
        Promise.longStackTraces = function(){};
        debugging = false;
    }
    
    Promise._makeSelfResolutionError = makeSelfResolutionError;
    _dereq_("./finally.js")(Promise, NEXT_FILTER);
    _dereq_("./direct_resolve.js")(Promise);
    _dereq_("./thenables.js")(Promise, INTERNAL);
    Promise.RangeError = RangeError;
    Promise.CancellationError = CancellationError;
    Promise.TimeoutError = TimeoutError;
    Promise.TypeError = TypeError;
    Promise.RejectionError = RejectionError;
    _dereq_('./timers.js')(Promise,INTERNAL);
    _dereq_('./synchronous_inspection.js')(Promise);
    _dereq_('./any.js')(Promise,Promise$_CreatePromiseArray,PromiseArray);
    _dereq_('./race.js')(Promise,INTERNAL);
    _dereq_('./call_get.js')(Promise);
    _dereq_('./filter.js')(Promise,Promise$_CreatePromiseArray,PromiseArray,apiRejection);
    _dereq_('./generators.js')(Promise,apiRejection,INTERNAL);
    _dereq_('./map.js')(Promise,Promise$_CreatePromiseArray,PromiseArray,apiRejection);
    _dereq_('./nodeify.js')(Promise);
    _dereq_('./promisify.js')(Promise,INTERNAL);
    _dereq_('./props.js')(Promise,PromiseArray);
    _dereq_('./reduce.js')(Promise,Promise$_CreatePromiseArray,PromiseArray,apiRejection,INTERNAL);
    _dereq_('./settle.js')(Promise,Promise$_CreatePromiseArray,PromiseArray);
    _dereq_('./some.js')(Promise,Promise$_CreatePromiseArray,PromiseArray,apiRejection);
    _dereq_('./progress.js')(Promise,isPromiseArrayProxy);
    _dereq_('./cancel.js')(Promise,INTERNAL);
    
    Promise.prototype = Promise.prototype;
    return Promise;
    
    };
    
    },{"./any.js":1,"./assert.js":2,"./async.js":3,"./call_get.js":5,"./cancel.js":6,"./captured_trace.js":7,"./catch_filter.js":8,"./direct_resolve.js":9,"./errors.js":10,"./errors_api_rejection":11,"./filter.js":13,"./finally.js":14,"./generators.js":15,"./global.js":16,"./map.js":17,"./nodeify.js":18,"./progress.js":19,"./promise_array.js":21,"./promise_resolver.js":23,"./promisify.js":25,"./props.js":27,"./race.js":29,"./reduce.js":30,"./settle.js":32,"./some.js":34,"./synchronous_inspection.js":36,"./thenables.js":37,"./timers.js":38,"./util.js":39}],21:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, INTERNAL) {
    var ASSERT = _dereq_("./assert.js");
    var canAttach = _dereq_("./errors.js").canAttach;
    var util = _dereq_("./util.js");
    var async = _dereq_("./async.js");
    var hasOwn = {}.hasOwnProperty;
    var isArray = util.isArray;
    
    function toResolutionValue(val) {
        switch(val) {
        case -1: return void 0;
        case -2: return [];
        case -3: return {};
        }
    }
    
    function PromiseArray(values, caller, boundTo) {
        var promise = this._promise = new Promise(INTERNAL);
        var parent = void 0;
        if (Promise.is(values)) {
            parent = values;
            if (values._cancellable()) {
                promise._setCancellable();
                promise._cancellationParent = values;
            }
            if (values._isBound()) {
                promise._setBoundTo(boundTo);
            }
        }
        promise._setTrace(caller, parent);
        this._values = values;
        this._length = 0;
        this._totalResolved = 0;
        this._init(void 0, -2);
    }
    PromiseArray.PropertiesPromiseArray = function() {};
    
    PromiseArray.prototype.length = function PromiseArray$length() {
        return this._length;
    };
    
    PromiseArray.prototype.promise = function PromiseArray$promise() {
        return this._promise;
    };
    
    PromiseArray.prototype._init =
    function PromiseArray$_init(_, resolveValueIfEmpty) {
        var values = this._values;
        if (Promise.is(values)) {
            if (values.isFulfilled()) {
                values = values._settledValue;
                if (!isArray(values)) {
                    var err = new Promise.TypeError("expecting an array, a promise or a thenable");
                    this.__hardReject__(err);
                    return;
                }
                this._values = values;
            }
            else if (values.isPending()) {
                values._then(
                    this._init,
                    this._reject,
                    void 0,
                    this,
                    resolveValueIfEmpty,
                    this.constructor
               );
                return;
            }
            else {
                this._reject(values._settledValue);
                return;
            }
        }
    
        if (values.length === 0) {
            this._resolve(toResolutionValue(resolveValueIfEmpty));
            return;
        }
        var len = values.length;
        var newLen = len;
        var newValues;
        if (this instanceof PromiseArray.PropertiesPromiseArray) {
            newValues = this._values;
        }
        else {
            newValues = new Array(len);
        }
        var isDirectScanNeeded = false;
        for (var i = 0; i < len; ++i) {
            var promise = values[i];
            if (promise === void 0 && !hasOwn.call(values, i)) {
                newLen--;
                continue;
            }
            var maybePromise = Promise._cast(promise, void 0, void 0);
            if (maybePromise instanceof Promise &&
                maybePromise.isPending()) {
                maybePromise._proxyPromiseArray(this, i);
            }
            else {
                isDirectScanNeeded = true;
            }
            newValues[i] = maybePromise;
        }
        if (newLen === 0) {
            if (resolveValueIfEmpty === -2) {
                this._resolve(newValues);
            }
            else {
                this._resolve(toResolutionValue(resolveValueIfEmpty));
            }
            return;
        }
        this._values = newValues;
        this._length = newLen;
        if (isDirectScanNeeded) {
            var scanMethod = newLen === len
                ? this._scanDirectValues
                : this._scanDirectValuesHoled;
            async.invoke(scanMethod, this, len);
        }
    };
    
    PromiseArray.prototype._settlePromiseAt =
    function PromiseArray$_settlePromiseAt(index) {
        var value = this._values[index];
        if (!Promise.is(value)) {
            this._promiseFulfilled(value, index);
        }
        else if (value.isFulfilled()) {
            this._promiseFulfilled(value._settledValue, index);
        }
        else if (value.isRejected()) {
            this._promiseRejected(value._settledValue, index);
        }
    };
    
    PromiseArray.prototype._scanDirectValuesHoled =
    function PromiseArray$_scanDirectValuesHoled(len) {
        for (var i = 0; i < len; ++i) {
            if (this._isResolved()) {
                break;
            }
            if (hasOwn.call(this._values, i)) {
                this._settlePromiseAt(i);
            }
        }
    };
    
    PromiseArray.prototype._scanDirectValues =
    function PromiseArray$_scanDirectValues(len) {
        for (var i = 0; i < len; ++i) {
            if (this._isResolved()) {
                break;
            }
            this._settlePromiseAt(i);
        }
    };
    
    PromiseArray.prototype._isResolved = function PromiseArray$_isResolved() {
        return this._values === null;
    };
    
    PromiseArray.prototype._resolve = function PromiseArray$_resolve(value) {
        this._values = null;
        this._promise._fulfill(value);
    };
    
    PromiseArray.prototype.__hardReject__ =
    PromiseArray.prototype._reject = function PromiseArray$_reject(reason) {
        this._values = null;
        var trace = canAttach(reason) ? reason : new Error(reason + "");
        this._promise._attachExtraTrace(trace);
        this._promise._reject(reason, trace);
    };
    
    PromiseArray.prototype._promiseProgressed =
    function PromiseArray$_promiseProgressed(progressValue, index) {
        if (this._isResolved()) return;
        this._promise._progress({
            index: index,
            value: progressValue
        });
    };
    
    
    PromiseArray.prototype._promiseFulfilled =
    function PromiseArray$_promiseFulfilled(value, index) {
        if (this._isResolved()) return;
        this._values[index] = value;
        var totalResolved = ++this._totalResolved;
        if (totalResolved >= this._length) {
            this._resolve(this._values);
        }
    };
    
    PromiseArray.prototype._promiseRejected =
    function PromiseArray$_promiseRejected(reason, index) {
        if (this._isResolved()) return;
        this._totalResolved++;
        this._reject(reason);
    };
    
    return PromiseArray;
    };
    
    },{"./assert.js":2,"./async.js":3,"./errors.js":10,"./util.js":39}],22:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var TypeError = _dereq_("./errors.js").TypeError;
    
    function PromiseInspection(promise) {
        if (promise !== void 0) {
            this._bitField = promise._bitField;
            this._settledValue = promise.isResolved()
                ? promise._settledValue
                : void 0;
        }
        else {
            this._bitField = 0;
            this._settledValue = void 0;
        }
    }
    PromiseInspection.prototype.isFulfilled =
    function PromiseInspection$isFulfilled() {
        return (this._bitField & 268435456) > 0;
    };
    
    PromiseInspection.prototype.isRejected =
    function PromiseInspection$isRejected() {
        return (this._bitField & 134217728) > 0;
    };
    
    PromiseInspection.prototype.isPending = function PromiseInspection$isPending() {
        return (this._bitField & 402653184) === 0;
    };
    
    PromiseInspection.prototype.value = function PromiseInspection$value() {
        if (!this.isFulfilled()) {
            throw new TypeError("cannot get fulfillment value of a non-fulfilled promise");
        }
        return this._settledValue;
    };
    
    PromiseInspection.prototype.error = function PromiseInspection$error() {
        if (!this.isRejected()) {
            throw new TypeError("cannot get rejection reason of a non-rejected promise");
        }
        return this._settledValue;
    };
    
    module.exports = PromiseInspection;
    
    },{"./errors.js":10}],23:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var util = _dereq_("./util.js");
    var maybeWrapAsError = util.maybeWrapAsError;
    var errors = _dereq_("./errors.js");
    var TimeoutError = errors.TimeoutError;
    var RejectionError = errors.RejectionError;
    var async = _dereq_("./async.js");
    var haveGetters = util.haveGetters;
    var es5 = _dereq_("./es5.js");
    
    function isUntypedError(obj) {
        return obj instanceof Error &&
            es5.getPrototypeOf(obj) === Error.prototype;
    }
    
    function wrapAsRejectionError(obj) {
        var ret;
        if (isUntypedError(obj)) {
            ret = new RejectionError(obj);
        }
        else {
            ret = obj;
        }
        errors.markAsOriginatingFromRejection(ret);
        return ret;
    }
    
    function nodebackForPromise(promise) {
        function PromiseResolver$_callback(err, value) {
            if (promise === null) return;
    
            if (err) {
                var wrapped = wrapAsRejectionError(maybeWrapAsError(err));
                promise._attachExtraTrace(wrapped);
                promise._reject(wrapped);
            }
            else {
                if (arguments.length > 2) {
                    var $_len = arguments.length;var args = new Array($_len - 1); for(var $_i = 1; $_i < $_len; ++$_i) {args[$_i - 1] = arguments[$_i];}
                    promise._fulfill(args);
                }
                else {
                    promise._fulfill(value);
                }
            }
    
            promise = null;
        }
        return PromiseResolver$_callback;
    }
    
    
    var PromiseResolver;
    if (!haveGetters) {
        PromiseResolver = function PromiseResolver(promise) {
            this.promise = promise;
            this.asCallback = nodebackForPromise(promise);
            this.callback = this.asCallback;
        };
    }
    else {
        PromiseResolver = function PromiseResolver(promise) {
            this.promise = promise;
        };
    }
    if (haveGetters) {
        var prop = {
            get: function() {
                return nodebackForPromise(this.promise);
            }
        };
        es5.defineProperty(PromiseResolver.prototype, "asCallback", prop);
        es5.defineProperty(PromiseResolver.prototype, "callback", prop);
    }
    
    PromiseResolver._nodebackForPromise = nodebackForPromise;
    
    PromiseResolver.prototype.toString = function PromiseResolver$toString() {
        return "[object PromiseResolver]";
    };
    
    PromiseResolver.prototype.resolve =
    PromiseResolver.prototype.fulfill = function PromiseResolver$resolve(value) {
        var promise = this.promise;
        if (promise._tryFollow(value)) {
            return;
        }
        async.invoke(promise._fulfill, promise, value);
    };
    
    PromiseResolver.prototype.reject = function PromiseResolver$reject(reason) {
        var promise = this.promise;
        errors.markAsOriginatingFromRejection(reason);
        var trace = errors.canAttach(reason) ? reason : new Error(reason + "");
        promise._attachExtraTrace(trace);
        async.invoke(promise._reject, promise, reason);
        if (trace !== reason) {
            async.invoke(this._setCarriedStackTrace, this, trace);
        }
    };
    
    PromiseResolver.prototype.progress =
    function PromiseResolver$progress(value) {
        async.invoke(this.promise._progress, this.promise, value);
    };
    
    PromiseResolver.prototype.cancel = function PromiseResolver$cancel() {
        async.invoke(this.promise.cancel, this.promise, void 0);
    };
    
    PromiseResolver.prototype.timeout = function PromiseResolver$timeout() {
        this.reject(new TimeoutError("timeout"));
    };
    
    PromiseResolver.prototype.isResolved = function PromiseResolver$isResolved() {
        return this.promise.isResolved();
    };
    
    PromiseResolver.prototype.toJSON = function PromiseResolver$toJSON() {
        return this.promise.toJSON();
    };
    
    PromiseResolver.prototype._setCarriedStackTrace =
    function PromiseResolver$_setCarriedStackTrace(trace) {
        if (this.promise.isRejected()) {
            this.promise._setCarriedStackTrace(trace);
        }
    };
    
    module.exports = PromiseResolver;
    
    },{"./async.js":3,"./errors.js":10,"./es5.js":12,"./util.js":39}],24:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, INTERNAL) {
    var errors = _dereq_("./errors.js");
    var TypeError = errors.TypeError;
    var util = _dereq_("./util.js");
    var isArray = util.isArray;
    var errorObj = util.errorObj;
    var tryCatch1 = util.tryCatch1;
    
    function PromiseSpawn(generatorFunction, receiver, caller) {
        var promise = this._promise = new Promise(INTERNAL);
        promise._setTrace(caller, void 0);
        this._generatorFunction = generatorFunction;
        this._receiver = receiver;
        this._generator = void 0;
    }
    
    PromiseSpawn.prototype.promise = function PromiseSpawn$promise() {
        return this._promise;
    };
    
    PromiseSpawn.prototype._run = function PromiseSpawn$_run() {
        this._generator = this._generatorFunction.call(this._receiver);
        this._receiver =
            this._generatorFunction = void 0;
        this._next(void 0);
    };
    
    PromiseSpawn.prototype._continue = function PromiseSpawn$_continue(result) {
        if (result === errorObj) {
            this._generator = void 0;
            var trace = errors.canAttach(result.e)
                ? result.e : new Error(result.e + "");
            this._promise._attachExtraTrace(trace);
            this._promise._reject(result.e, trace);
            return;
        }
    
        var value = result.value;
        if (result.done === true) {
            this._generator = void 0;
            if (!this._promise._tryFollow(value)) {
                this._promise._fulfill(value);
            }
        }
        else {
            var maybePromise = Promise._cast(value, PromiseSpawn$_continue, void 0);
            if (!(maybePromise instanceof Promise)) {
                if (isArray(maybePromise)) {
                    maybePromise = Promise.all(maybePromise);
                }
                else {
                    this._throw(new TypeError(
                        "A value was yielded that could not be treated as a promise"
                   ));
                    return;
                }
            }
            maybePromise._then(
                this._next,
                this._throw,
                void 0,
                this,
                null,
                void 0
           );
        }
    };
    
    PromiseSpawn.prototype._throw = function PromiseSpawn$_throw(reason) {
        if (errors.canAttach(reason))
            this._promise._attachExtraTrace(reason);
        this._continue(
            tryCatch1(this._generator["throw"], this._generator, reason)
       );
    };
    
    PromiseSpawn.prototype._next = function PromiseSpawn$_next(value) {
        this._continue(
            tryCatch1(this._generator.next, this._generator, value)
       );
    };
    
    return PromiseSpawn;
    };
    
    },{"./errors.js":10,"./util.js":39}],25:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, INTERNAL) {
    var THIS = {};
    var util = _dereq_("./util.js");
    var es5 = _dereq_("./es5.js");
    var nodebackForPromise = _dereq_("./promise_resolver.js")
        ._nodebackForPromise;
    var withAppended = util.withAppended;
    var maybeWrapAsError = util.maybeWrapAsError;
    var canEvaluate = util.canEvaluate;
    var notEnumerableProp = util.notEnumerableProp;
    var deprecated = util.deprecated;
    var ASSERT = _dereq_("./assert.js");
    
    
    var roriginal = new RegExp("__beforePromisified__" + "$");
    var hasProp = {}.hasOwnProperty;
    function isPromisified(fn) {
        return fn.__isPromisified__ === true;
    }
    var inheritedMethods = (function() {
        if (es5.isES5) {
            var create = Object.create;
            var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
            return function(cur) {
                var original = cur;
                var ret = [];
                var visitedKeys = create(null);
                while (cur !== null) {
                    var keys = es5.keys(cur);
                    for (var i = 0, len = keys.length; i < len; ++i) {
                        var key = keys[i];
                        if (visitedKeys[key] ||
                            roriginal.test(key) ||
                            hasProp.call(original, key + "__beforePromisified__")
                       ) {
                            continue;
                        }
                        visitedKeys[key] = true;
                        var desc = getOwnPropertyDescriptor(cur, key);
                        if (desc != null &&
                            typeof desc.value === "function" &&
                            !isPromisified(desc.value)) {
                            ret.push(key, desc.value);
                        }
                    }
                    cur = es5.getPrototypeOf(cur);
                }
                return ret;
            };
        }
        else {
            return function(obj) {
                var ret = [];
                /*jshint forin:false */
                for (var key in obj) {
                    if (roriginal.test(key) ||
                        hasProp.call(obj, key + "__beforePromisified__")) {
                        continue;
                    }
                    var fn = obj[key];
                    if (typeof fn === "function" &&
                        !isPromisified(fn)) {
                        ret.push(key, fn);
                    }
                }
                return ret;
            };
        }
    })();
    
    function switchCaseArgumentOrder(likelyArgumentCount) {
        var ret = [likelyArgumentCount];
        var min = Math.max(0, likelyArgumentCount - 1 - 5);
        for(var i = likelyArgumentCount - 1; i >= min; --i) {
            if (i === likelyArgumentCount) continue;
            ret.push(i);
        }
        for(var i = likelyArgumentCount + 1; i <= 5; ++i) {
            ret.push(i);
        }
        return ret;
    }
    
    function parameterDeclaration(parameterCount) {
        var ret = new Array(parameterCount);
        for(var i = 0; i < ret.length; ++i) {
            ret[i] = "_arg" + i;
        }
        return ret.join(", ");
    }
    
    function parameterCount(fn) {
        if (typeof fn.length === "number") {
            return Math.max(Math.min(fn.length, 1023 + 1), 0);
        }
        return 0;
    }
    
    function propertyAccess(id) {
        var rident = /^[a-z$_][a-z$_0-9]*$/i;
    
        if (rident.test(id)) {
            return "." + id;
        }
        else return "['" + id.replace(/(['\\])/g, "\\$1") + "']";
    }
    
    function makeNodePromisifiedEval(callback, receiver, originalName, fn) {
        var newParameterCount = Math.max(0, parameterCount(fn) - 1);
        var argumentOrder = switchCaseArgumentOrder(newParameterCount);
    
        var callbackName = (typeof originalName === "string" ?
            originalName + "Async" :
            "promisified");
    
        function generateCallForArgumentCount(count) {
            var args = new Array(count);
            for (var i = 0, len = args.length; i < len; ++i) {
                args[i] = "arguments[" + i + "]";
            }
            var comma = count > 0 ? "," : "";
    
            if (typeof callback === "string" &&
                receiver === THIS) {
                return "this" + propertyAccess(callback) + "("+args.join(",") +
                    comma +" fn);"+
                    "break;";
            }
            return (receiver === void 0
                ? "callback("+args.join(",")+ comma +" fn);"
                : "callback.call("+(receiver === THIS
                    ? "this"
                    : "receiver")+", "+args.join(",") + comma + " fn);") +
            "break;";
        }
    
        function generateArgumentSwitchCase() {
            var ret = "";
            for(var i = 0; i < argumentOrder.length; ++i) {
                ret += "case " + argumentOrder[i] +":" +
                    generateCallForArgumentCount(argumentOrder[i]);
            }
            ret += "default: var args = new Array(len + 1);" +
                "var i = 0;" +
                "for (var i = 0; i < len; ++i) { " +
                "   args[i] = arguments[i];" +
                "}" +
                "args[i] = fn;" +
    
                (typeof callback === "string"
                ? "this" + propertyAccess(callback) + ".apply("
                : "callback.apply(") +
    
                (receiver === THIS ? "this" : "receiver") +
                ", args); break;";
            return ret;
        }
    
        return new Function("Promise", "callback", "receiver",
                "withAppended", "maybeWrapAsError", "nodebackForPromise",
                "INTERNAL",
            "var ret = function " + callbackName +
            "(" + parameterDeclaration(newParameterCount) + ") {\"use strict\";" +
            "var len = arguments.length;" +
            "var promise = new Promise(INTERNAL);"+
            "promise._setTrace(" + callbackName + ", void 0);" +
            "var fn = nodebackForPromise(promise);"+
            "try {" +
            "switch(len) {" +
            generateArgumentSwitchCase() +
            "}" +
            "}" +
            "catch(e){ " +
            "var wrapped = maybeWrapAsError(e);" +
            "promise._attachExtraTrace(wrapped);" +
            "promise._reject(wrapped);" +
            "}" +
            "return promise;" +
            "" +
            "}; ret.__isPromisified__ = true; return ret;"
       )(Promise, callback, receiver, withAppended,
            maybeWrapAsError, nodebackForPromise, INTERNAL);
    }
    
    function makeNodePromisifiedClosure(callback, receiver) {
        function promisified() {
            var _receiver = receiver;
            if (receiver === THIS) _receiver = this;
            if (typeof callback === "string") {
                callback = _receiver[callback];
            }
            var promise = new Promise(INTERNAL);
            promise._setTrace(promisified, void 0);
            var fn = nodebackForPromise(promise);
            try {
                callback.apply(_receiver, withAppended(arguments, fn));
            }
            catch(e) {
                var wrapped = maybeWrapAsError(e);
                promise._attachExtraTrace(wrapped);
                promise._reject(wrapped);
            }
            return promise;
        }
        promisified.__isPromisified__ = true;
        return promisified;
    }
    
    var makeNodePromisified = canEvaluate
        ? makeNodePromisifiedEval
        : makeNodePromisifiedClosure;
    
    function f(){}
    function _promisify(callback, receiver, isAll) {
        if (isAll) {
            var methods = inheritedMethods(callback);
            for (var i = 0, len = methods.length; i < len; i+= 2) {
                var key = methods[i];
                var fn = methods[i+1];
                var originalKey = key + "__beforePromisified__";
                var promisifiedKey = key + "Async";
                notEnumerableProp(callback, originalKey, fn);
                callback[promisifiedKey] =
                    makeNodePromisified(originalKey, THIS,
                        key, fn);
            }
            if (methods.length > 16) f.prototype = callback;
            return callback;
        }
        else {
            return makeNodePromisified(callback, receiver, void 0, callback);
        }
    }
    
    Promise.promisify = function Promise$Promisify(fn, receiver) {
        if (typeof fn === "object" && fn !== null) {
            deprecated("Promise.promisify for promisifying entire objects is deprecated. Use Promise.promisifyAll instead.");
            return _promisify(fn, receiver, true);
        }
        if (typeof fn !== "function") {
            throw new TypeError("fn must be a function");
        }
        if (isPromisified(fn)) {
            return fn;
        }
        return _promisify(
            fn,
            arguments.length < 2 ? THIS : receiver,
            false);
    };
    
    Promise.promisifyAll = function Promise$PromisifyAll(target) {
        if (typeof target !== "function" && typeof target !== "object") {
            throw new TypeError("the target of promisifyAll must be an object or a function");
        }
        return _promisify(target, void 0, true);
    };
    };
    
    
    },{"./assert.js":2,"./es5.js":12,"./promise_resolver.js":23,"./util.js":39}],26:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, PromiseArray) {
    var ASSERT = _dereq_("./assert.js");
    var util = _dereq_("./util.js");
    var inherits = util.inherits;
    var es5 = _dereq_("./es5.js");
    
    function PropertiesPromiseArray(obj, caller, boundTo) {
        var keys = es5.keys(obj);
        var values = new Array(keys.length);
        for (var i = 0, len = values.length; i < len; ++i) {
            values[i] = obj[keys[i]];
        }
        this.constructor$(values, caller, boundTo);
        if (!this._isResolved()) {
            for (var i = 0, len = keys.length; i < len; ++i) {
                values.push(keys[i]);
            }
        }
    }
    inherits(PropertiesPromiseArray, PromiseArray);
    
    PropertiesPromiseArray.prototype._init =
    function PropertiesPromiseArray$_init() {
        this._init$(void 0, -3) ;
    };
    
    PropertiesPromiseArray.prototype._promiseFulfilled =
    function PropertiesPromiseArray$_promiseFulfilled(value, index) {
        if (this._isResolved()) return;
        this._values[index] = value;
        var totalResolved = ++this._totalResolved;
        if (totalResolved >= this._length) {
            var val = {};
            var keyOffset = this.length();
            for (var i = 0, len = this.length(); i < len; ++i) {
                val[this._values[i + keyOffset]] = this._values[i];
            }
            this._resolve(val);
        }
    };
    
    PropertiesPromiseArray.prototype._promiseProgressed =
    function PropertiesPromiseArray$_promiseProgressed(value, index) {
        if (this._isResolved()) return;
    
        this._promise._progress({
            key: this._values[index + this.length()],
            value: value
        });
    };
    
    PromiseArray.PropertiesPromiseArray = PropertiesPromiseArray;
    
    return PropertiesPromiseArray;
    };
    
    },{"./assert.js":2,"./es5.js":12,"./util.js":39}],27:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, PromiseArray) {
        var PropertiesPromiseArray = _dereq_("./properties_promise_array.js")(
            Promise, PromiseArray);
        var util = _dereq_("./util.js");
        var apiRejection = _dereq_("./errors_api_rejection")(Promise);
        var isObject = util.isObject;
    
        function Promise$_Props(promises, useBound, caller) {
            var ret;
            var castValue = Promise._cast(promises, caller, void 0);
    
            if (!isObject(castValue)) {
                return apiRejection("cannot await properties of a non-object");
            }
            else if (Promise.is(castValue)) {
                ret = castValue._then(Promise.props, void 0, void 0,
                                void 0, void 0, caller);
            }
            else {
                ret = new PropertiesPromiseArray(
                    castValue,
                    caller,
                    useBound === true && castValue._isBound()
                                ? castValue._boundTo
                                : void 0
               ).promise();
                useBound = false;
            }
            if (useBound === true && castValue._isBound()) {
                ret._setBoundTo(castValue._boundTo);
            }
            return ret;
        }
    
        Promise.prototype.props = function Promise$props() {
            return Promise$_Props(this, true, this.props);
        };
    
        Promise.props = function Promise$Props(promises) {
            return Promise$_Props(promises, false, Promise.props);
        };
    };
    
    },{"./errors_api_rejection":11,"./properties_promise_array.js":26,"./util.js":39}],28:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var ASSERT = _dereq_("./assert.js");
    function arrayCopy(src, srcIndex, dst, dstIndex, len) {
        for (var j = 0; j < len; ++j) {
            dst[j + dstIndex] = src[j + srcIndex];
        }
    }
    
    function pow2AtLeast(n) {
        n = n >>> 0;
        n = n - 1;
        n = n | (n >> 1);
        n = n | (n >> 2);
        n = n | (n >> 4);
        n = n | (n >> 8);
        n = n | (n >> 16);
        return n + 1;
    }
    
    function getCapacity(capacity) {
        if (typeof capacity !== "number") return 16;
        return pow2AtLeast(
            Math.min(
                Math.max(16, capacity), 1073741824)
       );
    }
    
    function Queue(capacity) {
        this._capacity = getCapacity(capacity);
        this._length = 0;
        this._front = 0;
        this._makeCapacity();
    }
    
    Queue.prototype._willBeOverCapacity =
    function Queue$_willBeOverCapacity(size) {
        return this._capacity < size;
    };
    
    Queue.prototype._pushOne = function Queue$_pushOne(arg) {
        var length = this.length();
        this._checkCapacity(length + 1);
        var i = (this._front + length) & (this._capacity - 1);
        this[i] = arg;
        this._length = length + 1;
    };
    
    Queue.prototype.push = function Queue$push(fn, receiver, arg) {
        var length = this.length() + 3;
        if (this._willBeOverCapacity(length)) {
            this._pushOne(fn);
            this._pushOne(receiver);
            this._pushOne(arg);
            return;
        }
        var j = this._front + length - 3;
        this._checkCapacity(length);
        var wrapMask = this._capacity - 1;
        this[(j + 0) & wrapMask] = fn;
        this[(j + 1) & wrapMask] = receiver;
        this[(j + 2) & wrapMask] = arg;
        this._length = length;
    };
    
    Queue.prototype.shift = function Queue$shift() {
        var front = this._front,
            ret = this[front];
    
        this[front] = void 0;
        this._front = (front + 1) & (this._capacity - 1);
        this._length--;
        return ret;
    };
    
    Queue.prototype.length = function Queue$length() {
        return this._length;
    };
    
    Queue.prototype._makeCapacity = function Queue$_makeCapacity() {
        var len = this._capacity;
        for (var i = 0; i < len; ++i) {
            this[i] = void 0;
        }
    };
    
    Queue.prototype._checkCapacity = function Queue$_checkCapacity(size) {
        if (this._capacity < size) {
            this._resizeTo(this._capacity << 3);
        }
    };
    
    Queue.prototype._resizeTo = function Queue$_resizeTo(capacity) {
        var oldFront = this._front;
        var oldCapacity = this._capacity;
        var oldQueue = new Array(oldCapacity);
        var length = this.length();
    
        arrayCopy(this, 0, oldQueue, 0, oldCapacity);
        this._capacity = capacity;
        this._makeCapacity();
        this._front = 0;
        if (oldFront + length <= oldCapacity) {
            arrayCopy(oldQueue, oldFront, this, 0, length);
        }
        else {        var lengthBeforeWrapping =
                length - ((oldFront + length) & (oldCapacity - 1));
    
            arrayCopy(oldQueue, oldFront, this, 0, lengthBeforeWrapping);
            arrayCopy(oldQueue, 0, this, lengthBeforeWrapping,
                        length - lengthBeforeWrapping);
        }
    };
    
    module.exports = Queue;
    
    },{"./assert.js":2}],29:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, INTERNAL) {
        var apiRejection = _dereq_("./errors_api_rejection.js")(Promise);
        var isArray = _dereq_("./util.js").isArray;
    
        var raceLater = function Promise$_raceLater(promise) {
            return promise.then(function Promise$_lateRacer(array) {
                return Promise$_Race(array, Promise$_lateRacer, promise);
            });
        };
    
        var hasOwn = {}.hasOwnProperty;
        function Promise$_Race(promises, caller, parent) {
            var maybePromise = Promise._cast(promises, caller, void 0);
    
            if (Promise.is(maybePromise)) {
                return raceLater(maybePromise);
            }
            else if (!isArray(promises)) {
                return apiRejection("expecting an array, a promise or a thenable");
            }
    
            var ret = new Promise(INTERNAL);
            ret._setTrace(caller, parent);
            if (parent !== void 0) {
                if (parent._isBound()) {
                    ret._setBoundTo(parent._boundTo);
                }
                if (parent._cancellable()) {
                    ret._setCancellable();
                    ret._cancellationParent = parent;
                }
            }
            var fulfill = ret._fulfill;
            var reject = ret._reject;
            for (var i = 0, len = promises.length; i < len; ++i) {
                var val = promises[i];
    
                if (val === void 0 && !(hasOwn.call(promises, i))) {
                    continue;
                }
    
                Promise.cast(val)._then(
                    fulfill,
                    reject,
                    void 0,
                    ret,
                    null,
                    caller
               );
            }
            return ret;
        }
    
        Promise.race = function Promise$Race(promises) {
            return Promise$_Race(promises, Promise.race, void 0);
        };
    
        Promise.prototype.race = function Promise$race() {
            return Promise$_Race(this, this.race, void 0);
        };
    
    };
    
    },{"./errors_api_rejection.js":11,"./util.js":39}],30:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(
        Promise, Promise$_CreatePromiseArray,
        PromiseArray, apiRejection, INTERNAL) {
    
        var ASSERT = _dereq_("./assert.js");
    
        function Reduction(callback, index, accum, items, receiver) {
            this.promise = new Promise(INTERNAL);
            this.index = index;
            this.length = items.length;
            this.items = items;
            this.callback = callback;
            this.receiver = receiver;
            this.accum = accum;
        }
    
        Reduction.prototype.reject = function Reduction$reject(e) {
            this.promise._reject(e);
        };
    
        Reduction.prototype.fulfill = function Reduction$fulfill(value, index) {
            this.accum = value;
            this.index = index + 1;
            this.iterate();
        };
    
        Reduction.prototype.iterate = function Reduction$iterate() {
            var i = this.index;
            var len = this.length;
            var items = this.items;
            var result = this.accum;
            var receiver = this.receiver;
            var callback = this.callback;
            var iterate = this.iterate;
    
            for(; i < len; ++i) {
                result = Promise._cast(
                    callback.call(
                        receiver,
                        result,
                        items[i],
                        i,
                        len
                    ),
                    iterate,
                    void 0
                );
    
                if (result instanceof Promise) {
                    result._then(
                        this.fulfill, this.reject, void 0, this, i, iterate);
                    return;
                }
            }
            this.promise._fulfill(result);
        };
    
        function Promise$_reducer(fulfilleds, initialValue) {
            var fn = this;
            var receiver = void 0;
            if (typeof fn !== "function")  {
                receiver = fn.receiver;
                fn = fn.fn;
            }
            var len = fulfilleds.length;
            var accum = void 0;
            var startIndex = 0;
    
            if (initialValue !== void 0) {
                accum = initialValue;
                startIndex = 0;
            }
            else {
                startIndex = 1;
                if (len > 0) accum = fulfilleds[0];
            }
            var i = startIndex;
    
            if (i >= len) {
                return accum;
            }
    
            var reduction = new Reduction(fn, i, accum, fulfilleds, receiver);
            reduction.iterate();
            return reduction.promise;
        }
    
        function Promise$_unpackReducer(fulfilleds) {
            var fn = this.fn;
            var initialValue = this.initialValue;
            return Promise$_reducer.call(fn, fulfilleds, initialValue);
        }
    
        function Promise$_slowReduce(
            promises, fn, initialValue, useBound, caller) {
            return initialValue._then(function callee(initialValue) {
                return Promise$_Reduce(
                    promises, fn, initialValue, useBound, callee);
            }, void 0, void 0, void 0, void 0, caller);
        }
    
        function Promise$_Reduce(promises, fn, initialValue, useBound, caller) {
            if (typeof fn !== "function") {
                return apiRejection("fn must be a function");
            }
    
            if (useBound === true && promises._isBound()) {
                fn = {
                    fn: fn,
                    receiver: promises._boundTo
                };
            }
    
            if (initialValue !== void 0) {
                if (Promise.is(initialValue)) {
                    if (initialValue.isFulfilled()) {
                        initialValue = initialValue._settledValue;
                    }
                    else {
                        return Promise$_slowReduce(promises,
                            fn, initialValue, useBound, caller);
                    }
                }
    
                return Promise$_CreatePromiseArray(promises, PromiseArray, caller,
                    useBound === true && promises._isBound()
                        ? promises._boundTo
                        : void 0)
                    .promise()
                    ._then(Promise$_unpackReducer, void 0, void 0, {
                        fn: fn,
                        initialValue: initialValue
                    }, void 0, Promise.reduce);
            }
            return Promise$_CreatePromiseArray(promises, PromiseArray, caller,
                    useBound === true && promises._isBound()
                        ? promises._boundTo
                        : void 0).promise()
                ._then(Promise$_reducer, void 0, void 0, fn, void 0, caller);
        }
    
    
        Promise.reduce = function Promise$Reduce(promises, fn, initialValue) {
            return Promise$_Reduce(promises, fn,
                initialValue, false, Promise.reduce);
        };
    
        Promise.prototype.reduce = function Promise$reduce(fn, initialValue) {
            return Promise$_Reduce(this, fn, initialValue,
                                    true, this.reduce);
        };
    };
    
    },{"./assert.js":2}],31:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var global = _dereq_("./global.js");
    var ASSERT = _dereq_("./assert.js");
    var schedule;
    if (typeof process !== "undefined" && process !== null &&
        typeof process.cwd === "function" &&
        typeof process.nextTick === "function") {
        if (process.version.indexOf("v0.10.") === 0) {
            schedule = (function () {
                var domain = _dereq_("domain");
                var activeDomain = null;
                var callback = null;
                function Promise$_Scheduler() {
                    var fn = callback;
                    var domain = activeDomain;
                    activeDomain = null;
                    callback = null;
                    if (domain != null) domain.run(fn); else fn();
    
                }
                return function schedule(fn) {
                    activeDomain = domain.active;
                    callback = fn;
                    process.nextTick(Promise$_Scheduler);
                };
            })();
        } else {
            schedule = process.nextTick;
        }
    }
    else if ((typeof global.MutationObserver === "function" ||
            typeof global.WebkitMutationObserver === "function" ||
            typeof global.WebKitMutationObserver === "function") &&
            typeof document !== "undefined" &&
            typeof document.createElement === "function") {
    
    
        schedule = (function(){
            var MutationObserver = global.MutationObserver ||
                global.WebkitMutationObserver ||
                global.WebKitMutationObserver;
            var div = document.createElement("div");
            var queuedFn = void 0;
            var observer = new MutationObserver(
                function Promise$_Scheduler() {
                    var fn = queuedFn;
                    queuedFn = void 0;
                    fn();
                }
           );
            observer.observe(div, {
                attributes: true
            });
            return function Promise$_Scheduler(fn) {
                queuedFn = fn;
                div.setAttribute("class", "foo");
            };
    
        })();
    }
    else if (typeof global.postMessage === "function" &&
        typeof global.importScripts !== "function" &&
        typeof global.addEventListener === "function" &&
        typeof global.removeEventListener === "function") {
    
        var MESSAGE_KEY = "bluebird_message_key_" + Math.random();
        schedule = (function(){
            var queuedFn = void 0;
    
            function Promise$_Scheduler(e) {
                if (e.source === global &&
                    e.data === MESSAGE_KEY) {
                    var fn = queuedFn;
                    queuedFn = void 0;
                    fn();
                }
            }
    
            global.addEventListener("message", Promise$_Scheduler, false);
    
            return function Promise$_Scheduler(fn) {
                queuedFn = fn;
                global.postMessage(
                    MESSAGE_KEY, "*"
               );
            };
    
        })();
    }
    else if (typeof global.MessageChannel === "function") {
        schedule = (function(){
            var queuedFn = void 0;
    
            var channel = new global.MessageChannel();
            channel.port1.onmessage = function Promise$_Scheduler() {
                    var fn = queuedFn;
                    queuedFn = void 0;
                    fn();
            };
    
            return function Promise$_Scheduler(fn) {
                queuedFn = fn;
                channel.port2.postMessage(null);
            };
        })();
    }
    else if (global.setTimeout) {
        schedule = function Promise$_Scheduler(fn) {
            setTimeout(fn, 4);
        };
    }
    else {
        schedule = function Promise$_Scheduler(fn) {
            fn();
        };
    }
    
    module.exports = schedule;
    
    },{"./assert.js":2,"./global.js":16,"domain":40}],32:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports =
        function(Promise, Promise$_CreatePromiseArray, PromiseArray) {
    
        var SettledPromiseArray = _dereq_("./settled_promise_array.js")(
            Promise, PromiseArray);
    
        function Promise$_Settle(promises, useBound, caller) {
            return Promise$_CreatePromiseArray(
                promises,
                SettledPromiseArray,
                caller,
                useBound === true && promises._isBound()
                    ? promises._boundTo
                    : void 0
           ).promise();
        }
    
        Promise.settle = function Promise$Settle(promises) {
            return Promise$_Settle(promises, false, Promise.settle);
        };
    
        Promise.prototype.settle = function Promise$settle() {
            return Promise$_Settle(this, true, this.settle);
        };
    
    };
    
    },{"./settled_promise_array.js":33}],33:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, PromiseArray) {
    var ASSERT = _dereq_("./assert.js");
    var PromiseInspection = _dereq_("./promise_inspection.js");
    var util = _dereq_("./util.js");
    var inherits = util.inherits;
    function SettledPromiseArray(values, caller, boundTo) {
        this.constructor$(values, caller, boundTo);
    }
    inherits(SettledPromiseArray, PromiseArray);
    
    SettledPromiseArray.prototype._promiseResolved =
    function SettledPromiseArray$_promiseResolved(index, inspection) {
        this._values[index] = inspection;
        var totalResolved = ++this._totalResolved;
        if (totalResolved >= this._length) {
            this._resolve(this._values);
        }
    };
    
    SettledPromiseArray.prototype._promiseFulfilled =
    function SettledPromiseArray$_promiseFulfilled(value, index) {
        if (this._isResolved()) return;
        var ret = new PromiseInspection();
        ret._bitField = 268435456;
        ret._settledValue = value;
        this._promiseResolved(index, ret);
    };
    SettledPromiseArray.prototype._promiseRejected =
    function SettledPromiseArray$_promiseRejected(reason, index) {
        if (this._isResolved()) return;
        var ret = new PromiseInspection();
        ret._bitField = 134217728;
        ret._settledValue = reason;
        this._promiseResolved(index, ret);
    };
    
    return SettledPromiseArray;
    };
    
    },{"./assert.js":2,"./promise_inspection.js":22,"./util.js":39}],34:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports =
    function(Promise, Promise$_CreatePromiseArray, PromiseArray, apiRejection) {
    
        var SomePromiseArray = _dereq_("./some_promise_array.js")(PromiseArray);
        var ASSERT = _dereq_("./assert.js");
    
        function Promise$_Some(promises, howMany, useBound, caller) {
            if ((howMany | 0) !== howMany || howMany < 0) {
                return apiRejection("expecting a positive integer");
            }
            var ret = Promise$_CreatePromiseArray(
                promises,
                SomePromiseArray,
                caller,
                useBound === true && promises._isBound()
                    ? promises._boundTo
                    : void 0
           );
            var promise = ret.promise();
            if (promise.isRejected()) {
                return promise;
            }
            ret.setHowMany(howMany);
            ret.init();
            return promise;
        }
    
        Promise.some = function Promise$Some(promises, howMany) {
            return Promise$_Some(promises, howMany, false, Promise.some);
        };
    
        Promise.prototype.some = function Promise$some(count) {
            return Promise$_Some(this, count, true, this.some);
        };
    
    };
    
    },{"./assert.js":2,"./some_promise_array.js":35}],35:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function (PromiseArray) {
    var util = _dereq_("./util.js");
    var RangeError = _dereq_("./errors.js").RangeError;
    var inherits = util.inherits;
    var isArray = util.isArray;
    
    function SomePromiseArray(values, caller, boundTo) {
        this.constructor$(values, caller, boundTo);
        this._howMany = 0;
        this._unwrap = false;
        this._initialized = false;
    }
    inherits(SomePromiseArray, PromiseArray);
    
    SomePromiseArray.prototype._init = function SomePromiseArray$_init() {
        if (!this._initialized) {
            return;
        }
        if (this._howMany === 0) {
            this._resolve([]);
            return;
        }
        this._init$(void 0, -2);
        var isArrayResolved = isArray(this._values);
        this._holes = isArrayResolved ? this._values.length - this.length() : 0;
    
        if (!this._isResolved() &&
            isArrayResolved &&
            this._howMany > this._canPossiblyFulfill()) {
            var message = "(Promise.some) input array contains less than " +
                            this._howMany  + " promises";
            this._reject(new RangeError(message));
        }
    };
    
    SomePromiseArray.prototype.init = function SomePromiseArray$init() {
        this._initialized = true;
        this._init();
    };
    
    SomePromiseArray.prototype.setUnwrap = function SomePromiseArray$setUnwrap() {
        this._unwrap = true;
    };
    
    SomePromiseArray.prototype.howMany = function SomePromiseArray$howMany() {
        return this._howMany;
    };
    
    SomePromiseArray.prototype.setHowMany =
    function SomePromiseArray$setHowMany(count) {
        if (this._isResolved()) return;
        this._howMany = count;
    };
    
    SomePromiseArray.prototype._promiseFulfilled =
    function SomePromiseArray$_promiseFulfilled(value) {
        if (this._isResolved()) return;
        this._addFulfilled(value);
        if (this._fulfilled() === this.howMany()) {
            this._values.length = this.howMany();
            if (this.howMany() === 1 && this._unwrap) {
                this._resolve(this._values[0]);
            }
            else {
                this._resolve(this._values);
            }
        }
    
    };
    SomePromiseArray.prototype._promiseRejected =
    function SomePromiseArray$_promiseRejected(reason) {
        if (this._isResolved()) return;
        this._addRejected(reason);
        if (this.howMany() > this._canPossiblyFulfill()) {
            if (this._values.length === this.length()) {
                this._reject([]);
            }
            else {
                this._reject(this._values.slice(this.length() + this._holes));
            }
        }
    };
    
    SomePromiseArray.prototype._fulfilled = function SomePromiseArray$_fulfilled() {
        return this._totalResolved;
    };
    
    SomePromiseArray.prototype._rejected = function SomePromiseArray$_rejected() {
        return this._values.length - this.length() - this._holes;
    };
    
    SomePromiseArray.prototype._addRejected =
    function SomePromiseArray$_addRejected(reason) {
        this._values.push(reason);
    };
    
    SomePromiseArray.prototype._addFulfilled =
    function SomePromiseArray$_addFulfilled(value) {
        this._values[this._totalResolved++] = value;
    };
    
    SomePromiseArray.prototype._canPossiblyFulfill =
    function SomePromiseArray$_canPossiblyFulfill() {
        return this.length() - this._rejected();
    };
    
    return SomePromiseArray;
    };
    
    },{"./errors.js":10,"./util.js":39}],36:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise) {
        var PromiseInspection = _dereq_("./promise_inspection.js");
    
        Promise.prototype.inspect = function Promise$inspect() {
            return new PromiseInspection(this);
        };
    };
    
    },{"./promise_inspection.js":22}],37:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    module.exports = function(Promise, INTERNAL) {
        var ASSERT = _dereq_("./assert.js");
        var util = _dereq_("./util.js");
        var canAttach = _dereq_("./errors.js").canAttach;
        var errorObj = util.errorObj;
        var isObject = util.isObject;
    
        function getThen(obj) {
            try {
                return obj.then;
            }
            catch(e) {
                errorObj.e = e;
                return errorObj;
            }
        }
    
        function Promise$_Cast(obj, caller, originalPromise) {
            if (isObject(obj)) {
                if (obj instanceof Promise) {
                    return obj;
                }
                else if (isAnyBluebirdPromise(obj)) {
                    var ret = new Promise(INTERNAL);
                    ret._setTrace(caller, void 0);
                    obj._then(
                        ret._fulfillUnchecked,
                        ret._rejectUncheckedCheckError,
                        ret._progressUnchecked,
                        ret,
                        null,
                        void 0
                    );
                    ret._setFollowing();
                    return ret;
                }
                var then = getThen(obj);
                if (then === errorObj) {
                    caller = typeof caller === "function" ? caller : Promise$_Cast;
                    if (originalPromise !== void 0 && canAttach(then.e)) {
                        originalPromise._attachExtraTrace(then.e);
                    }
                    return Promise.reject(then.e, caller);
                }
                else if (typeof then === "function") {
                    caller = typeof caller === "function" ? caller : Promise$_Cast;
                    return Promise$_doThenable(obj, then, caller, originalPromise);
                }
            }
            return obj;
        }
    
        var hasProp = {}.hasOwnProperty;
        function isAnyBluebirdPromise(obj) {
            return hasProp.call(obj, "_promise0");
        }
    
        function Promise$_doThenable(x, then, caller, originalPromise) {
            var resolver = Promise.defer(caller);
            var called = false;
            try {
                then.call(
                    x,
                    Promise$_resolveFromThenable,
                    Promise$_rejectFromThenable,
                    Promise$_progressFromThenable
                );
            }
            catch(e) {
                if (!called) {
                    called = true;
                    var trace = canAttach(e) ? e : new Error(e + "");
                    if (originalPromise !== void 0) {
                        originalPromise._attachExtraTrace(trace);
                    }
                    resolver.promise._reject(e, trace);
                }
            }
            return resolver.promise;
    
            function Promise$_resolveFromThenable(y) {
                if (called) return;
                called = true;
    
                if (x === y) {
                    var e = Promise._makeSelfResolutionError();
                    if (originalPromise !== void 0) {
                        originalPromise._attachExtraTrace(e);
                    }
                    resolver.promise._reject(e, void 0);
                    return;
                }
                resolver.resolve(y);
            }
    
            function Promise$_rejectFromThenable(r) {
                if (called) return;
                called = true;
                var trace = canAttach(r) ? r : new Error(r + "");
                if (originalPromise !== void 0) {
                    originalPromise._attachExtraTrace(trace);
                }
                resolver.promise._reject(r, trace);
            }
    
            function Promise$_progressFromThenable(v) {
                if (called) return;
                var promise = resolver.promise;
                if (typeof promise._progress === "function") {
                    promise._progress(v);
                }
            }
        }
    
        Promise._cast = Promise$_Cast;
    };
    
    },{"./assert.js":2,"./errors.js":10,"./util.js":39}],38:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    
    var global = _dereq_("./global.js");
    var setTimeout = function(fn, time) {
        var $_len = arguments.length;var args = new Array($_len - 2); for(var $_i = 2; $_i < $_len; ++$_i) {args[$_i - 2] = arguments[$_i];}
        global.setTimeout(function() {
            fn.apply(void 0, args);
        }, time);
    };
    
    var pass = {};
    global.setTimeout( function(_) {
        if(_ === pass) {
            setTimeout = global.setTimeout;
        }
    }, 1, pass);
    
    module.exports = function(Promise, INTERNAL) {
        var util = _dereq_("./util.js");
        var ASSERT = _dereq_("./assert.js");
        var errors = _dereq_("./errors.js");
        var apiRejection = _dereq_("./errors_api_rejection")(Promise);
        var TimeoutError = Promise.TimeoutError;
    
        var afterTimeout = function Promise$_afterTimeout(promise, message, ms) {
            if (!promise.isPending()) return;
            if (typeof message !== "string") {
                message = "operation timed out after" + " " + ms + " ms"
            }
            var err = new TimeoutError(message);
            errors.markAsOriginatingFromRejection(err);
            promise._attachExtraTrace(err);
            promise._rejectUnchecked(err);
        };
    
        var afterDelay = function Promise$_afterDelay(value, promise) {
            promise._fulfill(value);
        };
    
        Promise.delay = function Promise$Delay(value, ms, caller) {
            if (ms === void 0) {
                ms = value;
                value = void 0;
            }
            ms = +ms;
            if (typeof caller !== "function") {
                caller = Promise.delay;
            }
            var maybePromise = Promise._cast(value, caller, void 0);
            var promise = new Promise(INTERNAL);
    
            if (Promise.is(maybePromise)) {
                if (maybePromise._isBound()) {
                    promise._setBoundTo(maybePromise._boundTo);
                }
                if (maybePromise._cancellable()) {
                    promise._setCancellable();
                    promise._cancellationParent = maybePromise;
                }
                promise._setTrace(caller, maybePromise);
                promise._follow(maybePromise);
                return promise.then(function(value) {
                    return Promise.delay(value, ms);
                });
            }
            else {
                promise._setTrace(caller, void 0);
                setTimeout(afterDelay, ms, value, promise);
            }
            return promise;
        };
    
        Promise.prototype.delay = function Promise$delay(ms) {
            return Promise.delay(this, ms, this.delay);
        };
    
        Promise.prototype.timeout = function Promise$timeout(ms, message) {
            ms = +ms;
    
            var ret = new Promise(INTERNAL);
            ret._setTrace(this.timeout, this);
    
            if (this._isBound()) ret._setBoundTo(this._boundTo);
            if (this._cancellable()) {
                ret._setCancellable();
                ret._cancellationParent = this;
            }
            ret._follow(this);
            setTimeout(afterTimeout, ms, ret, message, ms);
            return ret;
        };
    
    };
    
    },{"./assert.js":2,"./errors.js":10,"./errors_api_rejection":11,"./global.js":16,"./util.js":39}],39:[function(_dereq_,module,exports){
    /**
     * Copyright (c) 2014 Petka Antonov
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:</p>
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     * 
     */
    "use strict";
    var global = _dereq_("./global.js");
    var ASSERT = _dereq_("./assert.js");
    var es5 = _dereq_("./es5.js");
    var haveGetters = (function(){
        try {
            var o = {};
            es5.defineProperty(o, "f", {
                get: function () {
                    return 3;
                }
            });
            return o.f === 3;
        }
        catch (e) {
            return false;
        }
    
    })();
    
    var canEvaluate = (function() {
        if (typeof window !== "undefined" && window !== null &&
            typeof window.document !== "undefined" &&
            typeof navigator !== "undefined" && navigator !== null &&
            typeof navigator.appName === "string" &&
            window === global) {
            return false;
        }
        return true;
    })();
    
    function deprecated(msg) {
        if (typeof console !== "undefined" && console !== null &&
            typeof console.warn === "function") {
            console.warn("Bluebird: " + msg);
        }
    }
    
    var errorObj = {e: {}};
    function tryCatch1(fn, receiver, arg) {
        try {
            return fn.call(receiver, arg);
        }
        catch (e) {
            errorObj.e = e;
            return errorObj;
        }
    }
    
    function tryCatch2(fn, receiver, arg, arg2) {
        try {
            return fn.call(receiver, arg, arg2);
        }
        catch (e) {
            errorObj.e = e;
            return errorObj;
        }
    }
    
    function tryCatchApply(fn, args, receiver) {
        try {
            return fn.apply(receiver, args);
        }
        catch (e) {
            errorObj.e = e;
            return errorObj;
        }
    }
    
    var inherits = function(Child, Parent) {
        var hasProp = {}.hasOwnProperty;
    
        function T() {
            this.constructor = Child;
            this.constructor$ = Parent;
            for (var propertyName in Parent.prototype) {
                if (hasProp.call(Parent.prototype, propertyName) &&
                    propertyName.charAt(propertyName.length-1) !== "$"
               ) {
                    this[propertyName + "$"] = Parent.prototype[propertyName];
                }
            }
        }
        T.prototype = Parent.prototype;
        Child.prototype = new T();
        return Child.prototype;
    };
    
    function asString(val) {
        return typeof val === "string" ? val : ("" + val);
    }
    
    function isPrimitive(val) {
        return val == null || val === true || val === false ||
            typeof val === "string" || typeof val === "number";
    
    }
    
    function isObject(value) {
        return !isPrimitive(value);
    }
    
    function maybeWrapAsError(maybeError) {
        if (!isPrimitive(maybeError)) return maybeError;
    
        return new Error(asString(maybeError));
    }
    
    function withAppended(target, appendee) {
        var len = target.length;
        var ret = new Array(len + 1);
        var i;
        for (i = 0; i < len; ++i) {
            ret[i] = target[i];
        }
        ret[i] = appendee;
        return ret;
    }
    
    
    function notEnumerableProp(obj, name, value) {
        var descriptor = {
            value: value,
            configurable: true,
            enumerable: false,
            writable: true
        };
        es5.defineProperty(obj, name, descriptor);
        return obj;
    }
    
    
    var wrapsPrimitiveReceiver = (function() {
        return this !== "string";
    }).call("string");
    
    function thrower(r) {
        throw r;
    }
    
    
    var ret = {
        thrower: thrower,
        isArray: es5.isArray,
        haveGetters: haveGetters,
        notEnumerableProp: notEnumerableProp,
        isPrimitive: isPrimitive,
        isObject: isObject,
        canEvaluate: canEvaluate,
        deprecated: deprecated,
        errorObj: errorObj,
        tryCatch1: tryCatch1,
        tryCatch2: tryCatch2,
        tryCatchApply: tryCatchApply,
        inherits: inherits,
        withAppended: withAppended,
        asString: asString,
        maybeWrapAsError: maybeWrapAsError,
        wrapsPrimitiveReceiver: wrapsPrimitiveReceiver
    };
    
    module.exports = ret;
    
    },{"./assert.js":2,"./es5.js":12,"./global.js":16}],40:[function(_dereq_,module,exports){
    /*global define:false require:false */
    module.exports = (function(){
      // Import Events
      var events = _dereq_('events');
    
      // Export Domain
      var domain = {};
      domain.create = function(){
        var d = new events.EventEmitter();
        d.run = function(fn){
          try {
            fn();
          }
          catch (err) {
            this.emit('error', err);
          }
          return this;
        };
        d.dispose = function(){
          this.removeAllListeners();
          return this;
        };
        return d;
      };
      return domain;
    }).call(this);
    },{"events":41}],41:[function(_dereq_,module,exports){
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
    
    },{}]},{},[4])
    (4)
    });
  };
  
  requires_['errors'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var BaseError, pkgman, _,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
        __slice = [].slice;
    
      _ = require('underscore');
    
      pkgman = require('pkgman');
    
      exports.BaseError = BaseError = (function(_super) {
        __extends(BaseError, _super);
    
        function BaseError(message) {
          this.message = message;
        }
    
        BaseError.template = "Unknown error: :message";
    
        BaseError.prototype.caught = function() {};
    
        BaseError.prototype.key = 'unknown';
    
        BaseError.prototype.template = BaseError.template;
    
        BaseError.prototype.toJSON = function() {
          return [this.key, this.message];
        };
    
        return BaseError;
    
      })(Error);
    
      exports.errorTypes = function() {
        var Type, Types, collected, _i, _len, _ref;
        collected = [BaseError];
        _ref = pkgman.invoke('errorType');
        for (_ in _ref) {
          Type = _ref[_];
          collected.push(Type);
        }
        Types = {};
        for (_i = 0, _len = collected.length; _i < _len; _i++) {
          Type = collected[_i];
          Types[Type.prototype.key] = Type;
        }
        return Types;
      };
    
      exports.serialize = function(error) {
        if (error instanceof BaseError) {
          return error.toJSON();
        } else if (error instanceof Error) {
          return [void 0, error.message];
        } else {
          return [void 0, error];
        }
      };
    
      exports.unserialize = function(data) {
        return exports.instantiate.apply(null, data);
      };
    
      exports.message = function(error) {
        var key, output, value;
        output = error instanceof BaseError ? error.template : error instanceof Error ? BaseError.template.replace(":message", error.message) : BaseError.template.replace(":message", error.toString());
        for (key in error) {
          value = error[key];
          output = output.replace(":" + key, value);
        }
        return output;
      };
    
      exports.stack = function(error) {
        var formatStack;
        formatStack = error.stack;
        formatStack = formatStack != null ? (formatStack = formatStack.split('\n'), formatStack.shift(), '\n' + formatStack.join('\n')) : '';
        return "" + (this.message(error)) + formatStack;
      };
    
      exports.instantiate = function() {
        var IType, Type, Types, args, error, key, stack;
        key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        Types = exports.errorTypes();
        Type = Types[key] != null ? Types[key] : BaseError;
        IType = (function(Type) {
          var F;
          F = function(args) {
            return Type.apply(this, args);
          };
          F.prototype = Type.prototype;
          return function(args) {
            return new F(args);
          };
        })(Type);
        try {
          throw new Error();
        } catch (_error) {
          error = _error;
          stack = error.stack;
        }
        error = IType(args);
        error.stack = stack;
        return error;
      };
    
      exports.caught = function(error) {
        if (!(error instanceof BaseError)) {
          return error;
        }
        error.caught(exports.message(error));
        return error;
      };
    
    }).call(this);
    
  };
  
  requires_['inflection'] = function(module, exports, require, __dirname, __filename) {
  
    !function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.inflection=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
    /*!
     * inflection
     * Copyright(c) 2011 Ben Lin <ben@dreamerslab.com>
     * MIT Licensed
     *
     * @fileoverview
     * A port of inflection-js to node.js module.
     */
    
    ( function ( root ){
    
      /**
       * @description This is a list of nouns that use the same form for both singular and plural.
       *              This list should remain entirely in lower case to correctly match Strings.
       * @private
       */
      var uncountable_words = [
        'equipment', 'information', 'rice', 'money', 'species',
        'series', 'fish', 'sheep', 'moose', 'deer', 'news'
      ];
    
      /**
       * @description These rules translate from the singular form of a noun to its plural form.
       * @private
       */
      var plural_rules = [
    
        // do not replace if its already a plural word
        [ new RegExp( '(m)en$',      'gi' )],
        [ new RegExp( '(pe)ople$',   'gi' )],
        [ new RegExp( '(child)ren$', 'gi' )],
        [ new RegExp( '([ti])a$',    'gi' )],
        [ new RegExp( '((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$','gi' )],
        [ new RegExp( '(hive)s$',           'gi' )],
        [ new RegExp( '(tive)s$',           'gi' )],
        [ new RegExp( '(curve)s$',          'gi' )],
        [ new RegExp( '([lr])ves$',         'gi' )],
        [ new RegExp( '([^fo])ves$',        'gi' )],
        [ new RegExp( '([^aeiouy]|qu)ies$', 'gi' )],
        [ new RegExp( '(s)eries$',          'gi' )],
        [ new RegExp( '(m)ovies$',          'gi' )],
        [ new RegExp( '(x|ch|ss|sh)es$',    'gi' )],
        [ new RegExp( '([m|l])ice$',        'gi' )],
        [ new RegExp( '(bus)es$',           'gi' )],
        [ new RegExp( '(o)es$',             'gi' )],
        [ new RegExp( '(shoe)s$',           'gi' )],
        [ new RegExp( '(cris|ax|test)es$',  'gi' )],
        [ new RegExp( '(octop|vir)i$',      'gi' )],
        [ new RegExp( '(alias|status)es$',  'gi' )],
        [ new RegExp( '^(ox)en',            'gi' )],
        [ new RegExp( '(vert|ind)ices$',    'gi' )],
        [ new RegExp( '(matr)ices$',        'gi' )],
        [ new RegExp( '(quiz)zes$',         'gi' )],
    
        // original rule
        [ new RegExp( '(m)an$', 'gi' ),                 '$1en' ],
        [ new RegExp( '(pe)rson$', 'gi' ),              '$1ople' ],
        [ new RegExp( '(child)$', 'gi' ),               '$1ren' ],
        [ new RegExp( '^(ox)$', 'gi' ),                 '$1en' ],
        [ new RegExp( '(ax|test)is$', 'gi' ),           '$1es' ],
        [ new RegExp( '(octop|vir)us$', 'gi' ),         '$1i' ],
        [ new RegExp( '(alias|status)$', 'gi' ),        '$1es' ],
        [ new RegExp( '(bu)s$', 'gi' ),                 '$1ses' ],
        [ new RegExp( '(buffal|tomat|potat)o$', 'gi' ), '$1oes' ],
        [ new RegExp( '([ti])um$', 'gi' ),              '$1a' ],
        [ new RegExp( 'sis$', 'gi' ),                   'ses' ],
        [ new RegExp( '(?:([^f])fe|([lr])f)$', 'gi' ),  '$1$2ves' ],
        [ new RegExp( '(hive)$', 'gi' ),                '$1s' ],
        [ new RegExp( '([^aeiouy]|qu)y$', 'gi' ),       '$1ies' ],
        [ new RegExp( '(x|ch|ss|sh)$', 'gi' ),          '$1es' ],
        [ new RegExp( '(matr|vert|ind)ix|ex$', 'gi' ),  '$1ices' ],
        [ new RegExp( '([m|l])ouse$', 'gi' ),           '$1ice' ],
        [ new RegExp( '(quiz)$', 'gi' ),                '$1zes' ],
    
        [ new RegExp( 's$', 'gi' ), 's' ],
        [ new RegExp( '$', 'gi' ),  's' ]
      ];
    
      /**
       * @description These rules translate from the plural form of a noun to its singular form.
       * @private
       */
      var singular_rules = [
    
        // do not replace if its already a singular word
        [ new RegExp( '(m)an$',                 'gi' )],
        [ new RegExp( '(pe)rson$',              'gi' )],
        [ new RegExp( '(child)$',               'gi' )],
        [ new RegExp( '^(ox)$',                 'gi' )],
        [ new RegExp( '(ax|test)is$',           'gi' )],
        [ new RegExp( '(octop|vir)us$',         'gi' )],
        [ new RegExp( '(alias|status)$',        'gi' )],
        [ new RegExp( '(bu)s$',                 'gi' )],
        [ new RegExp( '(buffal|tomat|potat)o$', 'gi' )],
        [ new RegExp( '([ti])um$',              'gi' )],
        [ new RegExp( 'sis$',                   'gi' )],
        [ new RegExp( '(?:([^f])fe|([lr])f)$',  'gi' )],
        [ new RegExp( '(hive)$',                'gi' )],
        [ new RegExp( '([^aeiouy]|qu)y$',       'gi' )],
        [ new RegExp( '(x|ch|ss|sh)$',          'gi' )],
        [ new RegExp( '(matr|vert|ind)ix|ex$',  'gi' )],
        [ new RegExp( '([m|l])ouse$',           'gi' )],
        [ new RegExp( '(quiz)$',                'gi' )],
    
        // original rule
        [ new RegExp( '(m)en$', 'gi' ),                                                       '$1an' ],
        [ new RegExp( '(pe)ople$', 'gi' ),                                                    '$1rson' ],
        [ new RegExp( '(child)ren$', 'gi' ),                                                  '$1' ],
        [ new RegExp( '([ti])a$', 'gi' ),                                                     '$1um' ],
        [ new RegExp( '((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$','gi' ), '$1$2sis' ],
        [ new RegExp( '(hive)s$', 'gi' ),                                                     '$1' ],
        [ new RegExp( '(tive)s$', 'gi' ),                                                     '$1' ],
        [ new RegExp( '(curve)s$', 'gi' ),                                                    '$1' ],
        [ new RegExp( '([lr])ves$', 'gi' ),                                                   '$1f' ],
        [ new RegExp( '([^fo])ves$', 'gi' ),                                                  '$1fe' ],
        [ new RegExp( '([^aeiouy]|qu)ies$', 'gi' ),                                           '$1y' ],
        [ new RegExp( '(s)eries$', 'gi' ),                                                    '$1eries' ],
        [ new RegExp( '(m)ovies$', 'gi' ),                                                    '$1ovie' ],
        [ new RegExp( '(x|ch|ss|sh)es$', 'gi' ),                                              '$1' ],
        [ new RegExp( '([m|l])ice$', 'gi' ),                                                  '$1ouse' ],
        [ new RegExp( '(bus)es$', 'gi' ),                                                     '$1' ],
        [ new RegExp( '(o)es$', 'gi' ),                                                       '$1' ],
        [ new RegExp( '(shoe)s$', 'gi' ),                                                     '$1' ],
        [ new RegExp( '(cris|ax|test)es$', 'gi' ),                                            '$1is' ],
        [ new RegExp( '(octop|vir)i$', 'gi' ),                                                '$1us' ],
        [ new RegExp( '(alias|status)es$', 'gi' ),                                            '$1' ],
        [ new RegExp( '^(ox)en', 'gi' ),                                                      '$1' ],
        [ new RegExp( '(vert|ind)ices$', 'gi' ),                                              '$1ex' ],
        [ new RegExp( '(matr)ices$', 'gi' ),                                                  '$1ix' ],
        [ new RegExp( '(quiz)zes$', 'gi' ),                                                   '$1' ],
        [ new RegExp( 'ss$', 'gi' ),                                                          'ss' ],
        [ new RegExp( 's$', 'gi' ),                                                           '' ]
      ];
    
      /**
       * @description This is a list of words that should not be capitalized for title case.
       * @private
       */
      var non_titlecased_words = [
        'and', 'or', 'nor', 'a', 'an', 'the', 'so', 'but', 'to', 'of', 'at','by',
        'from', 'into', 'on', 'onto', 'off', 'out', 'in', 'over', 'with', 'for'
      ];
    
      /**
       * @description These are regular expressions used for converting between String formats.
       * @private
       */
      var id_suffix         = new RegExp( '(_ids|_id)$', 'g' );
      var underbar          = new RegExp( '_', 'g' );
      var space_or_underbar = new RegExp( '[\ _]', 'g' );
      var uppercase         = new RegExp( '([A-Z])', 'g' );
      var underbar_prefix   = new RegExp( '^_' );
    
      var inflector = {
    
      /**
       * A helper method that applies rules based replacement to a String.
       * @private
       * @function
       * @param {String} str String to modify and return based on the passed rules.
       * @param {Array: [RegExp, String]} rules Regexp to match paired with String to use for replacement
       * @param {Array: [String]} skip Strings to skip if they match
       * @param {String} override String to return as though this method succeeded (used to conform to APIs)
       * @returns {String} Return passed String modified by passed rules.
       * @example
       *
       *     this._apply_rules( 'cows', singular_rules ); // === 'cow'
       */
        _apply_rules : function( str, rules, skip, override ){
          if( override ){
            str = override;
          }else{
            var ignore = ( inflector.indexOf( skip, str.toLowerCase()) > -1 );
    
            if( !ignore ){
              var i = 0;
              var j = rules.length;
    
              for( ; i < j; i++ ){
                if( str.match( rules[ i ][ 0 ])){
                  if( rules[ i ][ 1 ] !== undefined ){
                    str = str.replace( rules[ i ][ 0 ], rules[ i ][ 1 ]);
                  }
                  break;
                }
              }
            }
          }
    
          return str;
        },
    
    
    
      /**
       * This lets us detect if an Array contains a given element.
       * @public
       * @function
       * @param {Array} arr The subject array.
       * @param {Object} item Object to locate in the Array.
       * @param {Number} fromIndex Starts checking from this position in the Array.(optional)
       * @param {Function} compareFunc Function used to compare Array item vs passed item.(optional)
       * @returns {Number} Return index position in the Array of the passed item.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.indexOf([ 'hi','there' ], 'guys' ); // === -1
       *     inflection.indexOf([ 'hi','there' ], 'hi' ); // === 0
       */
        indexOf : function( arr, item, fromIndex, compareFunc ){
          if( !fromIndex ){
            fromIndex = -1;
          }
    
          var index = -1;
          var i     = fromIndex;
          var j     = arr.length;
    
          for( ; i < j; i++ ){
            if( arr[ i ]  === item || compareFunc && compareFunc( arr[ i ], item )){
              index = i;
              break;
            }
          }
    
          return index;
        },
    
    
    
      /**
       * This function adds pluralization support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {String} plural Overrides normal output with said String.(optional)
       * @returns {String} Singular English language nouns are returned in plural form.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.pluralize( 'person' ); // === 'people'
       *     inflection.pluralize( 'octopus' ); // === 'octopi'
       *     inflection.pluralize( 'Hat' ); // === 'Hats'
       *     inflection.pluralize( 'person', 'guys' ); // === 'guys'
       */
        pluralize : function ( str, plural ){
          return inflector._apply_rules( str, plural_rules, uncountable_words, plural );
        },
    
    
    
      /**
       * This function adds singularization support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {String} singular Overrides normal output with said String.(optional)
       * @returns {String} Plural English language nouns are returned in singular form.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.singularize( 'people' ); // === 'person'
       *     inflection.singularize( 'octopi' ); // === 'octopus'
       *     inflection.singularize( 'Hats' ); // === 'Hat'
       *     inflection.singularize( 'guys', 'person' ); // === 'person'
       */
        singularize : function ( str, singular ){
          return inflector._apply_rules( str, singular_rules, uncountable_words, singular );
        },
    
    
    
      /**
       * This function adds camelization support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {Boolean} lowFirstLetter Default is to capitalize the first letter of the results.(optional)
       *                                 Passing true will lowercase it.
       * @returns {String} Lower case underscored words will be returned in camel case.
       *                  additionally '/' is translated to '::'
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.camelize( 'message_properties' ); // === 'MessageProperties'
       *     inflection.camelize( 'message_properties', true ); // === 'messageProperties'
       */
        camelize : function ( str, lowFirstLetter ){
          var str_path = str.split( '/' );
          var i        = 0;
          var j        = str_path.length;
          var str_arr, init_x, k, l, first;
    
          for( ; i < j; i++ ){
            str_arr = str_path[ i ].split( '_' );
            k       = 0;
            l       = str_arr.length;
    
            for( ; k < l; k++ ){
              if( k !== 0 ){
                str_arr[ k ] = str_arr[ k ].toLowerCase();
              }
    
              first = str_arr[ k ].charAt( 0 );
              first = lowFirstLetter && i === 0 && k === 0
                ? first.toLowerCase() : first.toUpperCase();
              str_arr[ k ] = first + str_arr[ k ].substring( 1 );
            }
    
            str_path[ i ] = str_arr.join( '' );
          }
    
          return str_path.join( '::' );
        },
    
    
    
      /**
       * This function adds underscore support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {Boolean} allUpperCase Default is to lowercase and add underscore prefix.(optional)
       *                  Passing true will return as entered.
       * @returns {String} Camel cased words are returned as lower cased and underscored.
       *                  additionally '::' is translated to '/'.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.underscore( 'MessageProperties' ); // === 'message_properties'
       *     inflection.underscore( 'messageProperties' ); // === 'message_properties'
       *     inflection.underscore( 'MP', true ); // === 'MP'
       */
        underscore : function ( str, allUpperCase ){
          if( allUpperCase && str === str.toUpperCase()) return str;
    
          var str_path = str.split( '::' );
          var i        = 0;
          var j        = str_path.length;
    
          for( ; i < j; i++ ){
            str_path[ i ] = str_path[ i ].replace( uppercase, '_$1' );
            str_path[ i ] = str_path[ i ].replace( underbar_prefix, '' );
          }
    
          return str_path.join( '/' ).toLowerCase();
        },
    
    
    
      /**
       * This function adds humanize support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {Boolean} lowFirstLetter Default is to capitalize the first letter of the results.(optional)
       *                                 Passing true will lowercase it.
       * @returns {String} Lower case underscored words will be returned in humanized form.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.humanize( 'message_properties' ); // === 'Message properties'
       *     inflection.humanize( 'message_properties', true ); // === 'message properties'
       */
        humanize : function( str, lowFirstLetter ){
          str = str.toLowerCase();
          str = str.replace( id_suffix, '' );
          str = str.replace( underbar, ' ' );
    
          if( !lowFirstLetter ){
            str = inflector.capitalize( str );
          }
    
          return str;
        },
    
    
    
      /**
       * This function adds capitalization support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} All characters will be lower case and the first will be upper.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.capitalize( 'message_properties' ); // === 'Message_properties'
       *     inflection.capitalize( 'message properties', true ); // === 'Message properties'
       */
        capitalize : function ( str ){
          str = str.toLowerCase();
    
          return str.substring( 0, 1 ).toUpperCase() + str.substring( 1 );
        },
    
    
    
      /**
       * This function adds dasherization support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} Replaces all spaces or underbars with dashes.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.dasherize( 'message_properties' ); // === 'message-properties'
       *     inflection.dasherize( 'Message Properties' ); // === 'Message-Properties'
       */
        dasherize : function ( str ){
          return str.replace( space_or_underbar, '-' );
        },
    
    
    
      /**
       * This function adds titleize support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} Capitalizes words as you would for a book title.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.titleize( 'message_properties' ); // === 'Message Properties'
       *     inflection.titleize( 'message properties to keep' ); // === 'Message Properties to Keep'
       */
        titleize : function ( str ){
          str         = str.toLowerCase().replace( underbar, ' ');
          var str_arr = str.split(' ');
          var i       = 0;
          var j       = str_arr.length;
          var d, k, l;
    
          for( ; i < j; i++ ){
            d = str_arr[ i ].split( '-' );
            k = 0;
            l = d.length;
    
            for( ; k < l; k++){
              if( inflector.indexOf( non_titlecased_words, d[ k ].toLowerCase()) < 0 ){
                d[ k ] = inflector.capitalize( d[ k ]);
              }
            }
    
            str_arr[ i ] = d.join( '-' );
          }
    
          str = str_arr.join( ' ' );
          str = str.substring( 0, 1 ).toUpperCase() + str.substring( 1 );
    
          return str;
        },
    
    
    
      /**
       * This function adds demodulize support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} Removes module names leaving only class names.(Ruby style)
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.demodulize( 'Message::Bus::Properties' ); // === 'Properties'
       */
        demodulize : function ( str ){
          var str_arr = str.split( '::' );
    
          return str_arr[ str_arr.length - 1 ];
        },
    
    
    
      /**
       * This function adds tableize support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} Return camel cased words into their underscored plural form.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.tableize( 'MessageBusProperty' ); // === 'message_bus_properties'
       */
        tableize : function ( str ){
          str = inflector.underscore( str );
          str = inflector.pluralize( str );
    
          return str;
        },
    
    
    
      /**
       * This function adds classification support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} Underscored plural nouns become the camel cased singular form.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.classify( 'message_bus_properties' ); // === 'MessageBusProperty'
       */
        classify : function ( str ){
          str = inflector.camelize( str );
          str = inflector.singularize( str );
    
          return str;
        },
    
    
    
      /**
       * This function adds foreign key support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {Boolean} dropIdUbar Default is to seperate id with an underbar at the end of the class name,
                                     you can pass true to skip it.(optional)
       * @returns {String} Underscored plural nouns become the camel cased singular form.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.foreign_key( 'MessageBusProperty' ); // === 'message_bus_property_id'
       *     inflection.foreign_key( 'MessageBusProperty', true ); // === 'message_bus_propertyid'
       */
        foreign_key : function( str, dropIdUbar ){
          str = inflector.demodulize( str );
          str = inflector.underscore( str ) + (( dropIdUbar ) ? ( '' ) : ( '_' )) + 'id';
    
          return str;
        },
    
    
    
      /**
       * This function adds ordinalize support to every String object.
       * @public
       * @function
       * @param {String} str The subject string.
       * @returns {String} Return all found numbers their sequence like '22nd'.
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.ordinalize( 'the 1 pitch' ); // === 'the 1st pitch'
       */
        ordinalize : function ( str ){
          var str_arr = str.split(' ');
          var i       = 0;
          var j       = str_arr.length;
    
          for( ; i < j; i++ ){
            var k = parseInt( str_arr[ i ], 10 );
    
            if( !isNaN( k )){
              var ltd = str_arr[ i ].substring( str_arr[ i ].length - 2 );
              var ld  = str_arr[ i ].substring( str_arr[ i ].length - 1 );
              var suf = 'th';
    
              if( ltd != '11' && ltd != '12' && ltd != '13' ){
                if( ld === '1' ){
                  suf = 'st';
                }else if( ld === '2' ){
                  suf = 'nd';
                }else if( ld === '3' ){
                  suf = 'rd';
                }
              }
    
              str_arr[ i ] += suf;
            }
          }
    
          return str_arr.join( ' ' );
        },
    
      /**
       * This function performs multiple inflection methods on a string
       * @public
       * @function
       * @param {String} str The subject string.
       * @param {Array} arr An array of inflection methods.
       * @returns {String}
       * @example
       *
       *     var inflection = require( 'inflection' );
       *
       *     inflection.transform( 'all job', [ 'pluralize', 'capitalize', 'dasherize' ]); // === 'All-jobs'
       */
        transform : function ( str, arr ){
          var i = 0;
          var j = arr.length;
    
          for( ;i < j; i++ ){
            var method = arr[ i ];
    
            if( this.hasOwnProperty( method )){
              str = this[ method ]( str );
            }
          }
    
          return str;
        }
      };
    
    /**
     * @public
     */
      inflector.version = '1.3.5';
    
      // browser support
      // requirejs
      if( typeof define !== 'undefined' ){
        return define( function ( require, exports, module ){
          module.exports = inflector;
        });
      }
    
      // browser support
      // normal usage
      if( typeof exports === 'undefined' ){
        root.inflection = inflector;
        return;
      }
    
    /**
     * Exports module.
     */
      module.exports = inflector;
    })( this );
    
    },{}]},{},[1])
    (1)
    });
  };
  
  requires_['jugglingdb-client'] = function(module, exports, require, __dirname, __filename) {
  
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
  };
  
  requires_['jugglingdb-rest'] = function(module, exports, require, __dirname, __filename) {
  
    
    /*
    
    Socket.IO adapter proxy for [JugglingDB](https://github.com/1602/jugglingdb).
    
    This adapter forwards all adapter commands through a socket, to be run by the
    database server.
     */
    
    (function() {
      var SocketAdapter, i8n;
    
      i8n = require('inflection');
    
      SocketAdapter = (function() {
        var promiseCallback, translateQuery;
    
        function SocketAdapter(schema, $http) {
          this.schema = schema;
          this.$http = $http;
        }
    
        promiseCallback = function(fn, promise) {
          return promise.then(function(_arg) {
            var data;
            data = _arg.data;
            return fn(null, data);
          }, function(_arg) {
            var data;
            data = _arg.data;
            return fn(new Error(data.message));
          });
        };
    
        translateQuery = function(query) {
          var key, params, value, _ref;
          params = [];
          if (query.limit != null) {
            params.push("limit=" + query.limit);
          }
          if (query.order != null) {
            params.push("order=" + query.order);
          }
          if (query.skip != null) {
            params.push("skip=" + query.skip);
          }
          if ((query.where != null) && Object.keys(query.where).length) {
            _ref = query.where;
            for (key in _ref) {
              value = _ref[key];
              params.push("where[" + key + "]=" + value);
            }
          }
          return params.join('&');
        };
    
        ['connect', 'disconnect'].forEach(function(prop) {
          return SocketAdapter.prototype[prop] = function(fn) {
            return fn();
          };
        });
    
        ['define', 'defineForeignKey', 'possibleIndexes', 'updateIndexes', 'transaction'].forEach(function(prop) {
          return SocketAdapter.prototype[prop] = function() {};
        });
    
        SocketAdapter.prototype.all = function(model, query, fn) {
          var collection;
          collection = this.schema.resourcePaths(model).collection;
          query = translateQuery(query != null ? query : {});
          return promiseCallback(fn, this.$http.get("" + this.schema.settings.apiRoot + "/" + collection + "?" + query));
        };
    
        SocketAdapter.prototype.count = function(model, fn) {
          var collection;
          collection = this.schema.resourcePaths(model).collection;
          return promiseCallback(fn, this.$http.get("" + this.schema.settings.apiRoot + "/" + collection + "/count"));
        };
    
        SocketAdapter.prototype.create = function(model, data, fn) {
          var collection;
          collection = this.schema.resourcePaths(model).collection;
          return promiseCallback(fn, this.$http.post("" + this.schema.settings.apiRoot + "/" + collection, data));
        };
    
        SocketAdapter.prototype.destroy = function(model, id, fn) {
          var resource;
          resource = this.schema.resourcePaths(model).resource;
          return promiseCallback(fn, this.$http["delete"]("" + this.schema.settings.apiRoot + "/" + resource + "/" + id));
        };
    
        SocketAdapter.prototype.destroyAll = function(model, fn) {
          var collection;
          collection = this.schema.resourcePaths(model).collection;
          return promiseCallback(fn, this.$http["delete"]("" + this.schema.settings.apiRoot + "/" + collection));
        };
    
        SocketAdapter.prototype.exists = function(model, id, fn) {
          var resource;
          resource = this.schema.resourcePaths(model).resource;
          return promiseCallback(fn, this.$http.get("" + this.schema.settings.apiRoot + "/" + resource + "/" + id + "/exists"));
        };
    
        SocketAdapter.prototype.find = function() {};
    
        SocketAdapter.prototype.save = function(model, data, fn) {
          var id, resource;
          id = data.id;
          resource = this.schema.resourcePaths(model).resource;
          if (id != null) {
            return promiseCallback(fn, this.$http.put("" + this.schema.settings.apiRoot + "/" + resource + "/" + id, data));
          } else {
            return this.create(model, data, fn);
          }
        };
    
        SocketAdapter.prototype.updateAttributes = function(model, id, data, fn) {
          data.id = id;
          return this.save(model, data, fn);
        };
    
        SocketAdapter.prototype.updateOrCreate = SocketAdapter.prototype.save;
    
        return SocketAdapter;
    
      })();
    
      exports.initialize = function(schema) {
        var $http, inflection, _ref;
        _ref = schema.settings, $http = _ref.$http, inflection = _ref.inflection;
        schema.adapter = new SocketAdapter(schema, $http, inflection);
        return schema.connected = true;
      };
    
    }).call(this);
    
  };
  
  requires_['marked'] = function(module, exports, require, __dirname, __filename) {
  
    /**
     * marked - a markdown parser
     * Copyright (c) 2011-2013, Christopher Jeffrey. (MIT Licensed)
     * https://github.com/chjj/marked
     */
    
    ;(function() {
    
    /**
     * Block-Level Grammar
     */
    
    var block = {
      newline: /^\n+/,
      code: /^( {4}[^\n]+\n*)+/,
      fences: noop,
      hr: /^( *[-*_]){3,} *(?:\n+|$)/,
      heading: /^ *(#{1,6}) *([^\n]+?) *#* *(?:\n+|$)/,
      nptable: noop,
      lheading: /^([^\n]+)\n *(=|-){2,} *(?:\n+|$)/,
      blockquote: /^( *>[^\n]+(\n[^\n]+)*\n*)+/,
      list: /^( *)(bull) [\s\S]+?(?:hr|\n{2,}(?! )(?!\1bull )\n*|\s*$)/,
      html: /^ *(?:comment|closed|closing) *(?:\n{2,}|\s*$)/,
      def: /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +["(]([^\n]+)[")])? *(?:\n+|$)/,
      table: noop,
      paragraph: /^((?:[^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+)\n*/,
      text: /^[^\n]+/
    };
    
    block.bullet = /(?:[*+-]|\d+\.)/;
    block.item = /^( *)(bull) [^\n]*(?:\n(?!\1bull )[^\n]*)*/;
    block.item = replace(block.item, 'gm')
      (/bull/g, block.bullet)
      ();
    
    block.list = replace(block.list)
      (/bull/g, block.bullet)
      ('hr', /\n+(?=(?: *[-*_]){3,} *(?:\n+|$))/)
      ();
    
    block._tag = '(?!(?:'
      + 'a|em|strong|small|s|cite|q|dfn|abbr|data|time|code'
      + '|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo'
      + '|span|br|wbr|ins|del|img)\\b)\\w+(?!:/|[^\\w\\s@]*@)\\b';
    
    block.html = replace(block.html)
      ('comment', /<!--[\s\S]*?-->/)
      ('closed', /<(tag)[\s\S]+?<\/\1>/)
      ('closing', /<tag(?:"[^"]*"|'[^']*'|[^'">])*?>/)
      (/tag/g, block._tag)
      ();
    
    block.paragraph = replace(block.paragraph)
      ('hr', block.hr)
      ('heading', block.heading)
      ('lheading', block.lheading)
      ('blockquote', block.blockquote)
      ('tag', '<' + block._tag)
      ('def', block.def)
      ();
    
    /**
     * Normal Block Grammar
     */
    
    block.normal = merge({}, block);
    
    /**
     * GFM Block Grammar
     */
    
    block.gfm = merge({}, block.normal, {
      fences: /^ *(`{3,}|~{3,}) *(\S+)? *\n([\s\S]+?)\s*\1 *(?:\n+|$)/,
      paragraph: /^/
    });
    
    block.gfm.paragraph = replace(block.paragraph)
      ('(?!', '(?!'
        + block.gfm.fences.source.replace('\\1', '\\2') + '|'
        + block.list.source.replace('\\1', '\\3') + '|')
      ();
    
    /**
     * GFM + Tables Block Grammar
     */
    
    block.tables = merge({}, block.gfm, {
      nptable: /^ *(\S.*\|.*)\n *([-:]+ *\|[-| :]*)\n((?:.*\|.*(?:\n|$))*)\n*/,
      table: /^ *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/
    });
    
    /**
     * Block Lexer
     */
    
    function Lexer(options) {
      this.tokens = [];
      this.tokens.links = {};
      this.options = options || marked.defaults;
      this.rules = block.normal;
    
      if (this.options.gfm) {
        if (this.options.tables) {
          this.rules = block.tables;
        } else {
          this.rules = block.gfm;
        }
      }
    }
    
    /**
     * Expose Block Rules
     */
    
    Lexer.rules = block;
    
    /**
     * Static Lex Method
     */
    
    Lexer.lex = function(src, options) {
      var lexer = new Lexer(options);
      return lexer.lex(src);
    };
    
    /**
     * Preprocessing
     */
    
    Lexer.prototype.lex = function(src) {
      src = src
        .replace(/\r\n|\r/g, '\n')
        .replace(/\t/g, '    ')
        .replace(/\u00a0/g, ' ')
        .replace(/\u2424/g, '\n');
    
      return this.token(src, true);
    };
    
    /**
     * Lexing
     */
    
    Lexer.prototype.token = function(src, top) {
      var src = src.replace(/^ +$/gm, '')
        , next
        , loose
        , cap
        , bull
        , b
        , item
        , space
        , i
        , l;
    
      while (src) {
        // newline
        if (cap = this.rules.newline.exec(src)) {
          src = src.substring(cap[0].length);
          if (cap[0].length > 1) {
            this.tokens.push({
              type: 'space'
            });
          }
        }
    
        // code
        if (cap = this.rules.code.exec(src)) {
          src = src.substring(cap[0].length);
          cap = cap[0].replace(/^ {4}/gm, '');
          this.tokens.push({
            type: 'code',
            text: !this.options.pedantic
              ? cap.replace(/\n+$/, '')
              : cap
          });
          continue;
        }
    
        // fences (gfm)
        if (cap = this.rules.fences.exec(src)) {
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: 'code',
            lang: cap[2],
            text: cap[3]
          });
          continue;
        }
    
        // heading
        if (cap = this.rules.heading.exec(src)) {
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: 'heading',
            depth: cap[1].length,
            text: cap[2]
          });
          continue;
        }
    
        // table no leading pipe (gfm)
        if (top && (cap = this.rules.nptable.exec(src))) {
          src = src.substring(cap[0].length);
    
          item = {
            type: 'table',
            header: cap[1].replace(/^ *| *\| *$/g, '').split(/ *\| */),
            align: cap[2].replace(/^ *|\| *$/g, '').split(/ *\| */),
            cells: cap[3].replace(/\n$/, '').split('\n')
          };
    
          for (i = 0; i < item.align.length; i++) {
            if (/^ *-+: *$/.test(item.align[i])) {
              item.align[i] = 'right';
            } else if (/^ *:-+: *$/.test(item.align[i])) {
              item.align[i] = 'center';
            } else if (/^ *:-+ *$/.test(item.align[i])) {
              item.align[i] = 'left';
            } else {
              item.align[i] = null;
            }
          }
    
          for (i = 0; i < item.cells.length; i++) {
            item.cells[i] = item.cells[i].split(/ *\| */);
          }
    
          this.tokens.push(item);
    
          continue;
        }
    
        // lheading
        if (cap = this.rules.lheading.exec(src)) {
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: 'heading',
            depth: cap[2] === '=' ? 1 : 2,
            text: cap[1]
          });
          continue;
        }
    
        // hr
        if (cap = this.rules.hr.exec(src)) {
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: 'hr'
          });
          continue;
        }
    
        // blockquote
        if (cap = this.rules.blockquote.exec(src)) {
          src = src.substring(cap[0].length);
    
          this.tokens.push({
            type: 'blockquote_start'
          });
    
          cap = cap[0].replace(/^ *> ?/gm, '');
    
          // Pass `top` to keep the current
          // "toplevel" state. This is exactly
          // how markdown.pl works.
          this.token(cap, top);
    
          this.tokens.push({
            type: 'blockquote_end'
          });
    
          continue;
        }
    
        // list
        if (cap = this.rules.list.exec(src)) {
          src = src.substring(cap[0].length);
          bull = cap[2];
    
          this.tokens.push({
            type: 'list_start',
            ordered: bull.length > 1
          });
    
          // Get each top-level item.
          cap = cap[0].match(this.rules.item);
    
          next = false;
          l = cap.length;
          i = 0;
    
          for (; i < l; i++) {
            item = cap[i];
    
            // Remove the list item's bullet
            // so it is seen as the next token.
            space = item.length;
            item = item.replace(/^ *([*+-]|\d+\.) +/, '');
    
            // Outdent whatever the
            // list item contains. Hacky.
            if (~item.indexOf('\n ')) {
              space -= item.length;
              item = !this.options.pedantic
                ? item.replace(new RegExp('^ {1,' + space + '}', 'gm'), '')
                : item.replace(/^ {1,4}/gm, '');
            }
    
            // Determine whether the next list item belongs here.
            // Backpedal if it does not belong in this list.
            if (this.options.smartLists && i !== l - 1) {
              b = block.bullet.exec(cap[i + 1])[0];
              if (bull !== b && !(bull.length > 1 && b.length > 1)) {
                src = cap.slice(i + 1).join('\n') + src;
                i = l - 1;
              }
            }
    
            // Determine whether item is loose or not.
            // Use: /(^|\n)(?! )[^\n]+\n\n(?!\s*$)/
            // for discount behavior.
            loose = next || /\n\n(?!\s*$)/.test(item);
            if (i !== l - 1) {
              next = item.charAt(item.length - 1) === '\n';
              if (!loose) loose = next;
            }
    
            this.tokens.push({
              type: loose
                ? 'loose_item_start'
                : 'list_item_start'
            });
    
            // Recurse.
            this.token(item, false);
    
            this.tokens.push({
              type: 'list_item_end'
            });
          }
    
          this.tokens.push({
            type: 'list_end'
          });
    
          continue;
        }
    
        // html
        if (cap = this.rules.html.exec(src)) {
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: this.options.sanitize
              ? 'paragraph'
              : 'html',
            pre: cap[1] === 'pre' || cap[1] === 'script' || cap[1] === 'style',
            text: cap[0]
          });
          continue;
        }
    
        // def
        if (top && (cap = this.rules.def.exec(src))) {
          src = src.substring(cap[0].length);
          this.tokens.links[cap[1].toLowerCase()] = {
            href: cap[2],
            title: cap[3]
          };
          continue;
        }
    
        // table (gfm)
        if (top && (cap = this.rules.table.exec(src))) {
          src = src.substring(cap[0].length);
    
          item = {
            type: 'table',
            header: cap[1].replace(/^ *| *\| *$/g, '').split(/ *\| */),
            align: cap[2].replace(/^ *|\| *$/g, '').split(/ *\| */),
            cells: cap[3].replace(/(?: *\| *)?\n$/, '').split('\n')
          };
    
          for (i = 0; i < item.align.length; i++) {
            if (/^ *-+: *$/.test(item.align[i])) {
              item.align[i] = 'right';
            } else if (/^ *:-+: *$/.test(item.align[i])) {
              item.align[i] = 'center';
            } else if (/^ *:-+ *$/.test(item.align[i])) {
              item.align[i] = 'left';
            } else {
              item.align[i] = null;
            }
          }
    
          for (i = 0; i < item.cells.length; i++) {
            item.cells[i] = item.cells[i]
              .replace(/^ *\| *| *\| *$/g, '')
              .split(/ *\| */);
          }
    
          this.tokens.push(item);
    
          continue;
        }
    
        // top-level paragraph
        if (top && (cap = this.rules.paragraph.exec(src))) {
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: 'paragraph',
            text: cap[1].charAt(cap[1].length - 1) === '\n'
              ? cap[1].slice(0, -1)
              : cap[1]
          });
          continue;
        }
    
        // text
        if (cap = this.rules.text.exec(src)) {
          // Top-level should never reach here.
          src = src.substring(cap[0].length);
          this.tokens.push({
            type: 'text',
            text: cap[0]
          });
          continue;
        }
    
        if (src) {
          throw new
            Error('Infinite loop on byte: ' + src.charCodeAt(0));
        }
      }
    
      return this.tokens;
    };
    
    /**
     * Inline-Level Grammar
     */
    
    var inline = {
      escape: /^\\([\\`*{}\[\]()#+\-.!_>])/,
      autolink: /^<([^ >]+(@|:\/)[^ >]+)>/,
      url: noop,
      tag: /^<!--[\s\S]*?-->|^<\/?\w+(?:"[^"]*"|'[^']*'|[^'">])*?>/,
      link: /^!?\[(inside)\]\(href\)/,
      reflink: /^!?\[(inside)\]\s*\[([^\]]*)\]/,
      nolink: /^!?\[((?:\[[^\]]*\]|[^\[\]])*)\]/,
      strong: /^__([\s\S]+?)__(?!_)|^\*\*([\s\S]+?)\*\*(?!\*)/,
      em: /^\b_((?:__|[\s\S])+?)_\b|^\*((?:\*\*|[\s\S])+?)\*(?!\*)/,
      code: /^(`+)\s*([\s\S]*?[^`])\s*\1(?!`)/,
      br: /^ {2,}\n(?!\s*$)/,
      del: noop,
      text: /^[\s\S]+?(?=[\\<!\[_*`]| {2,}\n|$)/
    };
    
    inline._inside = /(?:\[[^\]]*\]|[^\[\]]|\](?=[^\[]*\]))*/;
    inline._href = /\s*<?([\s\S]*?)>?(?:\s+['"]([\s\S]*?)['"])?\s*/;
    
    inline.link = replace(inline.link)
      ('inside', inline._inside)
      ('href', inline._href)
      ();
    
    inline.reflink = replace(inline.reflink)
      ('inside', inline._inside)
      ();
    
    /**
     * Normal Inline Grammar
     */
    
    inline.normal = merge({}, inline);
    
    /**
     * Pedantic Inline Grammar
     */
    
    inline.pedantic = merge({}, inline.normal, {
      strong: /^__(?=\S)([\s\S]*?\S)__(?!_)|^\*\*(?=\S)([\s\S]*?\S)\*\*(?!\*)/,
      em: /^_(?=\S)([\s\S]*?\S)_(?!_)|^\*(?=\S)([\s\S]*?\S)\*(?!\*)/
    });
    
    /**
     * GFM Inline Grammar
     */
    
    inline.gfm = merge({}, inline.normal, {
      escape: replace(inline.escape)('])', '~|])')(),
      url: /^(https?:\/\/[^\s<]+[^<.,:;"')\]\s])/,
      del: /^~~(?=\S)([\s\S]*?\S)~~/,
      text: replace(inline.text)
        (']|', '~]|')
        ('|', '|https?://|')
        ()
    });
    
    /**
     * GFM + Line Breaks Inline Grammar
     */
    
    inline.breaks = merge({}, inline.gfm, {
      br: replace(inline.br)('{2,}', '*')(),
      text: replace(inline.gfm.text)('{2,}', '*')()
    });
    
    /**
     * Inline Lexer & Compiler
     */
    
    function InlineLexer(links, options) {
      this.options = options || marked.defaults;
      this.links = links;
      this.rules = inline.normal;
      this.renderer = this.options.renderer || new Renderer;
      this.renderer.options = this.options;
    
      if (!this.links) {
        throw new
          Error('Tokens array requires a `links` property.');
      }
    
      if (this.options.gfm) {
        if (this.options.breaks) {
          this.rules = inline.breaks;
        } else {
          this.rules = inline.gfm;
        }
      } else if (this.options.pedantic) {
        this.rules = inline.pedantic;
      }
    }
    
    /**
     * Expose Inline Rules
     */
    
    InlineLexer.rules = inline;
    
    /**
     * Static Lexing/Compiling Method
     */
    
    InlineLexer.output = function(src, links, options) {
      var inline = new InlineLexer(links, options);
      return inline.output(src);
    };
    
    /**
     * Lexing/Compiling
     */
    
    InlineLexer.prototype.output = function(src) {
      var out = ''
        , link
        , text
        , href
        , cap;
    
      while (src) {
        // escape
        if (cap = this.rules.escape.exec(src)) {
          src = src.substring(cap[0].length);
          out += cap[1];
          continue;
        }
    
        // autolink
        if (cap = this.rules.autolink.exec(src)) {
          src = src.substring(cap[0].length);
          if (cap[2] === '@') {
            text = cap[1].charAt(6) === ':'
              ? this.mangle(cap[1].substring(7))
              : this.mangle(cap[1]);
            href = this.mangle('mailto:') + text;
          } else {
            text = escape(cap[1]);
            href = text;
          }
          out += this.renderer.link(href, null, text);
          continue;
        }
    
        // url (gfm)
        if (cap = this.rules.url.exec(src)) {
          src = src.substring(cap[0].length);
          text = escape(cap[1]);
          href = text;
          out += this.renderer.link(href, null, text);
          continue;
        }
    
        // tag
        if (cap = this.rules.tag.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.options.sanitize
            ? escape(cap[0])
            : cap[0];
          continue;
        }
    
        // link
        if (cap = this.rules.link.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.outputLink(cap, {
            href: cap[2],
            title: cap[3]
          });
          continue;
        }
    
        // reflink, nolink
        if ((cap = this.rules.reflink.exec(src))
            || (cap = this.rules.nolink.exec(src))) {
          src = src.substring(cap[0].length);
          link = (cap[2] || cap[1]).replace(/\s+/g, ' ');
          link = this.links[link.toLowerCase()];
          if (!link || !link.href) {
            out += cap[0].charAt(0);
            src = cap[0].substring(1) + src;
            continue;
          }
          out += this.outputLink(cap, link);
          continue;
        }
    
        // strong
        if (cap = this.rules.strong.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.renderer.strong(this.output(cap[2] || cap[1]));
          continue;
        }
    
        // em
        if (cap = this.rules.em.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.renderer.em(this.output(cap[2] || cap[1]));
          continue;
        }
    
        // code
        if (cap = this.rules.code.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.renderer.codespan(escape(cap[2], true));
          continue;
        }
    
        // br
        if (cap = this.rules.br.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.renderer.br();
          continue;
        }
    
        // del (gfm)
        if (cap = this.rules.del.exec(src)) {
          src = src.substring(cap[0].length);
          out += this.renderer.del(this.output(cap[1]));
          continue;
        }
    
        // text
        if (cap = this.rules.text.exec(src)) {
          src = src.substring(cap[0].length);
          out += escape(this.smartypants(cap[0]));
          continue;
        }
    
        if (src) {
          throw new
            Error('Infinite loop on byte: ' + src.charCodeAt(0));
        }
      }
    
      return out;
    };
    
    /**
     * Compile Link
     */
    
    InlineLexer.prototype.outputLink = function(cap, link) {
      var href = escape(link.href)
        , title = link.title ? escape(link.title) : null;
    
      return cap[0].charAt(0) !== '!'
        ? this.renderer.link(href, title, this.output(cap[1]))
        : this.renderer.image(href, title, escape(cap[1]));
    };
    
    /**
     * Smartypants Transformations
     */
    
    InlineLexer.prototype.smartypants = function(text) {
      if (!this.options.smartypants) return text;
      return text
        // em-dashes
        .replace(/--/g, '\u2014')
        // opening singles
        .replace(/(^|[-\u2014/(\[{"\s])'/g, '$1\u2018')
        // closing singles & apostrophes
        .replace(/'/g, '\u2019')
        // opening doubles
        .replace(/(^|[-\u2014/(\[{\u2018\s])"/g, '$1\u201c')
        // closing doubles
        .replace(/"/g, '\u201d')
        // ellipses
        .replace(/\.{3}/g, '\u2026');
    };
    
    /**
     * Mangle Links
     */
    
    InlineLexer.prototype.mangle = function(text) {
      var out = ''
        , l = text.length
        , i = 0
        , ch;
    
      for (; i < l; i++) {
        ch = text.charCodeAt(i);
        if (Math.random() > 0.5) {
          ch = 'x' + ch.toString(16);
        }
        out += '&#' + ch + ';';
      }
    
      return out;
    };
    
    /**
     * Renderer
     */
    
    function Renderer(options) {
      this.options = options || {};
    }
    
    Renderer.prototype.code = function(code, lang, escaped) {
      if (this.options.highlight) {
        var out = this.options.highlight(code, lang);
        if (out != null && out !== code) {
          escaped = true;
          code = out;
        }
      }
    
      if (!lang) {
        return '<pre><code>'
          + (escaped ? code : escape(code, true))
          + '\n</code></pre>';
      }
    
      return '<pre><code class="'
        + this.options.langPrefix
        + escape(lang, true)
        + '">'
        + (escaped ? code : escape(code, true))
        + '\n</code></pre>\n';
    };
    
    Renderer.prototype.blockquote = function(quote) {
      return '<blockquote>\n' + quote + '</blockquote>\n';
    };
    
    Renderer.prototype.html = function(html) {
      return html;
    };
    
    Renderer.prototype.heading = function(text, level, raw) {
      return '<h'
        + level
        + ' id="'
        + this.options.headerPrefix
        + raw.toLowerCase().replace(/[^\w]+/g, '-')
        + '">'
        + text
        + '</h'
        + level
        + '>\n';
    };
    
    Renderer.prototype.hr = function() {
      return this.options.xhtml ? '<hr/>\n' : '<hr>\n';
    };
    
    Renderer.prototype.list = function(body, ordered) {
      var type = ordered ? 'ol' : 'ul';
      return '<' + type + '>\n' + body + '</' + type + '>\n';
    };
    
    Renderer.prototype.listitem = function(text) {
      return '<li>' + text + '</li>\n';
    };
    
    Renderer.prototype.paragraph = function(text) {
      return '<p>' + text + '</p>\n';
    };
    
    Renderer.prototype.table = function(header, body) {
      return '<table>\n'
        + '<thead>\n'
        + header
        + '</thead>\n'
        + '<tbody>\n'
        + body
        + '</tbody>\n'
        + '</table>\n';
    };
    
    Renderer.prototype.tablerow = function(content) {
      return '<tr>\n' + content + '</tr>\n';
    };
    
    Renderer.prototype.tablecell = function(content, flags) {
      var type = flags.header ? 'th' : 'td';
      var tag = flags.align
        ? '<' + type + ' style="text-align:' + flags.align + '">'
        : '<' + type + '>';
      return tag + content + '</' + type + '>\n';
    };
    
    // span level renderer
    Renderer.prototype.strong = function(text) {
      return '<strong>' + text + '</strong>';
    };
    
    Renderer.prototype.em = function(text) {
      return '<em>' + text + '</em>';
    };
    
    Renderer.prototype.codespan = function(text) {
      return '<code>' + text + '</code>';
    };
    
    Renderer.prototype.br = function() {
      return this.options.xhtml ? '<br/>' : '<br>';
    };
    
    Renderer.prototype.del = function(text) {
      return '<del>' + text + '</del>';
    };
    
    Renderer.prototype.link = function(href, title, text) {
      if (this.options.sanitize) {
        try {
          var prot = decodeURIComponent(unescape(href))
            .replace(/[^\w:]/g, '')
            .toLowerCase();
        } catch (e) {
          return '';
        }
        if (prot.indexOf('javascript:') === 0) {
          return '';
        }
      }
      var out = '<a href="' + href + '"';
      if (title) {
        out += ' title="' + title + '"';
      }
      out += '>' + text + '</a>';
      return out;
    };
    
    Renderer.prototype.image = function(href, title, text) {
      var out = '<img src="' + href + '" alt="' + text + '"';
      if (title) {
        out += ' title="' + title + '"';
      }
      out += this.options.xhtml ? '/>' : '>';
      return out;
    };
    
    /**
     * Parsing & Compiling
     */
    
    function Parser(options) {
      this.tokens = [];
      this.token = null;
      this.options = options || marked.defaults;
      this.options.renderer = this.options.renderer || new Renderer;
      this.renderer = this.options.renderer;
      this.renderer.options = this.options;
    }
    
    /**
     * Static Parse Method
     */
    
    Parser.parse = function(src, options, renderer) {
      var parser = new Parser(options, renderer);
      return parser.parse(src);
    };
    
    /**
     * Parse Loop
     */
    
    Parser.prototype.parse = function(src) {
      this.inline = new InlineLexer(src.links, this.options, this.renderer);
      this.tokens = src.reverse();
    
      var out = '';
      while (this.next()) {
        out += this.tok();
      }
    
      return out;
    };
    
    /**
     * Next Token
     */
    
    Parser.prototype.next = function() {
      return this.token = this.tokens.pop();
    };
    
    /**
     * Preview Next Token
     */
    
    Parser.prototype.peek = function() {
      return this.tokens[this.tokens.length - 1] || 0;
    };
    
    /**
     * Parse Text Tokens
     */
    
    Parser.prototype.parseText = function() {
      var body = this.token.text;
    
      while (this.peek().type === 'text') {
        body += '\n' + this.next().text;
      }
    
      return this.inline.output(body);
    };
    
    /**
     * Parse Current Token
     */
    
    Parser.prototype.tok = function() {
      switch (this.token.type) {
        case 'space': {
          return '';
        }
        case 'hr': {
          return this.renderer.hr();
        }
        case 'heading': {
          return this.renderer.heading(
            this.inline.output(this.token.text),
            this.token.depth,
            this.token.text);
        }
        case 'code': {
          return this.renderer.code(this.token.text,
            this.token.lang,
            this.token.escaped);
        }
        case 'table': {
          var header = ''
            , body = ''
            , i
            , row
            , cell
            , flags
            , j;
    
          // header
          cell = '';
          for (i = 0; i < this.token.header.length; i++) {
            flags = { header: true, align: this.token.align[i] };
            cell += this.renderer.tablecell(
              this.inline.output(this.token.header[i]),
              { header: true, align: this.token.align[i] }
            );
          }
          header += this.renderer.tablerow(cell);
    
          for (i = 0; i < this.token.cells.length; i++) {
            row = this.token.cells[i];
    
            cell = '';
            for (j = 0; j < row.length; j++) {
              cell += this.renderer.tablecell(
                this.inline.output(row[j]),
                { header: false, align: this.token.align[j] }
              );
            }
    
            body += this.renderer.tablerow(cell);
          }
          return this.renderer.table(header, body);
        }
        case 'blockquote_start': {
          var body = '';
    
          while (this.next().type !== 'blockquote_end') {
            body += this.tok();
          }
    
          return this.renderer.blockquote(body);
        }
        case 'list_start': {
          var body = ''
            , ordered = this.token.ordered;
    
          while (this.next().type !== 'list_end') {
            body += this.tok();
          }
    
          return this.renderer.list(body, ordered);
        }
        case 'list_item_start': {
          var body = '';
    
          while (this.next().type !== 'list_item_end') {
            body += this.token.type === 'text'
              ? this.parseText()
              : this.tok();
          }
    
          return this.renderer.listitem(body);
        }
        case 'loose_item_start': {
          var body = '';
    
          while (this.next().type !== 'list_item_end') {
            body += this.tok();
          }
    
          return this.renderer.listitem(body);
        }
        case 'html': {
          var html = !this.token.pre && !this.options.pedantic
            ? this.inline.output(this.token.text)
            : this.token.text;
          return this.renderer.html(html);
        }
        case 'paragraph': {
          return this.renderer.paragraph(this.inline.output(this.token.text));
        }
        case 'text': {
          return this.renderer.paragraph(this.parseText());
        }
      }
    };
    
    /**
     * Helpers
     */
    
    function escape(html, encode) {
      return html
        .replace(!encode ? /&(?!#?\w+;)/g : /&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }
    
    function unescape(html) {
      return html.replace(/&([#\w]+);/g, function(_, n) {
        n = n.toLowerCase();
        if (n === 'colon') return ':';
        if (n.charAt(0) === '#') {
          return n.charAt(1) === 'x'
            ? String.fromCharCode(parseInt(n.substring(2), 16))
            : String.fromCharCode(+n.substring(1));
        }
        return '';
      });
    }
    
    function replace(regex, opt) {
      regex = regex.source;
      opt = opt || '';
      return function self(name, val) {
        if (!name) return new RegExp(regex, opt);
        val = val.source || val;
        val = val.replace(/(^|[^\[])\^/g, '$1');
        regex = regex.replace(name, val);
        return self;
      };
    }
    
    function noop() {}
    noop.exec = noop;
    
    function merge(obj) {
      var i = 1
        , target
        , key;
    
      for (; i < arguments.length; i++) {
        target = arguments[i];
        for (key in target) {
          if (Object.prototype.hasOwnProperty.call(target, key)) {
            obj[key] = target[key];
          }
        }
      }
    
      return obj;
    }
    
    
    /**
     * Marked
     */
    
    function marked(src, opt, callback) {
      if (callback || typeof opt === 'function') {
        if (!callback) {
          callback = opt;
          opt = null;
        }
    
        opt = merge({}, marked.defaults, opt || {});
    
        var highlight = opt.highlight
          , tokens
          , pending
          , i = 0;
    
        try {
          tokens = Lexer.lex(src, opt)
        } catch (e) {
          return callback(e);
        }
    
        pending = tokens.length;
    
        var done = function() {
          var out, err;
    
          try {
            out = Parser.parse(tokens, opt);
          } catch (e) {
            err = e;
          }
    
          opt.highlight = highlight;
    
          return err
            ? callback(err)
            : callback(null, out);
        };
    
        if (!highlight || highlight.length < 3) {
          return done();
        }
    
        delete opt.highlight;
    
        if (!pending) return done();
    
        for (; i < tokens.length; i++) {
          (function(token) {
            if (token.type !== 'code') {
              return --pending || done();
            }
            return highlight(token.text, token.lang, function(err, code) {
              if (code == null || code === token.text) {
                return --pending || done();
              }
              token.text = code;
              token.escaped = true;
              --pending || done();
            });
          })(tokens[i]);
        }
    
        return;
      }
      try {
        if (opt) opt = merge({}, marked.defaults, opt);
        return Parser.parse(Lexer.lex(src, opt), opt);
      } catch (e) {
        e.message += '\nPlease report this to https://github.com/chjj/marked.';
        if ((opt || marked.defaults).silent) {
          return '<p>An error occured:</p><pre>'
            + escape(e.message + '', true)
            + '</pre>';
        }
        throw e;
      }
    }
    
    /**
     * Options
     */
    
    marked.options =
    marked.setOptions = function(opt) {
      merge(marked.defaults, opt);
      return marked;
    };
    
    marked.defaults = {
      gfm: true,
      tables: true,
      breaks: false,
      pedantic: false,
      sanitize: false,
      smartLists: false,
      silent: false,
      highlight: null,
      langPrefix: 'lang-',
      smartypants: false,
      headerPrefix: '',
      renderer: new Renderer,
      xhtml: false
    };
    
    /**
     * Expose
     */
    
    marked.Parser = Parser;
    marked.parser = Parser.parse;
    
    marked.Renderer = Renderer;
    
    marked.Lexer = Lexer;
    marked.lexer = Lexer.lex;
    
    marked.InlineLexer = InlineLexer;
    marked.inlineLexer = InlineLexer.output;
    
    marked.parse = marked;
    
    if (typeof exports === 'object') {
      module.exports = marked;
    } else if (typeof define === 'function' && define.amd) {
      define(function() { return marked; });
    } else {
      this.marked = marked;
    }
    
    }).call(function() {
      return this || (typeof window !== 'undefined' ? window : global);
    }());
    
  };
  
  requires_['middleware'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var Middleware, pkgman,
        __slice = [].slice;
    
      pkgman = require('pkgman');
    
      exports.Middleware = Middleware = (function() {
        function Middleware() {
          this._dispatcher = function() {};
          this._middleware = [];
        }
    
        Middleware.prototype.use = function(fn) {
          return this._middleware.push(fn);
        };
    
        Middleware.prototype.dispatch = function(request, response, fn) {
          var index, invoke;
          index = 0;
          invoke = (function(_this) {
            return function(error) {
              var current;
              if (index === _this._middleware.length) {
                return fn(error);
              }
              current = _this._middleware[index];
              index += 1;
              if (current.length === 4) {
                if (error != null) {
                  try {
                    return current(error, request, response, function(error) {
                      return invoke(error);
                    });
                  } catch (_error) {
                    error = _error;
                    return invoke(error);
                  }
                } else {
                  return invoke(error);
                }
              } else {
                if (error != null) {
                  return invoke(error);
                } else {
                  try {
                    return current(request, response, function(error) {
                      return invoke(error);
                    });
                  } catch (_error) {
                    error = _error;
                    return invoke(error);
                  }
                }
              }
            };
          })(this);
          return invoke(null);
        };
    
        return Middleware;
    
      })();
    
      exports.fromHook = function() {
        var args, hook, hookResults, middleware, path, paths, _, _i, _j, _len, _len1, _ref, _ref1, _ref2;
        hook = arguments[0], paths = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
        args.unshift(hook);
        hookResults = pkgman.invoke.apply(pkgman, args);
        middleware = new Middleware;
        for (_i = 0, _len = paths.length; _i < _len; _i++) {
          path = paths[_i];
          _ref2 = (_ref = (_ref1 = hookResults[path]) != null ? _ref1.middleware : void 0) != null ? _ref : [];
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            _ = _ref2[_j];
            middleware.use(_);
          }
        }
        return middleware;
      };
    
    }).call(this);
    
  };
  
  requires_['packages/core/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$appConfig = function() {
        return [
          '$injector', '$routeProvider', '$locationProvider', 'pkgmanProvider', function($injector, $routeProvider, $locationProvider, pkgmanProvider) {
            var injected, path, route, routes, _, _fn, _ref;
            routes = pkgmanProvider.invokeWithMocks('route');
            _ref = pkgmanProvider.invokeWithMocks('routeAlter');
            for (_ in _ref) {
              injected = _ref[_];
              $injector.invoke(injected, null, {
                routes: routes
              });
            }
            _fn = function(path, route) {
              var routeController, _ref1;
              routeController = route.controller;
              route.controller = [
                '$injector', '$scope', 'ui/title', function($injector, $scope, title) {
                  var _ref1;
                  title.setPage((_ref1 = route.title) != null ? _ref1 : '');
                  return $injector.invoke(routeController, null, {
                    $scope: $scope
                  });
                }
              ];
              if (route.template == null) {
                route.template = ' ';
              }
              return $routeProvider.when("/" + ((_ref1 = route.path) != null ? _ref1 : path), route);
            };
            for (path in routes) {
              route = routes[path];
              _fn(path, route);
            }
            $routeProvider.when('/shrub-entry-point', {});
            return $locationProvider.html5Mode(true);
          }
        ];
      };
    
      exports.$appRun = function() {
        return [
          '$rootScope', '$location', '$window', 'socket', function($rootScope, $location, $window, socket) {
            $rootScope.$watch(function() {
              return $location.path();
            }, function() {
              var i, part, parts;
              parts = $location.path().substr(1).split('/');
              parts = (function() {
                var _i, _ref, _results;
                _results = [];
                for (i = _i = 1, _ref = parts.length; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
                  part = parts.slice(0, i).join('-');
                  _results.push(part.replace(/[^_a-zA-Z0-9-]/g, '-'));
                }
                return _results;
              })();
              return $rootScope.pathClass = parts.join(' ');
            });
            socket.on('core.navigateTo', function(href) {
              return $window.location.href = href;
            });
            return socket.on('core.reload', function() {
              return $window.location.reload();
            });
          }
        ];
      };
    
      exports.$routeMock = function() {
        return {
          path: 'e2e/sanity-check'
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/example/about'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$route = function() {
        return {
          path: 'about',
          title: 'About',
          controller: [
            '$scope', function($scope) {
              $scope.about = "Shrub\n=====\n\nShrub is a JavaScript (or CoffeeScript if you prefer) application\nframework. [AngularJS](http://angularjs.org/) is used on the client-side, as\nwell as [Socket.IO](http://socket.io/), enabling real-time communication right\nout of the box. The server is a [Node.js](http://nodejs.org/) server using\n[Redis](http://redis.io/) for persistence and scalability.\n\nShrub handles generation (using [Grunt](http://gruntjs.com/)) of the vast\nmajority of Angular boilerplate, to allow you to structure your application in\na very clean and consistent way.\n\nAlso provided is an Angular service providing a NodeJS-style module framework\nto allow your application to bridge the gap between Angular and the vast\necosystem of publically available NodeJS-style modules.\n\n### The Twist\n\nJS applications catch flak because they are not impliticly SEO-friendly,\nas well as requiring JS execution, which [some people prefer not to\nallow for untrusted websites](http://www.wired.com/threatlevel/2013/09/freedom-hosting-fbi/).\n\nShrub does an interesting thing which is possible because both sides of the\nstack have fully featured JS ([well, except for certain older browsers...](http://www.youtube.com/watch?v=lD9FAOPBiDk)).\nWhen a client requests a page from Shrub, it spins up a DOM for the request,\nand renders the entire page, JS and all. Shrub then serves the fully-built page\nto the client.\n\nIf the client has JS enabled, the client-side Angular application takes over\nfrom here, loading new pages (nearly) instantly and generally benefitting from\nall the lovely things that client-side applications offer.\n\nHowever, if the client does not have JS enabled, a new page will hit the server\nagain, and Shrub, crafty as it is, will reuse the DOM created for that session,\nnavigate Angular to the new page, render it, and serve it to the client. Nice! \n\n### Get rolling\n\n* Get yourself a clone: `$ git clone git://github.com/cha0s/shrub.git`\n\n* Get in the new directory and then the usual `npm install`, followed by\n`$ scripts/good-to-go`. This script will return 0 if the project builds, and\nthe tests run successfully. In other words, you can easily wire it up in a\npre-commit hook.\n\n* Spin up the server: `$ npm start` and navigate to http://localhost:4201 (make\nsure you've run grunt at least once!)\n\n* Check out how Shrub has generated a lot of Angular boilerplate for\nyou. Particularly app/js/{controllers,directives,filters,services}.js will\nbe of interest.\n\n### TODO\n\nThere is much to do, and this project is currently essentially a\nproof-of-concept of some of the ideas outlined here. My plans for this\nframework include:\n\n* Integration of a database abstraction layer\n* A resource layer (using the aforementioned db layer) for serving Angular $resource requests\n* Socket/Session stores based on aforementioned db layer\n* Better handling of server-side DOM in the absence of a session/cookie\n* Research into whether server-side rendering can be synchronized in a DRY fashion (currently the rendering is given 50 ms to complete, not ideal)\n* Better abstraction of assets, instead of (for instance) hardcoding bootstrap/LESS\n* Using standardized solutions to UI and Bootstrap interface, instead of the hackish half-hand-rolled solutions currently in place\n* Better abstraction of the RPC interface, allowing other systems beside Socket.IO\n* Research into whether the http server interface (currently using Express) is worth abstracting\n* There is a rudimentary working form API, but research should be done as to how to DRY it up and make sure it's secure and resistant to attack";
              return $scope.$emit('shrubFinishedRendering');
            }
          ],
          template: "\n<span\n	class=\"about\"\n	data-ng-bind-html=\"about | uiMarkdown:false\"\n></span>\n"
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/example/home'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$appConfig = function() {
        return [
          '$routeProvider', function($routeProvider) {
            return $routeProvider.otherwise({
              redirectTo: '/home'
            });
          }
        ];
      };
    
      exports.$route = function() {
        return {
          path: 'home',
          title: 'Home',
          controller: [
            '$scope', function($scope) {
              return $scope.$emit('shrubFinishedRendering');
            }
          ],
          template: "\n<div class=\"jumbotron\">\n	\n	<h1>Shrub</h1>\n	\n	<p class=\"lead\">Welcome to the example application for Shrub!</p>\n	\n	<hr>\n\n</div>\n"
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/example/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var path, _i, _len, _ref;
    
      exports.$appRun = function() {
        return [
          'ui/nav', 'ui/title', function(nav, title) {
            nav.setLinks([
              {
                pattern: '/home',
                href: '/home',
                name: 'Home'
              }, {
                pattern: '/about',
                href: '/about',
                name: 'About'
              }, {
                pattern: '/user/register',
                href: '/user/register',
                name: 'Sign up'
              }, {
                pattern: '/user/login',
                href: '/user/login',
                name: 'Sign in'
              }, {
                pattern: '/user/logout',
                href: '/user/logout',
                name: 'Sign out'
              }
            ]);
            return title.setSite('Shrub');
          }
        ];
      };
    
      _ref = ['about', 'home'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        path = _ref[_i];
        exports[path] = require("./" + path);
      }
    
    }).call(this);
    
  };
  
  requires_['packages/form/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$directive = function() {
        return [
          '$compile', '$injector', '$q', 'form', 'require', function($compile, $injector, $q, form, require) {
            return {
              link: function(scope, element, attrs) {
                var $field, $form, $formKeyElement, $input, $wrapper, field, formKey, formSpec, handler, name, _base, _ref;
                formKey = attrs['form'];
                if ((formSpec = scope[formKey]) == null) {
                  return;
                }
                $form = angular.element('<form>');
                $form = angular.element('<form>').attr({
                  'data-ng-submit': "" + formKey + ".submit.handler()",
                  method: (_ref = $form.attr('method')) != null ? _ref : 'POST'
                }).addClass(formKey);
                for (name in formSpec) {
                  field = formSpec[name];
                  if (field.type == null) {
                    continue;
                  }
                  $wrapper = angular.element('<div class="form-group">');
                  $wrapper.append($field = (function() {
                    var _ref1;
                    switch (field.type) {
                      case 'hidden':
                        scope[name] = field.value;
                        return angular.element('<input type="hidden">').attr({
                          name: name
                        });
                      case 'email':
                      case 'password':
                      case 'text':
                        if (field.label != null) {
                          $wrapper.append(angular.element('<label>').text(field.label));
                        }
                        $input = angular.element('<input type="' + field.type + '">').attr({
                          name: name,
                          'data-ng-model': name
                        }).addClass('form-control');
                        if (field.defaultValue != null) {
                          $input.attr('value', field.defaultValue);
                        }
                        if (field.required) {
                          $input.attr('required', 'required');
                        }
                        return $input;
                      case 'submit':
                        if (field.rpc != null) {
                          if (field.handler == null) {
                            field.handler = function() {};
                          }
                          handler = field.handler;
                          field.handler = function() {
                            var dottedFormKey, fields, i8n;
                            i8n = require('inflection');
                            dottedFormKey = i8n.underscore(formKey);
                            dottedFormKey = i8n.dasherize(dottedFormKey.toLowerCase());
                            dottedFormKey = dottedFormKey.replace('-', '.');
                            fields = {};
                            for (name in formSpec) {
                              field = formSpec[name];
                              if (field.type === 'submit') {
                                continue;
                              }
                              fields[name] = scope[name];
                            }
                            return $injector.invoke([
                              'rpc', function(rpc) {
                                return rpc.call(dottedFormKey, fields).then(function(result) {
                                  return handler(null, result);
                                }, function(error) {
                                  return handler(error);
                                });
                              }
                            ]);
                          };
                        }
                        $input = angular.element('<input type="submit">');
                        $input.attr('value', (_ref1 = field.label) != null ? _ref1 : "Submit");
                        return $input.addClass('btn btn-default');
                    }
                  })());
                  $form.append($wrapper);
                }
                $formKeyElement = angular.element('<input type="hidden"/>');
                $formKeyElement.attr({
                  name: 'formKey',
                  value: formKey
                });
                $form.append($formKeyElement);
                element.append($form);
                $compile($form)(scope);
                form.register(formKey, scope, $form);
                return (_base = (formSpec.submit != null ? formSpec.submit : formSpec.submit = {})).handler != null ? _base.handler : _base.handler = function() {
                  return $q.when(true);
                };
              }
            };
          }
        ];
      };
    
      exports.$service = function() {
        return [
          function() {
            var forms;
            forms = {};
            this.register = function(key, scope, element) {
              return forms[key] = {
                scope: scope,
                element: element
              };
            };
            this.lookup = function(key) {
              return forms[key];
            };
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/limiter/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var LimiterThresholdError, errors,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
    
      errors = require('errors');
    
      LimiterThresholdError = (function(_super) {
        __extends(LimiterThresholdError, _super);
    
        function LimiterThresholdError(message, time) {
          this.time = time;
          LimiterThresholdError.__super__.constructor.apply(this, arguments);
        }
    
        LimiterThresholdError.prototype.key = 'limiterThreshold';
    
        LimiterThresholdError.prototype.template = ":message You may try again :time.";
    
        LimiterThresholdError.prototype.toJSON = function() {
          return [this.key, this.message, this.time];
        };
    
        return LimiterThresholdError;
    
      })(errors.BaseError);
    
      exports.$errorType = function() {
        return LimiterThresholdError;
      };
    
    }).call(this);
    
  };
  
  requires_['packages/rpc/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var errors;
    
      errors = require('errors');
    
      exports.$appRun = function() {
        return [
          '$window', 'config', 'rpc', function($window, config, rpc) {
            if (!$window.navigator.userAgent.match(/^Node\.js .*$/)) {
              return rpc.call('hangup');
            }
          }
        ];
      };
    
      exports.$service = function() {
        return [
          '$injector', '$q', 'require', 'socket', function($injector, $q, require, socket) {
            var error, notifications, service;
            service = {};
            notifications = null;
            try {
              $injector.invoke([
                'ui/notifications', function(_notifications_) {
                  return notifications = _notifications_;
                }
              ]);
            } catch (_error) {
              error = _error;
            }
            service.call = function(route, data) {
              var deferred;
              deferred = $q.defer();
              socket.emit("rpc://" + route, data, function(_arg) {
                var error, result;
                error = _arg.error, result = _arg.result;
                if (error != null) {
                  error = errors.unserialize(errors.caught(error));
                  if (notifications != null) {
                    notifications.add({
                      "class": 'alert-danger',
                      text: errors.message(error)
                    });
                  }
                  return deferred.reject(error);
                } else {
                  return deferred.resolve(result);
                }
              });
              return deferred.promise;
            };
            return service;
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/schema/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$service = function() {
        return [
          '$http', 'config', 'require', function($http, config, require) {
            return require('schema-client').define(require('jugglingdb-rest'), {
              $http: $http,
              apiRoot: config.get('apiRoot')
            });
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/socket/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$service = function() {
        return [
          '$rootScope', 'config', function($rootScope, config) {
            var debugListeners, initializedQueue, service, socket;
            service = {};
            if ('unit' === config.get('testMode')) {
              return service;
            }
            socket = io.connect();
            initializedQueue = [];
            socket.on('initialized', (function(_this) {
              return function() {
                var args, _i, _len, _results;
                _results = [];
                for (_i = 0, _len = initializedQueue.length; _i < _len; _i++) {
                  args = initializedQueue[_i];
                  _results.push(service.emit.apply(_this, args));
                }
                return _results;
              };
            })(this));
            debugListeners = {};
            service.connect = function() {
              return socket.socket.connect();
            };
            service.connected = function() {
              return socket.socket.connected;
            };
            service.disconnect = function() {
              return socket.disconnect();
            };
            service.on = function(eventName, fn) {
              var _name;
              if (config.get('debugging')) {
                if (debugListeners[_name = "on-" + eventName] == null) {
                  debugListeners[_name] = (function() {
                    return socket.on(eventName, function(data) {
                      return console.debug("received: " + eventName + ", " + (JSON.stringify(data, null, '  ')));
                    });
                  })();
                }
              }
              return socket.on(eventName, function() {
                var onArguments;
                onArguments = arguments;
                return $rootScope.$apply(function() {
                  return fn.apply(socket, onArguments);
                });
              });
            };
            service.emit = function(eventName, data, fn) {
              if (!service.connected()) {
                return initializedQueue.push(arguments);
              }
              if (config.get('debugging')) {
                console.debug("sent: " + eventName + ", " + (JSON.stringify(data, null, '  ')));
              }
              return socket.emit(eventName, data, function() {
                var emitArguments;
                if (fn == null) {
                  return;
                }
                if (config.get('debugging')) {
                  console.debug("data from: " + eventName + ", " + (JSON.stringify(arguments, null, '  ')));
                }
                emitArguments = arguments;
                return $rootScope.$apply(function() {
                  return fn.apply(socket, emitArguments);
                });
              });
            };
            $rootScope.$on('debugLog', function(error) {
              return service.emit('debugLog', error);
            });
            return service;
          }
        ];
      };
    
      exports.$serviceMock = function() {
        return [
          '$q', '$rootScope', '$timeout', function($q, $rootScope, $timeout) {
            var emitMap, onMap, service;
            service = {};
            onMap = {};
            service.on = function(type, fn) {
              return (onMap[type] != null ? onMap[type] : onMap[type] = []).push(fn);
            };
            service.stimulateOn = function(type, data) {
              return $timeout(function() {
                var fn, _i, _len, _ref, _ref1, _results;
                _ref1 = (_ref = onMap[type]) != null ? _ref : [];
                _results = [];
                for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
                  fn = _ref1[_i];
                  _results.push(fn(data));
                }
                return _results;
              });
            };
            emitMap = {};
            service.catchEmit = function(type, fn) {
              return (emitMap[type] != null ? emitMap[type] : emitMap[type] = []).push(fn);
            };
            service.emit = function(type, data, done) {
              return $timeout(function() {
                var fn, _i, _len, _ref, _ref1, _results;
                _ref1 = (_ref = emitMap[type]) != null ? _ref : [];
                _results = [];
                for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
                  fn = _ref1[_i];
                  _results.push(fn(data, done));
                }
                return _results;
              });
            };
            return service;
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/ui/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var path, _i, _len, _ref;
    
      _ref = ['markdown', 'nav', 'notifications', 'title', 'window'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        path = _ref[_i];
        exports[path] = require("./" + path);
      }
    
    }).call(this);
    
  };
  
  requires_['packages/ui/markdown'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var marked;
    
      marked = require('marked');
    
      exports.$filter = function() {
        return function() {
          return function(input, sanitize) {
            if (sanitize == null) {
              sanitize = true;
            }
            return marked(input, {
              sanitize: sanitize
            });
          };
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/ui/nav'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$directive = function() {
        return [
          '$location', 'ui/nav', 'socket', 'ui/title', 'user', function($location, nav, socket, title, user) {
            return {
              link: function(scope, elm, attr) {
                var navActiveLinks;
                scope.navClass = attr['uiNav'] ? attr['uiNav'] : 'ui-nav';
                scope.links = nav.links;
                scope.user = user.instance();
                scope.$watch(function() {
                  return title.page();
                }, function() {
                  return scope.pageTitle = title.page();
                });
                (navActiveLinks = function() {
                  var link, path, regexp, _i, _len, _ref, _results;
                  path = $location.path();
                  _ref = scope.links();
                  _results = [];
                  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    link = _ref[_i];
                    regexp = new RegExp("^" + link.pattern + "$", ['i']);
                    _results.push(link.active = regexp.test(path) ? 'active' : void 0);
                  }
                  return _results;
                })();
                scope.$watch(function() {
                  return scope.links();
                }, navActiveLinks);
                return scope.$watch(function() {
                  return $location.path();
                }, navActiveLinks);
              },
              template: "\n<nav class=\"navbar navbar-default\" role=\"navigation\">\n	<div class=\"container-fluid\">\n		\n		<div class=\"navbar-header\">\n			<button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\".{{navClass}}\">\n				<span class=\"sr-only\">Toggle navigation</span>\n				<span class=\"icon-bar\"></span>\n				<span class=\"icon-bar\"></span>\n				<span class=\"icon-bar\"></span>\n			</button>\n\n			<a class=\"navbar-brand\" href=\"#\"><span data-ng-bind=\"pageTitle\"></span></a>\n			\n		</div>\n		\n		<div class=\"navbar-collapse collapse\" data-ng-class=\"navClass\">\n			<p class=\"navbar-text navbar-right identity-wrapper\">\n				<span class=\"identity\">\n					You are <span class=\"username\" data-ng-bind=\"user.name\"></span>\n				</span>\n			</p>\n			<ul class=\"nav navbar-nav navbar-right\">\n				<li data-ng-class=\"link.active\" data-match-route=\"{{link.pattern}}\" data-ng-repeat=\"link in links()\">\n					<a target=\"{{link.target}}\" data-ng-href=\"{{link.href}}\" data-ng-bind=\"link.name\"></a>\n				</li>\n			</ul>\n		</div>\n		\n	</div>\n</nav>\n"
            };
          }
        ];
      };
    
      exports.$service = function() {
        return [
          function() {
            var _links;
            _links = [];
            this.links = function() {
              return _links;
            };
            this.setLinks = function(links) {
              return _links = links;
            };
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/ui/notifications'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$directive = function() {
        return [
          '$timeout', 'ui/notifications', function($timeout, notifications) {
            return {
              link: function(scope, elm, attr) {
                var $notificationWrapper, activeNotification;
                activeNotification = null;
                $notificationWrapper = elm.find('.notification-wrapper');
                scope.close = function() {
                  $timeout.cancel(activeNotification);
                  $notificationWrapper.fadeOut('2000', function() {
                    return scope.$apply(function() {
                      return notifications.removeTop();
                    });
                  });
                };
                return scope.$watch(function() {
                  return notifications.top();
                }, function() {
                  scope.notification = notifications.top();
                  if (notifications.count() === 0) {
                    return;
                  }
                  $notificationWrapper.fadeIn('2000');
                  return activeNotification = $timeout(function() {
                    return scope.close();
                  }, 15000);
                });
              },
              template: "\n<div class=\"notification-wrapper\">\n	\n	<div\n		data-ng-show=\"!!notification\"\n		data-ng-class=\"notification.class\"\n		class=\"alert notification fade in\"\n	>\n		<button\n			type=\"button\"\n			class=\"close\"\n			data-ng-click=\"close()\"\n		>&times;</button>\n		<span data-ng-bind-html=\"notification.text\"></span>\n	</div>\n	\n</div>\n"
            };
          }
        ];
      };
    
      exports.$service = function() {
        return [
          'socket', function(socket) {
            var service, _notifications;
            _notifications = [];
            service = {};
            service.add = function(notification) {
              if (notification["class"] == null) {
                notification["class"] = 'alert-info';
              }
              return _notifications.push(notification);
            };
            service.top = function() {
              return _notifications[0];
            };
            service.removeTop = function() {
              return _notifications.shift();
            };
            service.count = function() {
              return _notifications.length;
            };
            socket.on('notifications', function(data) {
              var notification, _i, _len, _ref, _results;
              _ref = data.notifications;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                notification = _ref[_i];
                _results.push(service.add(notification));
              }
              return _results;
            });
            return service;
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/ui/title'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$directive = function() {
        return [
          'ui/title', function(title) {
            return {
              link: function(scope, elm, attr) {
                return scope.$watch(function() {
                  return title.window();
                }, function() {
                  return scope.windowTitle = title.window();
                });
              }
            };
          }
        ];
      };
    
      exports.$service = function() {
        return [
          '$rootScope', '$interval', function($rootScope, $interval) {
            var flashInProgress, _flashDownWrapper, _flashUpWrapper, _page, _separator, _site, _window, _windowWrapper;
            _page = '';
            this.page = function() {
              return _page;
            };
            this.setPage = function(page, setWindow) {
              if (setWindow == null) {
                setWindow = true;
              }
              _page = page;
              if (setWindow) {
                return this.setWindow([_page, _site].join(_separator));
              }
            };
            _separator = ' · ';
            this.separator = function() {
              return _separator;
            };
            this.setSeparator = function(separator) {
              return _separator = separator;
            };
            _site = '';
            this.site = function() {
              return _site;
            };
            this.setSite = function(site) {
              return _site = site;
            };
            _window = '';
            this.window = function() {
              return _windowWrapper(_window);
            };
            this.setWindow = function(window) {
              return _window = window;
            };
            _flashUpWrapper = function(text) {
              return "¯¯¯" + (text.toUpperCase()) + "¯¯¯";
            };
            _flashDownWrapper = function(text) {
              return "___" + text + "___";
            };
            _windowWrapper = angular.identity;
            flashInProgress = null;
            this.flash = function() {
              if (flashInProgress != null) {
                return;
              }
              return flashInProgress = $interval(function() {
                if (_windowWrapper === _flashUpWrapper) {
                  return _windowWrapper = _flashDownWrapper;
                } else {
                  return _windowWrapper = _flashUpWrapper;
                }
              }, 600);
            };
            this.stopFlashing = function() {
              if (flashInProgress != null) {
                $interval.cancel(flashInProgress);
              }
              flashInProgress = null;
              return _windowWrapper = angular.identity;
            };
            this.windowWrapper = function() {
              return _windowWrapper;
            };
            this.setWindowWrapper = function(windowWrapper) {
              return _windowWrapper = windowWrapper;
            };
            this.flashDownWrapper = function() {
              return _flashDownWrapper;
            };
            this.setFlashDownWrapper = function(flashDownWrapper) {
              return _flashDownWrapper = flashDownWrapper;
            };
            this.flashUpWrapper = function() {
              return _flashUpWrapper;
            };
            this.setFlashUpWrapper = function(flashUpWrapper) {
              return _flashUpWrapper = flashUpWrapper;
            };
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/ui/window'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$service = function() {
        return [
          '$rootScope', '$window', function($rootScope, $window) {
            var _isActive, _notifyOnClose;
            _isActive = true;
            angular.element($window).bind('focus', function() {
              return $rootScope.$apply(function() {
                return _isActive = true;
              });
            });
            angular.element($window).bind('blur', function() {
              return $rootScope.$apply(function() {
                return _isActive = false;
              });
            });
            this.isActive = function() {
              return _isActive;
            };
            _notifyOnClose = null;
            $window.onbeforeunload = function() {
              return _notifyOnClose;
            };
            this.notifyOnClose = function(notifyOnClose) {
              if (notifyOnClose == null) {
                notifyOnClose = true;
              }
              return _notifyOnClose = notifyOnClose ? true : null;
            };
          }
        ];
      };
    
    }).call(this);
    
  };
  
  requires_['packages/user/forgot'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var errors;
    
      errors = require('errors');
    
      exports.$route = function() {
        return {
          title: 'Forgot password',
          controller: [
            '$location', '$scope', 'ui/notifications', 'user', function($location, $scope, notifications, user) {
              if (user.isLoggedIn()) {
                return $location.path('/');
              }
              $scope.userForgot = {
                usernameOrEmail: {
                  type: 'text',
                  label: "Username or Email",
                  required: true
                },
                submit: {
                  type: 'submit',
                  label: "Email reset link",
                  rpc: true,
                  handler: function(error, result) {
                    if (error != null) {
                      return;
                    }
                    notifications.add({
                      text: "A reset link will be emailed."
                    });
                    return $location.path('/');
                  }
                }
              };
              return $scope.$emit('shrubFinishedRendering');
            }
          ],
          template: "\n<div data-form=\"userForgot\"></div>\n"
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/user/index'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var Promise, augmentModel, path, _i, _len, _ref;
    
      Promise = require('bluebird');
    
      exports.$models = function(schema) {
        var User;
        User = schema.define('User', {
          email: {
            type: String,
            index: true
          },
          iname: {
            type: String,
            length: 24,
            index: true
          },
          name: {
            type: String,
            "default": 'Anonymous',
            length: 24
          },
          passwordHash: {
            type: String
          },
          resetPasswordToken: {
            type: String,
            length: 48,
            index: true
          },
          salt: {
            type: String,
            length: 128
          }
        });
        User.prototype.hasPermission = function(perm) {
          return false;
        };
        User.prototype.isAccessibleBy = function(user) {
          return false;
        };
        return User.prototype.redactFor = function(user) {
          var redacted;
          redacted = {
            name: this.name,
            id: this.id,
            email: this.email
          };
          return Promise.resolve(redacted);
        };
      };
    
      augmentModel = function(User, Model, name) {
        var checkPermission, validateUser, _base, _base1, _base2, _base3;
        validateUser = function(user) {
          return new Promise(function(resolve, reject) {
            var error;
            if (user instanceof User) {
              return resolve();
            }
            error = new Error("Invalid user.");
            error.code = 500;
            return reject(error);
          });
        };
        checkPermission = function(user, perm) {
          return new Promise(function(resolve, reject) {
            var error;
            if (user.hasPermission(perm)) {
              return resolve();
            }
            error = new Error("Access denied.");
            error.code = 403;
            return reject(error);
          });
        };
        Model.authenticatedAll = function(user, params) {
          return validateUser(user).then(function() {
            return checkPermission(user, "schema:" + name + ":all");
          }).then(function() {
            return Model.all(params);
          }).then(function(models) {
            return models.filter(function(model) {
              return model.isAccessibleBy(user);
            });
          }).then(function(models) {
            return Promise.all(models.map(function(model) {
              return model.redactFor(user);
            }));
          }).then(function(models) {
            var error;
            if (models.length > 0) {
              return models;
            }
            error = new Error("Collection not found.");
            error.code = 404;
            return Promise.reject(error);
          });
        };
        Model.authenticatedCount = function(user) {
          return validateUser(user).then(function() {
            return checkPermission(user, "schema:" + name + ":count");
          }).then(function() {
            return Model.count();
          });
        };
        Model.authenticatedCreate = function(user, properties) {
          return validateUser(user).then(function() {
            return checkPermission(user, "schema:" + name + ":create");
          }).then(function() {
            return Model.create(properties);
          });
        };
        Model.authenticatedDestroy = function(user, id) {
          return validateUser(user).then(function() {
            return checkPermission(user, "schema:" + name + ":create");
          }).then(function() {
            return Model.authenticatedFind(user, id);
          }).then(function(model) {
            var error;
            if (model.isDeletableBy(user)) {
              return model.destroy();
            }
            if (model.isAccessibleBy(user)) {
              error = new Error("Access denied.");
              error.code = 403;
            } else {
              error = new Error("Resource not found.");
              error.code = 404;
            }
            return Promise.reject(error);
          });
        };
        Model.authenticatedDestroyAll = function(user) {
          return validateUser(user).then(function() {
            return checkPermission("schema:" + name + ":destroyAll");
          }).then(function() {
            return Model.destroyAll();
          });
        };
        Model.authenticatedFind = function(user, id) {
          return validateUser(user).then(function() {
            return Model.find(id);
          }).then(function(model) {
            var error;
            if ((model != null) && model.isAccessibleBy(user)) {
              return model.redactFor(user);
            }
            error = new Error("Resource not found.");
            error.code = 404;
            return Promise.reject(error);
          });
        };
        Model.authenticatedUpdate = function(user, id, properties) {
          return validateUser(user).then(function() {
            return Model.authenticatedFind(user, id);
          }).then(function(model) {
            var error;
            if (model.isEditableBy(user)) {
              return model.updateAttributes(properties);
            }
            if (model.isAccessibleBy(user)) {
              error = new Error("Access denied.");
              error.code = 403;
            } else {
              error = new Error("Resource not found.");
              error.code = 404;
            }
            return Promise.reject(error);
          });
        };
        if ((_base = Model.prototype).isAccessibleBy == null) {
          _base.isAccessibleBy = function(user) {
            return true;
          };
        }
        if ((_base1 = Model.prototype).isEditableBy == null) {
          _base1.isEditableBy = function(user) {
            return false;
          };
        }
        if ((_base2 = Model.prototype).isDeletableBy == null) {
          _base2.isDeletableBy = function(user) {
            return false;
          };
        }
        return (_base3 = Model.prototype).redactFor != null ? _base3.redactFor : _base3.redactFor = function(user) {
          return Promise.resolve(this);
        };
      };
    
      exports.$modelsAlter = function(models) {
        var Model, name, _results;
        _results = [];
        for (name in models) {
          Model = models[name];
          _results.push(augmentModel(models.User, Model, name));
        }
        return _results;
      };
    
      exports.$service = function() {
        return [
          '$q', 'config', 'rpc', 'schema', 'socket', function($q, config, rpc, schema, socket) {
            var isLoaded, logout, service, user;
            service = {};
            user = new schema.models.User;
            logout = function() {
              return user.fromObject((new schema.models.User).toObject());
            };
            socket.on('user.logout', logout);
            service.isLoggedIn = function() {
              return service.instance().id != null;
            };
            service.login = function(method, username, password) {
              return rpc.call('user.login', {
                method: method,
                username: username,
                password: password
              }).then(function(O) {
                user.fromObject(O);
                return user;
              });
            };
            service.logout = function() {
              return rpc.call('user.logout').then(logout);
            };
            isLoaded = false;
            service.instance = function() {
              if (!isLoaded) {
                isLoaded = true;
                user.fromObject(config.get('user'));
              }
              return user;
            };
            return service;
          }
        ];
      };
    
      exports.$serviceMock = function() {
        return [
          '$delegate', 'socket', function($delegate, socket) {
            $delegate.fakeLogin = function(username, password, id) {
              if (password == null) {
                password = 'password';
              }
              if (id == null) {
                id = 1;
              }
              socket.catchEmit('rpc://user.login', function(data, fn) {
                return fn({
                  result: {
                    id: id,
                    name: username
                  }
                });
              });
              return $delegate.login('local', username, password);
            };
            return $delegate;
          }
        ];
      };
    
      _ref = ['forgot', 'login', 'logout', 'register', 'reset'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        path = _ref[_i];
        exports[path] = require("./" + path);
      }
    
    }).call(this);
    
  };
  
  requires_['packages/user/login'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var LoginError, errors,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
    
      errors = require('errors');
    
      LoginError = LoginError = (function(_super) {
        __extends(LoginError, _super);
    
        function LoginError() {
          return LoginError.__super__.constructor.apply(this, arguments);
        }
    
        LoginError.prototype.key = 'login';
    
        LoginError.prototype.template = "No such username/password.";
    
        return LoginError;
    
      })(errors.BaseError);
    
      exports.e2eLogin = {
        $routeMock: function() {
          return {
            path: 'e2e/user/login/:destination',
            controller: [
              '$location', '$routeParams', '$scope', 'socket', 'user', function($location, $routeParams, $scope, socket, user) {
                return user.fakeLogin('cha0s').then(function() {
                  return $location.path("/user/" + $routeParams.destination);
                });
              }
            ]
          };
        }
      };
    
      exports.$errorType = function() {
        return LoginError;
      };
    
      exports.$route = function() {
        return {
          title: 'Sign in',
          controller: [
            '$location', '$scope', 'ui/notifications', 'user', function($location, $scope, notifications, user) {
              if (user.isLoggedIn()) {
                return $location.path('/');
              }
              $scope.userLogin = {
                username: {
                  type: 'text',
                  label: "Username",
                  required: true
                },
                password: {
                  type: 'password',
                  label: "Password",
                  required: true
                },
                submit: {
                  type: 'submit',
                  label: "Sign in",
                  handler: function() {
                    return user.login('local', $scope.username, $scope.password).then(function() {
                      notifications.add({
                        "class": 'alert-success',
                        text: "Logged in successfully."
                      });
                      return $location.path('/');
                    });
                  }
                }
              };
              return $scope.$emit('shrubFinishedRendering');
            }
          ],
          template: "\n<div data-form=\"userLogin\"></div>\n\n<a class=\"forgot\" href=\"/user/forgot\">Forgot your password?</a>\n"
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/user/logout'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      exports.$route = function() {
        return {
          controller: [
            '$location', '$q', 'user', function($location, $q, user) {
              if (!user.isLoggedIn()) {
                return $location.path('/');
              }
              return user.logout().then(function() {
                return $location.path('/');
              });
            }
          ]
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/user/register'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var errors;
    
      errors = require('errors');
    
      exports.$route = function() {
        return {
          title: 'Sign up',
          controller: [
            '$location', '$scope', 'ui/notifications', 'user', function($location, $scope, notifications, user) {
              if (user.isLoggedIn()) {
                return $location.path('/');
              }
              $scope.userRegister = {
                username: {
                  type: 'text',
                  label: "Username",
                  required: true
                },
                email: {
                  type: 'email',
                  label: "Email",
                  required: true
                },
                submit: {
                  type: 'submit',
                  label: "Register",
                  rpc: true,
                  handler: function(error, result) {
                    if (error != null) {
                      return;
                    }
                    notifications.add({
                      text: "An email has been sent with account registration details. Please check your email."
                    });
                    return $location.path('/');
                  }
                }
              };
              return $scope.$emit('shrubFinishedRendering');
            }
          ],
          template: "\n<div data-form=\"userRegister\"></div>\n"
        };
      };
    
    }).call(this);
    
  };
  
  requires_['packages/user/reset'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var errors;
    
      errors = require('errors');
    
      exports.$route = function() {
        return {
          path: 'user/reset/:token',
          title: 'Reset your password',
          controller: [
            '$location', '$routeParams', '$scope', 'ui/notifications', function($location, $routeParams, $scope, notifications) {
              $scope.userReset = {
                password: {
                  type: 'password',
                  label: "New password",
                  required: true
                },
                token: {
                  type: 'hidden',
                  value: $routeParams.token
                },
                submit: {
                  type: 'submit',
                  label: "Reset password",
                  rpc: true,
                  handler: function(error, result) {
                    if (error != null) {
                      return;
                    }
                    notifications.add({
                      text: "You may now log in with your new password."
                    });
                    return $location.path('/user/login');
                  }
                }
              };
              return $scope.$emit('shrubFinishedRendering');
            }
          ],
          template: "\n<div data-form=\"userReset\"></div>\n"
        };
      };
    
    }).call(this);
    
  };
  
  requires_['path'] = function(module, exports, require, __dirname, __filename) {
  
    !function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.path=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
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
    
    },{}],2:[function(_dereq_,module,exports){
    (function (process){
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
    
    // resolves . and .. elements in a path array with directory names there
    // must be no slashes, empty elements, or device names (c:\) in the array
    // (so also no leading and trailing slashes - it does not distinguish
    // relative and absolute paths)
    function normalizeArray(parts, allowAboveRoot) {
      // if the path tries to go above the root, `up` ends up > 0
      var up = 0;
      for (var i = parts.length - 1; i >= 0; i--) {
        var last = parts[i];
        if (last === '.') {
          parts.splice(i, 1);
        } else if (last === '..') {
          parts.splice(i, 1);
          up++;
        } else if (up) {
          parts.splice(i, 1);
          up--;
        }
      }
    
      // if the path is allowed to go above the root, restore leading ..s
      if (allowAboveRoot) {
        for (; up--; up) {
          parts.unshift('..');
        }
      }
    
      return parts;
    }
    
    // Split a filename into [root, dir, basename, ext], unix version
    // 'root' is just a slash, or nothing.
    var splitPathRe =
        /^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
    var splitPath = function(filename) {
      return splitPathRe.exec(filename).slice(1);
    };
    
    // path.resolve([from ...], to)
    // posix version
    exports.resolve = function() {
      var resolvedPath = '',
          resolvedAbsolute = false;
    
      for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
        var path = (i >= 0) ? arguments[i] : process.cwd();
    
        // Skip empty and invalid entries
        if (typeof path !== 'string') {
          throw new TypeError('Arguments to path.resolve must be strings');
        } else if (!path) {
          continue;
        }
    
        resolvedPath = path + '/' + resolvedPath;
        resolvedAbsolute = path.charAt(0) === '/';
      }
    
      // At this point the path should be resolved to a full absolute path, but
      // handle relative paths to be safe (might happen when process.cwd() fails)
    
      // Normalize the path
      resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
        return !!p;
      }), !resolvedAbsolute).join('/');
    
      return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
    };
    
    // path.normalize(path)
    // posix version
    exports.normalize = function(path) {
      var isAbsolute = exports.isAbsolute(path),
          trailingSlash = substr(path, -1) === '/';
    
      // Normalize the path
      path = normalizeArray(filter(path.split('/'), function(p) {
        return !!p;
      }), !isAbsolute).join('/');
    
      if (!path && !isAbsolute) {
        path = '.';
      }
      if (path && trailingSlash) {
        path += '/';
      }
    
      return (isAbsolute ? '/' : '') + path;
    };
    
    // posix version
    exports.isAbsolute = function(path) {
      return path.charAt(0) === '/';
    };
    
    // posix version
    exports.join = function() {
      var paths = Array.prototype.slice.call(arguments, 0);
      return exports.normalize(filter(paths, function(p, index) {
        if (typeof p !== 'string') {
          throw new TypeError('Arguments to path.join must be strings');
        }
        return p;
      }).join('/'));
    };
    
    
    // path.relative(from, to)
    // posix version
    exports.relative = function(from, to) {
      from = exports.resolve(from).substr(1);
      to = exports.resolve(to).substr(1);
    
      function trim(arr) {
        var start = 0;
        for (; start < arr.length; start++) {
          if (arr[start] !== '') break;
        }
    
        var end = arr.length - 1;
        for (; end >= 0; end--) {
          if (arr[end] !== '') break;
        }
    
        if (start > end) return [];
        return arr.slice(start, end - start + 1);
      }
    
      var fromParts = trim(from.split('/'));
      var toParts = trim(to.split('/'));
    
      var length = Math.min(fromParts.length, toParts.length);
      var samePartsLength = length;
      for (var i = 0; i < length; i++) {
        if (fromParts[i] !== toParts[i]) {
          samePartsLength = i;
          break;
        }
      }
    
      var outputParts = [];
      for (var i = samePartsLength; i < fromParts.length; i++) {
        outputParts.push('..');
      }
    
      outputParts = outputParts.concat(toParts.slice(samePartsLength));
    
      return outputParts.join('/');
    };
    
    exports.sep = '/';
    exports.delimiter = ':';
    
    exports.dirname = function(path) {
      var result = splitPath(path),
          root = result[0],
          dir = result[1];
    
      if (!root && !dir) {
        // No dirname whatsoever
        return '.';
      }
    
      if (dir) {
        // It has a dirname, strip trailing slash
        dir = dir.substr(0, dir.length - 1);
      }
    
      return root + dir;
    };
    
    
    exports.basename = function(path, ext) {
      var f = splitPath(path)[2];
      // TODO: make this comparison case-insensitive on windows?
      if (ext && f.substr(-1 * ext.length) === ext) {
        f = f.substr(0, f.length - ext.length);
      }
      return f;
    };
    
    
    exports.extname = function(path) {
      return splitPath(path)[3];
    };
    
    function filter (xs, f) {
        if (xs.filter) return xs.filter(f);
        var res = [];
        for (var i = 0; i < xs.length; i++) {
            if (f(xs[i], i, xs)) res.push(xs[i]);
        }
        return res;
    }
    
    // String.prototype.substr - negative index don't work in IE8
    var substr = 'ab'.substr(-1) === 'b'
        ? function (str, start, len) { return str.substr(start, len) }
        : function (str, start, len) {
            if (start < 0) start = str.length + start;
            return str.substr(start, len);
        }
    ;
    
    }).call(this,_dereq_("/home/cha0s6983/dev/code/js/reddichat/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
    },{"/home/cha0s6983/dev/code/js/reddichat/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1}]},{},[2])
    (2)
    });
  };
  
  requires_['pkgman'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var packageCache, _packages,
        __slice = [].slice;
    
      packageCache = null;
    
      _packages = [];
    
      exports.rebuildPackageCache = function() {
        var error, name, package_, _i, _len;
        packageCache = {};
        for (_i = 0, _len = _packages.length; _i < _len; _i++) {
          name = _packages[_i];
          try {
            package_ = require("packages/" + name);
          } catch (_error) {
            error = _error;
            if (error.toString() === ("Error: Cannot find module 'packages/" + name + "'")) {
              continue;
            }
            throw error;
          }
          packageCache[name] = package_;
        }
      };
    
      exports.registerPackages = function(packages) {
        _packages.push.apply(_packages, packages);
        return exports.rebuildPackageCache();
      };
    
      exports.invoke = function() {
        var args, hook, invokeRecursive, name, package_, results;
        hook = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (packageCache == null) {
          exports.rebuildPackageCache();
        }
        results = {};
        invokeRecursive = function(path, parent) {
          var key, objectOrFunction, _results;
          _results = [];
          for (key in parent) {
            objectOrFunction = parent[key];
            if (key.charCodeAt(0) === '$'.charCodeAt(0)) {
              if (key === ("$" + hook)) {
                _results.push(results[path] = objectOrFunction.apply(null, args));
              } else {
                _results.push(void 0);
              }
            } else {
              _results.push(invokeRecursive("" + path + "/" + key, objectOrFunction));
            }
          }
          return _results;
        };
        for (name in packageCache) {
          package_ = packageCache[name];
          invokeRecursive(name, package_);
        }
        return results;
      };
    
    }).call(this);
    
  };
  
  requires_['schema-client'] = function(module, exports, require, __dirname, __filename) {
  
    (function() {
      var Schema, i8n, pkgman;
    
      i8n = require('inflection');
    
      pkgman = require('pkgman');
    
      Schema = (require('jugglingdb-client')).Schema;
    
      Schema.prototype.resourcePaths = function(name) {
        var resource;
        resource = i8n.underscore(name);
        resource = i8n.dasherize(resource.toLowerCase());
        return {
          resource: resource,
          collection: i8n.pluralize(resource)
        };
      };
    
      exports.define = function(adapter, options) {
        var schema;
        if (options == null) {
          options = {};
        }
        schema = new Schema(adapter, options);
        pkgman.invoke('models', schema);
        pkgman.invoke('modelsAlter', schema.models, schema);
        return schema;
      };
    
    }).call(this);
    
  };
  
  requires_['underscore'] = function(module, exports, require, __dirname, __filename) {
  
    //     Underscore.js 1.6.0
    //     http://underscorejs.org
    //     (c) 2009-2014 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
    //     Underscore may be freely distributed under the MIT license.
    
    (function() {
    
      // Baseline setup
      // --------------
    
      // Establish the root object, `window` in the browser, or `exports` on the server.
      var root = this;
    
      // Save the previous value of the `_` variable.
      var previousUnderscore = root._;
    
      // Establish the object that gets returned to break out of a loop iteration.
      var breaker = {};
    
      // Save bytes in the minified (but not gzipped) version:
      var ArrayProto = Array.prototype, ObjProto = Object.prototype, FuncProto = Function.prototype;
    
      // Create quick reference variables for speed access to core prototypes.
      var
        push             = ArrayProto.push,
        slice            = ArrayProto.slice,
        concat           = ArrayProto.concat,
        toString         = ObjProto.toString,
        hasOwnProperty   = ObjProto.hasOwnProperty;
    
      // All **ECMAScript 5** native function implementations that we hope to use
      // are declared here.
      var
        nativeForEach      = ArrayProto.forEach,
        nativeMap          = ArrayProto.map,
        nativeReduce       = ArrayProto.reduce,
        nativeReduceRight  = ArrayProto.reduceRight,
        nativeFilter       = ArrayProto.filter,
        nativeEvery        = ArrayProto.every,
        nativeSome         = ArrayProto.some,
        nativeIndexOf      = ArrayProto.indexOf,
        nativeLastIndexOf  = ArrayProto.lastIndexOf,
        nativeIsArray      = Array.isArray,
        nativeKeys         = Object.keys,
        nativeBind         = FuncProto.bind;
    
      // Create a safe reference to the Underscore object for use below.
      var _ = function(obj) {
        if (obj instanceof _) return obj;
        if (!(this instanceof _)) return new _(obj);
        this._wrapped = obj;
      };
    
      // Export the Underscore object for **Node.js**, with
      // backwards-compatibility for the old `require()` API. If we're in
      // the browser, add `_` as a global object via a string identifier,
      // for Closure Compiler "advanced" mode.
      if (typeof exports !== 'undefined') {
        if (typeof module !== 'undefined' && module.exports) {
          exports = module.exports = _;
        }
        exports._ = _;
      } else {
        root._ = _;
      }
    
      // Current version.
      _.VERSION = '1.6.0';
    
      // Collection Functions
      // --------------------
    
      // The cornerstone, an `each` implementation, aka `forEach`.
      // Handles objects with the built-in `forEach`, arrays, and raw objects.
      // Delegates to **ECMAScript 5**'s native `forEach` if available.
      var each = _.each = _.forEach = function(obj, iterator, context) {
        if (obj == null) return obj;
        if (nativeForEach && obj.forEach === nativeForEach) {
          obj.forEach(iterator, context);
        } else if (obj.length === +obj.length) {
          for (var i = 0, length = obj.length; i < length; i++) {
            if (iterator.call(context, obj[i], i, obj) === breaker) return;
          }
        } else {
          var keys = _.keys(obj);
          for (var i = 0, length = keys.length; i < length; i++) {
            if (iterator.call(context, obj[keys[i]], keys[i], obj) === breaker) return;
          }
        }
        return obj;
      };
    
      // Return the results of applying the iterator to each element.
      // Delegates to **ECMAScript 5**'s native `map` if available.
      _.map = _.collect = function(obj, iterator, context) {
        var results = [];
        if (obj == null) return results;
        if (nativeMap && obj.map === nativeMap) return obj.map(iterator, context);
        each(obj, function(value, index, list) {
          results.push(iterator.call(context, value, index, list));
        });
        return results;
      };
    
      var reduceError = 'Reduce of empty array with no initial value';
    
      // **Reduce** builds up a single result from a list of values, aka `inject`,
      // or `foldl`. Delegates to **ECMAScript 5**'s native `reduce` if available.
      _.reduce = _.foldl = _.inject = function(obj, iterator, memo, context) {
        var initial = arguments.length > 2;
        if (obj == null) obj = [];
        if (nativeReduce && obj.reduce === nativeReduce) {
          if (context) iterator = _.bind(iterator, context);
          return initial ? obj.reduce(iterator, memo) : obj.reduce(iterator);
        }
        each(obj, function(value, index, list) {
          if (!initial) {
            memo = value;
            initial = true;
          } else {
            memo = iterator.call(context, memo, value, index, list);
          }
        });
        if (!initial) throw new TypeError(reduceError);
        return memo;
      };
    
      // The right-associative version of reduce, also known as `foldr`.
      // Delegates to **ECMAScript 5**'s native `reduceRight` if available.
      _.reduceRight = _.foldr = function(obj, iterator, memo, context) {
        var initial = arguments.length > 2;
        if (obj == null) obj = [];
        if (nativeReduceRight && obj.reduceRight === nativeReduceRight) {
          if (context) iterator = _.bind(iterator, context);
          return initial ? obj.reduceRight(iterator, memo) : obj.reduceRight(iterator);
        }
        var length = obj.length;
        if (length !== +length) {
          var keys = _.keys(obj);
          length = keys.length;
        }
        each(obj, function(value, index, list) {
          index = keys ? keys[--length] : --length;
          if (!initial) {
            memo = obj[index];
            initial = true;
          } else {
            memo = iterator.call(context, memo, obj[index], index, list);
          }
        });
        if (!initial) throw new TypeError(reduceError);
        return memo;
      };
    
      // Return the first value which passes a truth test. Aliased as `detect`.
      _.find = _.detect = function(obj, predicate, context) {
        var result;
        any(obj, function(value, index, list) {
          if (predicate.call(context, value, index, list)) {
            result = value;
            return true;
          }
        });
        return result;
      };
    
      // Return all the elements that pass a truth test.
      // Delegates to **ECMAScript 5**'s native `filter` if available.
      // Aliased as `select`.
      _.filter = _.select = function(obj, predicate, context) {
        var results = [];
        if (obj == null) return results;
        if (nativeFilter && obj.filter === nativeFilter) return obj.filter(predicate, context);
        each(obj, function(value, index, list) {
          if (predicate.call(context, value, index, list)) results.push(value);
        });
        return results;
      };
    
      // Return all the elements for which a truth test fails.
      _.reject = function(obj, predicate, context) {
        return _.filter(obj, function(value, index, list) {
          return !predicate.call(context, value, index, list);
        }, context);
      };
    
      // Determine whether all of the elements match a truth test.
      // Delegates to **ECMAScript 5**'s native `every` if available.
      // Aliased as `all`.
      _.every = _.all = function(obj, predicate, context) {
        predicate || (predicate = _.identity);
        var result = true;
        if (obj == null) return result;
        if (nativeEvery && obj.every === nativeEvery) return obj.every(predicate, context);
        each(obj, function(value, index, list) {
          if (!(result = result && predicate.call(context, value, index, list))) return breaker;
        });
        return !!result;
      };
    
      // Determine if at least one element in the object matches a truth test.
      // Delegates to **ECMAScript 5**'s native `some` if available.
      // Aliased as `any`.
      var any = _.some = _.any = function(obj, predicate, context) {
        predicate || (predicate = _.identity);
        var result = false;
        if (obj == null) return result;
        if (nativeSome && obj.some === nativeSome) return obj.some(predicate, context);
        each(obj, function(value, index, list) {
          if (result || (result = predicate.call(context, value, index, list))) return breaker;
        });
        return !!result;
      };
    
      // Determine if the array or object contains a given value (using `===`).
      // Aliased as `include`.
      _.contains = _.include = function(obj, target) {
        if (obj == null) return false;
        if (nativeIndexOf && obj.indexOf === nativeIndexOf) return obj.indexOf(target) != -1;
        return any(obj, function(value) {
          return value === target;
        });
      };
    
      // Invoke a method (with arguments) on every item in a collection.
      _.invoke = function(obj, method) {
        var args = slice.call(arguments, 2);
        var isFunc = _.isFunction(method);
        return _.map(obj, function(value) {
          return (isFunc ? method : value[method]).apply(value, args);
        });
      };
    
      // Convenience version of a common use case of `map`: fetching a property.
      _.pluck = function(obj, key) {
        return _.map(obj, _.property(key));
      };
    
      // Convenience version of a common use case of `filter`: selecting only objects
      // containing specific `key:value` pairs.
      _.where = function(obj, attrs) {
        return _.filter(obj, _.matches(attrs));
      };
    
      // Convenience version of a common use case of `find`: getting the first object
      // containing specific `key:value` pairs.
      _.findWhere = function(obj, attrs) {
        return _.find(obj, _.matches(attrs));
      };
    
      // Return the maximum element or (element-based computation).
      // Can't optimize arrays of integers longer than 65,535 elements.
      // See [WebKit Bug 80797](https://bugs.webkit.org/show_bug.cgi?id=80797)
      _.max = function(obj, iterator, context) {
        if (!iterator && _.isArray(obj) && obj[0] === +obj[0] && obj.length < 65535) {
          return Math.max.apply(Math, obj);
        }
        var result = -Infinity, lastComputed = -Infinity;
        each(obj, function(value, index, list) {
          var computed = iterator ? iterator.call(context, value, index, list) : value;
          if (computed > lastComputed) {
            result = value;
            lastComputed = computed;
          }
        });
        return result;
      };
    
      // Return the minimum element (or element-based computation).
      _.min = function(obj, iterator, context) {
        if (!iterator && _.isArray(obj) && obj[0] === +obj[0] && obj.length < 65535) {
          return Math.min.apply(Math, obj);
        }
        var result = Infinity, lastComputed = Infinity;
        each(obj, function(value, index, list) {
          var computed = iterator ? iterator.call(context, value, index, list) : value;
          if (computed < lastComputed) {
            result = value;
            lastComputed = computed;
          }
        });
        return result;
      };
    
      // Shuffle an array, using the modern version of the
      // [Fisher-Yates shuffle](http://en.wikipedia.org/wiki/Fisher–Yates_shuffle).
      _.shuffle = function(obj) {
        var rand;
        var index = 0;
        var shuffled = [];
        each(obj, function(value) {
          rand = _.random(index++);
          shuffled[index - 1] = shuffled[rand];
          shuffled[rand] = value;
        });
        return shuffled;
      };
    
      // Sample **n** random values from a collection.
      // If **n** is not specified, returns a single random element.
      // The internal `guard` argument allows it to work with `map`.
      _.sample = function(obj, n, guard) {
        if (n == null || guard) {
          if (obj.length !== +obj.length) obj = _.values(obj);
          return obj[_.random(obj.length - 1)];
        }
        return _.shuffle(obj).slice(0, Math.max(0, n));
      };
    
      // An internal function to generate lookup iterators.
      var lookupIterator = function(value) {
        if (value == null) return _.identity;
        if (_.isFunction(value)) return value;
        return _.property(value);
      };
    
      // Sort the object's values by a criterion produced by an iterator.
      _.sortBy = function(obj, iterator, context) {
        iterator = lookupIterator(iterator);
        return _.pluck(_.map(obj, function(value, index, list) {
          return {
            value: value,
            index: index,
            criteria: iterator.call(context, value, index, list)
          };
        }).sort(function(left, right) {
          var a = left.criteria;
          var b = right.criteria;
          if (a !== b) {
            if (a > b || a === void 0) return 1;
            if (a < b || b === void 0) return -1;
          }
          return left.index - right.index;
        }), 'value');
      };
    
      // An internal function used for aggregate "group by" operations.
      var group = function(behavior) {
        return function(obj, iterator, context) {
          var result = {};
          iterator = lookupIterator(iterator);
          each(obj, function(value, index) {
            var key = iterator.call(context, value, index, obj);
            behavior(result, key, value);
          });
          return result;
        };
      };
    
      // Groups the object's values by a criterion. Pass either a string attribute
      // to group by, or a function that returns the criterion.
      _.groupBy = group(function(result, key, value) {
        _.has(result, key) ? result[key].push(value) : result[key] = [value];
      });
    
      // Indexes the object's values by a criterion, similar to `groupBy`, but for
      // when you know that your index values will be unique.
      _.indexBy = group(function(result, key, value) {
        result[key] = value;
      });
    
      // Counts instances of an object that group by a certain criterion. Pass
      // either a string attribute to count by, or a function that returns the
      // criterion.
      _.countBy = group(function(result, key) {
        _.has(result, key) ? result[key]++ : result[key] = 1;
      });
    
      // Use a comparator function to figure out the smallest index at which
      // an object should be inserted so as to maintain order. Uses binary search.
      _.sortedIndex = function(array, obj, iterator, context) {
        iterator = lookupIterator(iterator);
        var value = iterator.call(context, obj);
        var low = 0, high = array.length;
        while (low < high) {
          var mid = (low + high) >>> 1;
          iterator.call(context, array[mid]) < value ? low = mid + 1 : high = mid;
        }
        return low;
      };
    
      // Safely create a real, live array from anything iterable.
      _.toArray = function(obj) {
        if (!obj) return [];
        if (_.isArray(obj)) return slice.call(obj);
        if (obj.length === +obj.length) return _.map(obj, _.identity);
        return _.values(obj);
      };
    
      // Return the number of elements in an object.
      _.size = function(obj) {
        if (obj == null) return 0;
        return (obj.length === +obj.length) ? obj.length : _.keys(obj).length;
      };
    
      // Array Functions
      // ---------------
    
      // Get the first element of an array. Passing **n** will return the first N
      // values in the array. Aliased as `head` and `take`. The **guard** check
      // allows it to work with `_.map`.
      _.first = _.head = _.take = function(array, n, guard) {
        if (array == null) return void 0;
        if ((n == null) || guard) return array[0];
        if (n < 0) return [];
        return slice.call(array, 0, n);
      };
    
      // Returns everything but the last entry of the array. Especially useful on
      // the arguments object. Passing **n** will return all the values in
      // the array, excluding the last N. The **guard** check allows it to work with
      // `_.map`.
      _.initial = function(array, n, guard) {
        return slice.call(array, 0, array.length - ((n == null) || guard ? 1 : n));
      };
    
      // Get the last element of an array. Passing **n** will return the last N
      // values in the array. The **guard** check allows it to work with `_.map`.
      _.last = function(array, n, guard) {
        if (array == null) return void 0;
        if ((n == null) || guard) return array[array.length - 1];
        return slice.call(array, Math.max(array.length - n, 0));
      };
    
      // Returns everything but the first entry of the array. Aliased as `tail` and `drop`.
      // Especially useful on the arguments object. Passing an **n** will return
      // the rest N values in the array. The **guard**
      // check allows it to work with `_.map`.
      _.rest = _.tail = _.drop = function(array, n, guard) {
        return slice.call(array, (n == null) || guard ? 1 : n);
      };
    
      // Trim out all falsy values from an array.
      _.compact = function(array) {
        return _.filter(array, _.identity);
      };
    
      // Internal implementation of a recursive `flatten` function.
      var flatten = function(input, shallow, output) {
        if (shallow && _.every(input, _.isArray)) {
          return concat.apply(output, input);
        }
        each(input, function(value) {
          if (_.isArray(value) || _.isArguments(value)) {
            shallow ? push.apply(output, value) : flatten(value, shallow, output);
          } else {
            output.push(value);
          }
        });
        return output;
      };
    
      // Flatten out an array, either recursively (by default), or just one level.
      _.flatten = function(array, shallow) {
        return flatten(array, shallow, []);
      };
    
      // Return a version of the array that does not contain the specified value(s).
      _.without = function(array) {
        return _.difference(array, slice.call(arguments, 1));
      };
    
      // Split an array into two arrays: one whose elements all satisfy the given
      // predicate, and one whose elements all do not satisfy the predicate.
      _.partition = function(array, predicate, context) {
        predicate = lookupIterator(predicate);
        var pass = [], fail = [];
        each(array, function(elem) {
          (predicate.call(context, elem) ? pass : fail).push(elem);
        });
        return [pass, fail];
      };
    
      // Produce a duplicate-free version of the array. If the array has already
      // been sorted, you have the option of using a faster algorithm.
      // Aliased as `unique`.
      _.uniq = _.unique = function(array, isSorted, iterator, context) {
        if (_.isFunction(isSorted)) {
          context = iterator;
          iterator = isSorted;
          isSorted = false;
        }
        var initial = iterator ? _.map(array, iterator, context) : array;
        var results = [];
        var seen = [];
        each(initial, function(value, index) {
          if (isSorted ? (!index || seen[seen.length - 1] !== value) : !_.contains(seen, value)) {
            seen.push(value);
            results.push(array[index]);
          }
        });
        return results;
      };
    
      // Produce an array that contains the union: each distinct element from all of
      // the passed-in arrays.
      _.union = function() {
        return _.uniq(_.flatten(arguments, true));
      };
    
      // Produce an array that contains every item shared between all the
      // passed-in arrays.
      _.intersection = function(array) {
        var rest = slice.call(arguments, 1);
        return _.filter(_.uniq(array), function(item) {
          return _.every(rest, function(other) {
            return _.contains(other, item);
          });
        });
      };
    
      // Take the difference between one array and a number of other arrays.
      // Only the elements present in just the first array will remain.
      _.difference = function(array) {
        var rest = concat.apply(ArrayProto, slice.call(arguments, 1));
        return _.filter(array, function(value){ return !_.contains(rest, value); });
      };
    
      // Zip together multiple lists into a single array -- elements that share
      // an index go together.
      _.zip = function() {
        var length = _.max(_.pluck(arguments, 'length').concat(0));
        var results = new Array(length);
        for (var i = 0; i < length; i++) {
          results[i] = _.pluck(arguments, '' + i);
        }
        return results;
      };
    
      // Converts lists into objects. Pass either a single array of `[key, value]`
      // pairs, or two parallel arrays of the same length -- one of keys, and one of
      // the corresponding values.
      _.object = function(list, values) {
        if (list == null) return {};
        var result = {};
        for (var i = 0, length = list.length; i < length; i++) {
          if (values) {
            result[list[i]] = values[i];
          } else {
            result[list[i][0]] = list[i][1];
          }
        }
        return result;
      };
    
      // If the browser doesn't supply us with indexOf (I'm looking at you, **MSIE**),
      // we need this function. Return the position of the first occurrence of an
      // item in an array, or -1 if the item is not included in the array.
      // Delegates to **ECMAScript 5**'s native `indexOf` if available.
      // If the array is large and already in sort order, pass `true`
      // for **isSorted** to use binary search.
      _.indexOf = function(array, item, isSorted) {
        if (array == null) return -1;
        var i = 0, length = array.length;
        if (isSorted) {
          if (typeof isSorted == 'number') {
            i = (isSorted < 0 ? Math.max(0, length + isSorted) : isSorted);
          } else {
            i = _.sortedIndex(array, item);
            return array[i] === item ? i : -1;
          }
        }
        if (nativeIndexOf && array.indexOf === nativeIndexOf) return array.indexOf(item, isSorted);
        for (; i < length; i++) if (array[i] === item) return i;
        return -1;
      };
    
      // Delegates to **ECMAScript 5**'s native `lastIndexOf` if available.
      _.lastIndexOf = function(array, item, from) {
        if (array == null) return -1;
        var hasIndex = from != null;
        if (nativeLastIndexOf && array.lastIndexOf === nativeLastIndexOf) {
          return hasIndex ? array.lastIndexOf(item, from) : array.lastIndexOf(item);
        }
        var i = (hasIndex ? from : array.length);
        while (i--) if (array[i] === item) return i;
        return -1;
      };
    
      // Generate an integer Array containing an arithmetic progression. A port of
      // the native Python `range()` function. See
      // [the Python documentation](http://docs.python.org/library/functions.html#range).
      _.range = function(start, stop, step) {
        if (arguments.length <= 1) {
          stop = start || 0;
          start = 0;
        }
        step = arguments[2] || 1;
    
        var length = Math.max(Math.ceil((stop - start) / step), 0);
        var idx = 0;
        var range = new Array(length);
    
        while(idx < length) {
          range[idx++] = start;
          start += step;
        }
    
        return range;
      };
    
      // Function (ahem) Functions
      // ------------------
    
      // Reusable constructor function for prototype setting.
      var ctor = function(){};
    
      // Create a function bound to a given object (assigning `this`, and arguments,
      // optionally). Delegates to **ECMAScript 5**'s native `Function.bind` if
      // available.
      _.bind = function(func, context) {
        var args, bound;
        if (nativeBind && func.bind === nativeBind) return nativeBind.apply(func, slice.call(arguments, 1));
        if (!_.isFunction(func)) throw new TypeError;
        args = slice.call(arguments, 2);
        return bound = function() {
          if (!(this instanceof bound)) return func.apply(context, args.concat(slice.call(arguments)));
          ctor.prototype = func.prototype;
          var self = new ctor;
          ctor.prototype = null;
          var result = func.apply(self, args.concat(slice.call(arguments)));
          if (Object(result) === result) return result;
          return self;
        };
      };
    
      // Partially apply a function by creating a version that has had some of its
      // arguments pre-filled, without changing its dynamic `this` context. _ acts
      // as a placeholder, allowing any combination of arguments to be pre-filled.
      _.partial = function(func) {
        var boundArgs = slice.call(arguments, 1);
        return function() {
          var position = 0;
          var args = boundArgs.slice();
          for (var i = 0, length = args.length; i < length; i++) {
            if (args[i] === _) args[i] = arguments[position++];
          }
          while (position < arguments.length) args.push(arguments[position++]);
          return func.apply(this, args);
        };
      };
    
      // Bind a number of an object's methods to that object. Remaining arguments
      // are the method names to be bound. Useful for ensuring that all callbacks
      // defined on an object belong to it.
      _.bindAll = function(obj) {
        var funcs = slice.call(arguments, 1);
        if (funcs.length === 0) throw new Error('bindAll must be passed function names');
        each(funcs, function(f) { obj[f] = _.bind(obj[f], obj); });
        return obj;
      };
    
      // Memoize an expensive function by storing its results.
      _.memoize = function(func, hasher) {
        var memo = {};
        hasher || (hasher = _.identity);
        return function() {
          var key = hasher.apply(this, arguments);
          return _.has(memo, key) ? memo[key] : (memo[key] = func.apply(this, arguments));
        };
      };
    
      // Delays a function for the given number of milliseconds, and then calls
      // it with the arguments supplied.
      _.delay = function(func, wait) {
        var args = slice.call(arguments, 2);
        return setTimeout(function(){ return func.apply(null, args); }, wait);
      };
    
      // Defers a function, scheduling it to run after the current call stack has
      // cleared.
      _.defer = function(func) {
        return _.delay.apply(_, [func, 1].concat(slice.call(arguments, 1)));
      };
    
      // Returns a function, that, when invoked, will only be triggered at most once
      // during a given window of time. Normally, the throttled function will run
      // as much as it can, without ever going more than once per `wait` duration;
      // but if you'd like to disable the execution on the leading edge, pass
      // `{leading: false}`. To disable execution on the trailing edge, ditto.
      _.throttle = function(func, wait, options) {
        var context, args, result;
        var timeout = null;
        var previous = 0;
        options || (options = {});
        var later = function() {
          previous = options.leading === false ? 0 : _.now();
          timeout = null;
          result = func.apply(context, args);
          context = args = null;
        };
        return function() {
          var now = _.now();
          if (!previous && options.leading === false) previous = now;
          var remaining = wait - (now - previous);
          context = this;
          args = arguments;
          if (remaining <= 0) {
            clearTimeout(timeout);
            timeout = null;
            previous = now;
            result = func.apply(context, args);
            context = args = null;
          } else if (!timeout && options.trailing !== false) {
            timeout = setTimeout(later, remaining);
          }
          return result;
        };
      };
    
      // Returns a function, that, as long as it continues to be invoked, will not
      // be triggered. The function will be called after it stops being called for
      // N milliseconds. If `immediate` is passed, trigger the function on the
      // leading edge, instead of the trailing.
      _.debounce = function(func, wait, immediate) {
        var timeout, args, context, timestamp, result;
    
        var later = function() {
          var last = _.now() - timestamp;
          if (last < wait) {
            timeout = setTimeout(later, wait - last);
          } else {
            timeout = null;
            if (!immediate) {
              result = func.apply(context, args);
              context = args = null;
            }
          }
        };
    
        return function() {
          context = this;
          args = arguments;
          timestamp = _.now();
          var callNow = immediate && !timeout;
          if (!timeout) {
            timeout = setTimeout(later, wait);
          }
          if (callNow) {
            result = func.apply(context, args);
            context = args = null;
          }
    
          return result;
        };
      };
    
      // Returns a function that will be executed at most one time, no matter how
      // often you call it. Useful for lazy initialization.
      _.once = function(func) {
        var ran = false, memo;
        return function() {
          if (ran) return memo;
          ran = true;
          memo = func.apply(this, arguments);
          func = null;
          return memo;
        };
      };
    
      // Returns the first function passed as an argument to the second,
      // allowing you to adjust arguments, run code before and after, and
      // conditionally execute the original function.
      _.wrap = function(func, wrapper) {
        return _.partial(wrapper, func);
      };
    
      // Returns a function that is the composition of a list of functions, each
      // consuming the return value of the function that follows.
      _.compose = function() {
        var funcs = arguments;
        return function() {
          var args = arguments;
          for (var i = funcs.length - 1; i >= 0; i--) {
            args = [funcs[i].apply(this, args)];
          }
          return args[0];
        };
      };
    
      // Returns a function that will only be executed after being called N times.
      _.after = function(times, func) {
        return function() {
          if (--times < 1) {
            return func.apply(this, arguments);
          }
        };
      };
    
      // Object Functions
      // ----------------
    
      // Retrieve the names of an object's properties.
      // Delegates to **ECMAScript 5**'s native `Object.keys`
      _.keys = function(obj) {
        if (!_.isObject(obj)) return [];
        if (nativeKeys) return nativeKeys(obj);
        var keys = [];
        for (var key in obj) if (_.has(obj, key)) keys.push(key);
        return keys;
      };
    
      // Retrieve the values of an object's properties.
      _.values = function(obj) {
        var keys = _.keys(obj);
        var length = keys.length;
        var values = new Array(length);
        for (var i = 0; i < length; i++) {
          values[i] = obj[keys[i]];
        }
        return values;
      };
    
      // Convert an object into a list of `[key, value]` pairs.
      _.pairs = function(obj) {
        var keys = _.keys(obj);
        var length = keys.length;
        var pairs = new Array(length);
        for (var i = 0; i < length; i++) {
          pairs[i] = [keys[i], obj[keys[i]]];
        }
        return pairs;
      };
    
      // Invert the keys and values of an object. The values must be serializable.
      _.invert = function(obj) {
        var result = {};
        var keys = _.keys(obj);
        for (var i = 0, length = keys.length; i < length; i++) {
          result[obj[keys[i]]] = keys[i];
        }
        return result;
      };
    
      // Return a sorted list of the function names available on the object.
      // Aliased as `methods`
      _.functions = _.methods = function(obj) {
        var names = [];
        for (var key in obj) {
          if (_.isFunction(obj[key])) names.push(key);
        }
        return names.sort();
      };
    
      // Extend a given object with all the properties in passed-in object(s).
      _.extend = function(obj) {
        each(slice.call(arguments, 1), function(source) {
          if (source) {
            for (var prop in source) {
              obj[prop] = source[prop];
            }
          }
        });
        return obj;
      };
    
      // Return a copy of the object only containing the whitelisted properties.
      _.pick = function(obj) {
        var copy = {};
        var keys = concat.apply(ArrayProto, slice.call(arguments, 1));
        each(keys, function(key) {
          if (key in obj) copy[key] = obj[key];
        });
        return copy;
      };
    
       // Return a copy of the object without the blacklisted properties.
      _.omit = function(obj) {
        var copy = {};
        var keys = concat.apply(ArrayProto, slice.call(arguments, 1));
        for (var key in obj) {
          if (!_.contains(keys, key)) copy[key] = obj[key];
        }
        return copy;
      };
    
      // Fill in a given object with default properties.
      _.defaults = function(obj) {
        each(slice.call(arguments, 1), function(source) {
          if (source) {
            for (var prop in source) {
              if (obj[prop] === void 0) obj[prop] = source[prop];
            }
          }
        });
        return obj;
      };
    
      // Create a (shallow-cloned) duplicate of an object.
      _.clone = function(obj) {
        if (!_.isObject(obj)) return obj;
        return _.isArray(obj) ? obj.slice() : _.extend({}, obj);
      };
    
      // Invokes interceptor with the obj, and then returns obj.
      // The primary purpose of this method is to "tap into" a method chain, in
      // order to perform operations on intermediate results within the chain.
      _.tap = function(obj, interceptor) {
        interceptor(obj);
        return obj;
      };
    
      // Internal recursive comparison function for `isEqual`.
      var eq = function(a, b, aStack, bStack) {
        // Identical objects are equal. `0 === -0`, but they aren't identical.
        // See the [Harmony `egal` proposal](http://wiki.ecmascript.org/doku.php?id=harmony:egal).
        if (a === b) return a !== 0 || 1 / a == 1 / b;
        // A strict comparison is necessary because `null == undefined`.
        if (a == null || b == null) return a === b;
        // Unwrap any wrapped objects.
        if (a instanceof _) a = a._wrapped;
        if (b instanceof _) b = b._wrapped;
        // Compare `[[Class]]` names.
        var className = toString.call(a);
        if (className != toString.call(b)) return false;
        switch (className) {
          // Strings, numbers, dates, and booleans are compared by value.
          case '[object String]':
            // Primitives and their corresponding object wrappers are equivalent; thus, `"5"` is
            // equivalent to `new String("5")`.
            return a == String(b);
          case '[object Number]':
            // `NaN`s are equivalent, but non-reflexive. An `egal` comparison is performed for
            // other numeric values.
            return a != +a ? b != +b : (a == 0 ? 1 / a == 1 / b : a == +b);
          case '[object Date]':
          case '[object Boolean]':
            // Coerce dates and booleans to numeric primitive values. Dates are compared by their
            // millisecond representations. Note that invalid dates with millisecond representations
            // of `NaN` are not equivalent.
            return +a == +b;
          // RegExps are compared by their source patterns and flags.
          case '[object RegExp]':
            return a.source == b.source &&
                   a.global == b.global &&
                   a.multiline == b.multiline &&
                   a.ignoreCase == b.ignoreCase;
        }
        if (typeof a != 'object' || typeof b != 'object') return false;
        // Assume equality for cyclic structures. The algorithm for detecting cyclic
        // structures is adapted from ES 5.1 section 15.12.3, abstract operation `JO`.
        var length = aStack.length;
        while (length--) {
          // Linear search. Performance is inversely proportional to the number of
          // unique nested structures.
          if (aStack[length] == a) return bStack[length] == b;
        }
        // Objects with different constructors are not equivalent, but `Object`s
        // from different frames are.
        var aCtor = a.constructor, bCtor = b.constructor;
        if (aCtor !== bCtor && !(_.isFunction(aCtor) && (aCtor instanceof aCtor) &&
                                 _.isFunction(bCtor) && (bCtor instanceof bCtor))
                            && ('constructor' in a && 'constructor' in b)) {
          return false;
        }
        // Add the first object to the stack of traversed objects.
        aStack.push(a);
        bStack.push(b);
        var size = 0, result = true;
        // Recursively compare objects and arrays.
        if (className == '[object Array]') {
          // Compare array lengths to determine if a deep comparison is necessary.
          size = a.length;
          result = size == b.length;
          if (result) {
            // Deep compare the contents, ignoring non-numeric properties.
            while (size--) {
              if (!(result = eq(a[size], b[size], aStack, bStack))) break;
            }
          }
        } else {
          // Deep compare objects.
          for (var key in a) {
            if (_.has(a, key)) {
              // Count the expected number of properties.
              size++;
              // Deep compare each member.
              if (!(result = _.has(b, key) && eq(a[key], b[key], aStack, bStack))) break;
            }
          }
          // Ensure that both objects contain the same number of properties.
          if (result) {
            for (key in b) {
              if (_.has(b, key) && !(size--)) break;
            }
            result = !size;
          }
        }
        // Remove the first object from the stack of traversed objects.
        aStack.pop();
        bStack.pop();
        return result;
      };
    
      // Perform a deep comparison to check if two objects are equal.
      _.isEqual = function(a, b) {
        return eq(a, b, [], []);
      };
    
      // Is a given array, string, or object empty?
      // An "empty" object has no enumerable own-properties.
      _.isEmpty = function(obj) {
        if (obj == null) return true;
        if (_.isArray(obj) || _.isString(obj)) return obj.length === 0;
        for (var key in obj) if (_.has(obj, key)) return false;
        return true;
      };
    
      // Is a given value a DOM element?
      _.isElement = function(obj) {
        return !!(obj && obj.nodeType === 1);
      };
    
      // Is a given value an array?
      // Delegates to ECMA5's native Array.isArray
      _.isArray = nativeIsArray || function(obj) {
        return toString.call(obj) == '[object Array]';
      };
    
      // Is a given variable an object?
      _.isObject = function(obj) {
        return obj === Object(obj);
      };
    
      // Add some isType methods: isArguments, isFunction, isString, isNumber, isDate, isRegExp.
      each(['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp'], function(name) {
        _['is' + name] = function(obj) {
          return toString.call(obj) == '[object ' + name + ']';
        };
      });
    
      // Define a fallback version of the method in browsers (ahem, IE), where
      // there isn't any inspectable "Arguments" type.
      if (!_.isArguments(arguments)) {
        _.isArguments = function(obj) {
          return !!(obj && _.has(obj, 'callee'));
        };
      }
    
      // Optimize `isFunction` if appropriate.
      if (typeof (/./) !== 'function') {
        _.isFunction = function(obj) {
          return typeof obj === 'function';
        };
      }
    
      // Is a given object a finite number?
      _.isFinite = function(obj) {
        return isFinite(obj) && !isNaN(parseFloat(obj));
      };
    
      // Is the given value `NaN`? (NaN is the only number which does not equal itself).
      _.isNaN = function(obj) {
        return _.isNumber(obj) && obj != +obj;
      };
    
      // Is a given value a boolean?
      _.isBoolean = function(obj) {
        return obj === true || obj === false || toString.call(obj) == '[object Boolean]';
      };
    
      // Is a given value equal to null?
      _.isNull = function(obj) {
        return obj === null;
      };
    
      // Is a given variable undefined?
      _.isUndefined = function(obj) {
        return obj === void 0;
      };
    
      // Shortcut function for checking if an object has a given property directly
      // on itself (in other words, not on a prototype).
      _.has = function(obj, key) {
        return hasOwnProperty.call(obj, key);
      };
    
      // Utility Functions
      // -----------------
    
      // Run Underscore.js in *noConflict* mode, returning the `_` variable to its
      // previous owner. Returns a reference to the Underscore object.
      _.noConflict = function() {
        root._ = previousUnderscore;
        return this;
      };
    
      // Keep the identity function around for default iterators.
      _.identity = function(value) {
        return value;
      };
    
      _.constant = function(value) {
        return function () {
          return value;
        };
      };
    
      _.property = function(key) {
        return function(obj) {
          return obj[key];
        };
      };
    
      // Returns a predicate for checking whether an object has a given set of `key:value` pairs.
      _.matches = function(attrs) {
        return function(obj) {
          if (obj === attrs) return true; //avoid comparing an object to itself.
          for (var key in attrs) {
            if (attrs[key] !== obj[key])
              return false;
          }
          return true;
        }
      };
    
      // Run a function **n** times.
      _.times = function(n, iterator, context) {
        var accum = Array(Math.max(0, n));
        for (var i = 0; i < n; i++) accum[i] = iterator.call(context, i);
        return accum;
      };
    
      // Return a random integer between min and max (inclusive).
      _.random = function(min, max) {
        if (max == null) {
          max = min;
          min = 0;
        }
        return min + Math.floor(Math.random() * (max - min + 1));
      };
    
      // A (possibly faster) way to get the current timestamp as an integer.
      _.now = Date.now || function() { return new Date().getTime(); };
    
      // List of HTML entities for escaping.
      var entityMap = {
        escape: {
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          '"': '&quot;',
          "'": '&#x27;'
        }
      };
      entityMap.unescape = _.invert(entityMap.escape);
    
      // Regexes containing the keys and values listed immediately above.
      var entityRegexes = {
        escape:   new RegExp('[' + _.keys(entityMap.escape).join('') + ']', 'g'),
        unescape: new RegExp('(' + _.keys(entityMap.unescape).join('|') + ')', 'g')
      };
    
      // Functions for escaping and unescaping strings to/from HTML interpolation.
      _.each(['escape', 'unescape'], function(method) {
        _[method] = function(string) {
          if (string == null) return '';
          return ('' + string).replace(entityRegexes[method], function(match) {
            return entityMap[method][match];
          });
        };
      });
    
      // If the value of the named `property` is a function then invoke it with the
      // `object` as context; otherwise, return it.
      _.result = function(object, property) {
        if (object == null) return void 0;
        var value = object[property];
        return _.isFunction(value) ? value.call(object) : value;
      };
    
      // Add your own custom functions to the Underscore object.
      _.mixin = function(obj) {
        each(_.functions(obj), function(name) {
          var func = _[name] = obj[name];
          _.prototype[name] = function() {
            var args = [this._wrapped];
            push.apply(args, arguments);
            return result.call(this, func.apply(_, args));
          };
        });
      };
    
      // Generate a unique integer id (unique within the entire client session).
      // Useful for temporary DOM ids.
      var idCounter = 0;
      _.uniqueId = function(prefix) {
        var id = ++idCounter + '';
        return prefix ? prefix + id : id;
      };
    
      // By default, Underscore uses ERB-style template delimiters, change the
      // following template settings to use alternative delimiters.
      _.templateSettings = {
        evaluate    : /<%([\s\S]+?)%>/g,
        interpolate : /<%=([\s\S]+?)%>/g,
        escape      : /<%-([\s\S]+?)%>/g
      };
    
      // When customizing `templateSettings`, if you don't want to define an
      // interpolation, evaluation or escaping regex, we need one that is
      // guaranteed not to match.
      var noMatch = /(.)^/;
    
      // Certain characters need to be escaped so that they can be put into a
      // string literal.
      var escapes = {
        "'":      "'",
        '\\':     '\\',
        '\r':     'r',
        '\n':     'n',
        '\t':     't',
        '\u2028': 'u2028',
        '\u2029': 'u2029'
      };
    
      var escaper = /\\|'|\r|\n|\t|\u2028|\u2029/g;
    
      // JavaScript micro-templating, similar to John Resig's implementation.
      // Underscore templating handles arbitrary delimiters, preserves whitespace,
      // and correctly escapes quotes within interpolated code.
      _.template = function(text, data, settings) {
        var render;
        settings = _.defaults({}, settings, _.templateSettings);
    
        // Combine delimiters into one regular expression via alternation.
        var matcher = new RegExp([
          (settings.escape || noMatch).source,
          (settings.interpolate || noMatch).source,
          (settings.evaluate || noMatch).source
        ].join('|') + '|$', 'g');
    
        // Compile the template source, escaping string literals appropriately.
        var index = 0;
        var source = "__p+='";
        text.replace(matcher, function(match, escape, interpolate, evaluate, offset) {
          source += text.slice(index, offset)
            .replace(escaper, function(match) { return '\\' + escapes[match]; });
    
          if (escape) {
            source += "'+\n((__t=(" + escape + "))==null?'':_.escape(__t))+\n'";
          }
          if (interpolate) {
            source += "'+\n((__t=(" + interpolate + "))==null?'':__t)+\n'";
          }
          if (evaluate) {
            source += "';\n" + evaluate + "\n__p+='";
          }
          index = offset + match.length;
          return match;
        });
        source += "';\n";
    
        // If a variable is not specified, place data values in local scope.
        if (!settings.variable) source = 'with(obj||{}){\n' + source + '}\n';
    
        source = "var __t,__p='',__j=Array.prototype.join," +
          "print=function(){__p+=__j.call(arguments,'');};\n" +
          source + "return __p;\n";
    
        try {
          render = new Function(settings.variable || 'obj', '_', source);
        } catch (e) {
          e.source = source;
          throw e;
        }
    
        if (data) return render(data, _);
        var template = function(data) {
          return render.call(this, data, _);
        };
    
        // Provide the compiled function source as a convenience for precompilation.
        template.source = 'function(' + (settings.variable || 'obj') + '){\n' + source + '}';
    
        return template;
      };
    
      // Add a "chain" function, which will delegate to the wrapper.
      _.chain = function(obj) {
        return _(obj).chain();
      };
    
      // OOP
      // ---------------
      // If Underscore is called as a function, it returns a wrapped object that
      // can be used OO-style. This wrapper holds altered versions of all the
      // underscore functions. Wrapped objects may be chained.
    
      // Helper function to continue chaining intermediate results.
      var result = function(obj) {
        return this._chain ? _(obj).chain() : obj;
      };
    
      // Add all of the Underscore functions to the wrapper object.
      _.mixin(_);
    
      // Add all mutator Array functions to the wrapper.
      each(['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], function(name) {
        var method = ArrayProto[name];
        _.prototype[name] = function() {
          var obj = this._wrapped;
          method.apply(obj, arguments);
          if ((name == 'shift' || name == 'splice') && obj.length === 0) delete obj[0];
          return result.call(this, obj);
        };
      });
    
      // Add all accessor Array functions to the wrapper.
      each(['concat', 'join', 'slice'], function(name) {
        var method = ArrayProto[name];
        _.prototype[name] = function() {
          return result.call(this, method.apply(this._wrapped, arguments));
        };
      });
    
      _.extend(_.prototype, {
    
        // Start chaining a wrapped Underscore object.
        chain: function() {
          this._chain = true;
          return this;
        },
    
        // Extracts the result from a wrapped and chained object.
        value: function() {
          return this._wrapped;
        }
    
      });
    
      // AMD registration happens at the end for compatibility with AMD loaders
      // that may not enforce next-turn semantics on modules. Even though general
      // practice for AMD registration is to be anonymous, underscore registers
      // as a named module because, like jQuery, it is a base library that is
      // popular enough to be bundled in a third party lib, but not be part of
      // an AMD load request. Those cases could generate an error when an
      // anonymous define() is called outside of a loader request.
      if (typeof define === 'function' && define.amd) {
        define('underscore', [], function() {
          return _;
        });
      }
    }).call(this);
    
  };
  
  (function() {
    var __slice = [].slice;
  
    angular.module('shrub.packages', ['shrub.require', 'shrub.pkgman']).config([
      '$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'configProvider', 'pkgmanProvider', 'requireProvider', function($compileProvider, $controllerProvider, $filterProvider, $provide, configProvider, pkgmanProvider, requireProvider) {
        var i8n, injected, normalize, path, require, _ref, _ref1, _ref2, _ref3, _ref4, _results;
        require = requireProvider.require;
        i8n = require('inflection');
        normalize = function(path) {
          var i, part, parts;
          parts = (function() {
            var _i, _len, _ref, _results;
            _ref = path.split('/');
            _results = [];
            for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
              part = _ref[i];
              _results.push(i8n.camelize(part.replace(/[^\w]/g, '_'), 0 === i));
            }
            return _results;
          })();
          return i8n.camelize(i8n.underscore(parts.join('')), true);
        };
        _ref = pkgmanProvider.invokeWithMocks('controller');
        for (path in _ref) {
          injected = _ref[path];
          $controllerProvider.register(path, injected);
        }
        _ref1 = pkgmanProvider.invokeWithMocks('directive');
        for (path in _ref1) {
          injected = _ref1[path];
          $compileProvider.directive(normalize(path), injected);
        }
        _ref2 = pkgmanProvider.invokeWithMocks('filter');
        for (path in _ref2) {
          injected = _ref2[path];
          $filterProvider.register(normalize(path), injected);
        }
        _ref3 = pkgmanProvider.invoke('service');
        for (path in _ref3) {
          injected = _ref3[path];
          $provide.service(path, injected);
        }
        if (configProvider.get('testMode')) {
          _ref4 = pkgmanProvider.invoke('serviceMock');
          _results = [];
          for (path in _ref4) {
            injected = _ref4[path];
            _results.push($provide.decorator(path, injected));
          }
          return _results;
        }
      }
    ]);
  
    angular.module('shrub.pkgman', ['shrub.require']).provider('pkgman', [
      '$provide', 'configProvider', 'requireProvider', function($provide, configProvider, requireProvider) {
        var pkgman, require, service, _;
        require = requireProvider.require;
        _ = require('underscore');
        pkgman = require('pkgman');
        pkgman.registerPackages(configProvider.get('packageList'));
        service = {};
        service.invoke = function() {
          var args, hook;
          hook = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          args.unshift(hook);
          return pkgman.invoke.apply(pkgman, args);
        };
        service.invokeWithMocks = function() {
          var args, hook, results;
          hook = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          args.unshift(hook);
          results = this.invoke.apply(this, args);
          if (configProvider.get('testMode')) {
            args[0] = "" + hook + "Mock";
            _.extend(results, pkgman.invoke.apply(pkgman, args));
          }
          return results;
        };
        service.$get = function() {
          return service;
        };
        return service;
      }
    ]);
  
  }).call(this);
  
  (function() {
    var require, _require, _resolveModuleName;
  
    _resolveModuleName = function(name, parentFilename) {
      var checkModuleName, checked, path;
      checkModuleName = function(name) {
        if (requires_[name]) {
          return name;
        }
        if (requires_["" + name + "/index"] != null) {
          return "" + name + "/index";
        }
      };
      if ((checked = checkModuleName(name)) != null) {
        return checked;
      }
      path = _require('path');
      if ((checked = checkModuleName(path.resolve(path.dirname(parentFilename), name).substr(1))) != null) {
        return checked;
      }
      throw new Error("Cannot find module '" + name + "'");
    };
  
    _require = function(name, parentFilename) {
      var exports, f, module, path, __dirname, __filename, _ref;
      name = _resolveModuleName(name, parentFilename);
      if (requires_[name].module == null) {
        exports = {};
        module = {
          exports: exports
        };
        f = requires_[name];
        requires_[name] = {
          module: module
        };
        path = _require('path');
        __dirname = (_ref = typeof path.dirname === "function" ? path.dirname(name) : void 0) != null ? _ref : '';
        __filename = name;
        f(module, exports, function(name) {
          return _require(name, __filename);
        }, __dirname, __filename);
      }
      return requires_[name].module.exports;
    };
  
    require = function(name) {
      return _require(name, '');
    };
  
    angular.module('shrub.require', []).provider('require', function() {
      return {
        require: require,
        $get: function() {
          return require;
        }
      };
    });
  
  }).call(this);
  
})();
