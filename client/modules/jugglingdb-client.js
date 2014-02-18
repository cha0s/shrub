(function(e){if("function"==typeof bootstrap)bootstrap("jugglingdb",e);else if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else if("undefined"!=typeof ses){if(!ses.ok())return;ses.makeJugglingdb=e}else"undefined"!=typeof window?window.jugglingdb=e():global.jugglingdb=e()})(function(){var define,ses,bootstrap,module,exports;
return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var global=typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},__dirname="/";var fs = require('fs');
var path = require('path');

exports.Schema = require('./lib/schema').Schema;
exports.AbstractClass = require('./lib/model.js');

var baseSQL = './lib/sql';

exports.__defineGetter__('BaseSQL', function () {
    return require(baseSQL);
});

exports.init = function (rw) {
    if (global.railway) {
        global.railway.orm = exports;
    } else {
        rw.orm = {Schema: exports.Schema, AbstractClass: exports.AbstractClass};
    }
    var railway = './lib/railway';

    if (rw.version > '1.1.5-15') {
        rw.on('after routes', initialize);
    } else {
        initialize();
    }

    function initialize() {
        try {
            var init = require(railway);
        } catch (e) {}
        if (init) init(rw);
    }
};

exports.__defineGetter__('version', function () {
    return JSON.parse(fs.readFileSync(__dirname + '/package.json')).version;
});

var commonTest = './test/common_test';
exports.__defineGetter__('test', function () {
    return require(commonTest);
});

},{"./lib/model.js":5,"./lib/schema":7,"fs":13,"path":14}],2:[function(require,module,exports){
/**
 * Module exports
 */
exports.Hookable = Hookable;

/**
 * Hooks mixins for ./model.js
 */
var Hookable = require('./model.js');

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

Hookable.prototype.trigger = function trigger(actionName, work, data) {
    var capitalizedName = capitalize(actionName);
    var beforeHook = this.constructor["before" + capitalizedName];
    var afterHook = this.constructor["after" + capitalizedName];
    if (actionName === 'validate') {
        beforeHook = beforeHook || this.constructor.beforeValidation;
        afterHook = afterHook || this.constructor.afterValidation;
    }
    var inst = this;

    // we only call "before" hook when we have actual action (work) to perform
    if (work) {
        if (beforeHook) {
            // before hook should be called on instance with one param: callback
            beforeHook.call(inst, function () {
                // actual action also have one param: callback
                work.call(inst, next);
            }, data);
        } else {
            work.call(inst, next);
        }
    } else {
        next();
    }

    function next(done) {
        if (afterHook) {
            afterHook.call(inst, done);
        } else if (done) {
            done.call(this);
        }
    }
};

function capitalize(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

},{"./model.js":5}],3:[function(require,module,exports){
/**
 * Include mixin for ./model.js
 */
var AbstractClass = require('./model.js');

/**
 * Allows you to load relations of several objects and optimize numbers of requests.
 *
 * @param {Array} objects - array of instances
 * @param {String}, {Object} or {Array} include - which relations you want to load.
 * @param {Function} cb - Callback called when relations are loaded
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
AbstractClass.include = function (objects, include, cb) {
    var self = this;

    if (
        (include.constructor.name == 'Array' && include.length == 0) ||
        (include.constructor.name == 'Object' && Object.keys(include).length == 0)
        ) {
        cb(null, objects);
        return;
    }

    include = processIncludeJoin(include);

    var keyVals = {};
    var objsByKeys = {};

    var nbCallbacks = 0;
    for (var i = 0; i < include.length; i++) {
        var callback = processIncludeItem(objects, include[i], keyVals, objsByKeys);
        if (callback !== null) {
            nbCallbacks++;
            callback(function() {
                nbCallbacks--;
                if (nbCallbacks == 0) {
                    cb(null, objects);
                }
            });
        } else {
            cb(null, objects);
        }
    }

    function processIncludeJoin(ij) {
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

    function processIncludeItem(objs, include, keyVals, objsByKeys) {
        var relations = self.relations;

        if (include.constructor.name === 'Object') {
            var relationName = Object.keys(include)[0];
            var subInclude = include[relationName];
        } else {
            var relationName = include;
            var subInclude = [];
        }
        var relation = relations[relationName];

        if (!relation) {
            return function() {
                cb(new Error('Relation "' + relationName + '" is not defined for ' + self.modelName + ' model'));
            }
        }

        var req = {'where': {}};

        if (!keyVals[relation.keyFrom]) {
            objsByKeys[relation.keyFrom] = {};
            objs.filter(Boolean).forEach(function(obj) {
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

            return function(cb) {
                relation.modelTo.all(req, function(err, objsIncluded) {
                    for (var i = 0; i < objsIncluded.length; i++) {
                        delete keysToBeProcessed[objsIncluded[i][relation.keyTo]];
                        var objectsFrom = objsByKeys[relation.keyFrom][objsIncluded[i][relation.keyTo]];
                        for (var j = 0; j < objectsFrom.length; j++) {
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
                        var objectsFrom = objsByKeys[relation.keyFrom][key];
                        for (var j = 0; j < objectsFrom.length; j++) {
                            if (!objectsFrom[j].__cachedRelations) {
                                objectsFrom[j].__cachedRelations = {};
                            }
                            objectsFrom[j].__cachedRelations[relationName] = relation.multiple ? [] : null;
                        }
                    }
                    cb(err, objsIncluded);
                });
            };
        }


        return null;
    }
}


},{"./model.js":5}],4:[function(require,module,exports){

module.exports = List;

/**
 * List class provides functionality of nested collection
 *
 * @param {Array} data - array of items.
 * @param {Crap} type - array with some type information? TODO: rework this API.
 * @param {AbstractClass} parent - owner of list.
 * @constructor
 */
function List(data, type, parent) {
    var list = this;
    if (!(list instanceof List)) {
        return new List(data);
    }

    if (data && data instanceof List) data = data.items;

    Object.defineProperty(list, 'parent', {
        writable: false,
        enumerable: false,
        configurable: false,
        value: parent
    });

    Object.defineProperty(list, 'nextid', {
        writable: true,
        enumerable: false,
        value: 1
    });

    data = list.items = data || [];
    var Item = list.ItemType = ListItem;

    if (typeof type === 'object' && type.constructor.name === 'Array') {
        list.ItemType = type[0] || ListItem;
    }

    data.forEach(function(item, i) {
        data[i] = new Item(item, list);
        Object.defineProperty(list, data[i].id, {
            writable: true,
            enumerable: false,
            configurable: true,
            value: data[i]
        });
        if (list.nextid <= data[i].id) {
            list.nextid = data[i].id + 1;
        }
    });

    Object.defineProperty(list, 'length', {
        enumerable: false,
        configurable: true,
        get: function() {
            return list.items.length;
        }
    });

    return list;

}

var _;
try {
    var underscore = 'underscore';
    _ = require(underscore);
} catch (e) {
    _ = false;
}

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

    _import.forEach(function(name) {
        List.prototype[name] = function() {
            var args = [].slice.call(arguments);
            args.unshift(this.items);
            return _[name].apply(_, args);
        };
    });
}

['slice', 'forEach', 'filter', 'reduce', 'map'].forEach(function (method) {
    var slice = [].slice;
    List.prototype[method] = function () {
        return Array.prototype[method].apply(this.items, slice.call(arguments));
    };
});

List.prototype.find = function(pattern, field) {
    if (field) {
        var res;
        this.items.forEach(function(o) {
            if (o[field] == pattern) res = o;
        });
        return res;
    } else {
        return this.items[this.items.indexOf(pattern)];
    }
};

List.prototype.toObject = function() {
    return this.items;
};

List.prototype.toJSON = function() {
    return this.items;
};

List.prototype.toString = function() {
    return JSON.stringify(this.items);
};

List.prototype.autoincrement = function() {
    return this.nextid++;
};

List.prototype.push = function(obj) {
    var item = new ListItem(obj, this);
    this.items.push(item);
    return item;
};

List.prototype.remove = function(obj) {
    var id = obj.id ? obj.id : obj;
    var found = false;
    this.items.forEach(function(o, i) {
        if (id && o.id == id) {
            found = i;
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

List.prototype.sort = function(cb) {
    return this.items.sort(cb);
};

List.prototype.some = function(cb) {
    return this.items.some(cb);
};

List.prototype.map = function(cb) {
    if (typeof cb === 'function') return this.items.map(cb);
    if (typeof cb === 'string') return this.items.map(function(el) {
        if (typeof el[cb] === 'function') return el[cb]();
        if (el.hasOwnProperty(cb)) return el[cb];
    });
};

function ListItem(data, parent) {
    if (typeof data === 'object') {
        for (var i in data) this[i] = data[i];
    } else {
        this.id = data;
    }
    Object.defineProperty(this, 'parent', {
        writable: false,
        enumerable: false,
        configurable: true,
        value: parent
    });
    if (!this.id) {
        this.id = parent.autoincrement();
    }
    if (parent.ItemType) {
        this.__proto__ = parent.ItemType.prototype;
        if (parent.ItemType !== ListItem) {
            parent.ItemType.apply(this);
        }
    }

    this.save = function(c) {
        parent.parent.save(c);
    };
}


},{}],5:[function(require,module,exports){
var process=require("__browserify_process"),global=typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {};/**
 * Module exports class Model
 */
module.exports = AbstractClass;

/**
 * Module dependencies
 */
var util = require('util');
var validations = require('./validations.js');
var ValidationError = validations.ValidationError;
var List = require('./list.js');
require('./hooks.js');
require('./relations.js');
require('./include.js');

var BASE_TYPES = ['String', 'Boolean', 'Number', 'Date', 'Text'];

/**
 * Model class - base class for all persist objects
 * provides **common API** to access any database adapter.
 * This class describes only abstract behavior layer, refer to `lib/adapters/*.js`
 * to learn more about specific adapter implementations
 *
 * `AbstractClass` mixes `Validatable` and `Hookable` classes methods
 *
 * @constructor
 * @param {Object} data - initial object data
 */
function AbstractClass(data) {
    this._initProperties(data, true);
}

AbstractClass.prototype._initProperties = function (data, applySetters) {
    var self = this;
    var ctor = this.constructor;
    var ds = ctor.schema.definitions[ctor.modelName];
    var properties = ds.properties;
    data = data || {};

    Object.defineProperty(this, '__cachedRelations', {
        writable: true,
        enumerable: false,
        configurable: true,
        value: {}
    });

    Object.defineProperty(this, '__data', {
        writable: true,
        enumerable: false,
        configurable: true,
        value: {}
    });

    Object.defineProperty(this, '__dataWas', {
        writable: true,
        enumerable: false,
        configurable: true,
        value: {}
    });

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
        Object.keys(data).forEach(function (attr) {
            self[attr] = data[attr];
        });
    }

    ctor.forEachProperty(function (attr) {

        if ('undefined' === typeof self.__data[attr]) {
            self.__data[attr] = self.__dataWas[attr] = getDefault(attr);
        } else {
            self.__dataWas[attr] = self.__data[attr];
        }

    });

    ctor.forEachProperty(function (attr) {

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

    function getDefault(attr) {
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
}

/**
 * @param {String} prop - property name
 * @param {Object} params - various property configuration
 */
AbstractClass.defineProperty = function (prop, params) {
    this.schema.defineProperty(this.modelName, prop, params);
};

AbstractClass.whatTypeName = function (propName) {
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
 * @param callback(err, obj)
 */
AbstractClass.update = function (params, cb) {
    if (stillConnecting(this.schema, this, arguments)) return;
    this.schema.adapter.update(this.modelName, params, cb);
};


AbstractClass._forDB = function (data) {
    var res = {};
    Object.keys(data).forEach(function (propName) {
        var typeName = this.whatTypeName(propName);
        if (!typeName && !data[propName] instanceof Array) {
            return;
        }
        if (typeName === 'JSON' || data[propName] instanceof Array) {
            res[propName] = JSON.stringify(data[propName]);
        } else {
            res[propName] = data[propName];
        }
    }.bind(this));
    return res;
};

AbstractClass.prototype.whatTypeName = function (propName) {
    return this.constructor.whatTypeName(propName);
};

/**
 * Create new instance of Model class, saved in database
 *
 * @param data [optional]
 * @param callback(err, obj)
 * callback called with arguments:
 *
 *   - err (null or Error)
 *   - instance (null or Model)
 */
AbstractClass.create = function (data, callback) {
    if (stillConnecting(this.schema, this, arguments)) return;

    var Model = this;
    var modelName = Model.modelName;

    if (typeof data === 'function') {
        callback = data;
        data = {};
    }

    if (typeof callback !== 'function') {
        callback = function () {};
    }

    if (!data) {
        data = {};
    }

    // Passed via data from save
    var options = data.options || { validate: true };

    if (data.data instanceof Model) {
        data = data.data;
    }

    if (data instanceof Array) {
        var instances = [];
        var errors = Array(data.length);
        var gotError = false;
        var wait = data.length;
        if (wait === 0) callback(null, []);

        var instances = [];
        for (var i = 0; i < data.length; i += 1) {
            (function(d, i) {
                instances.push(Model.create(d, function(err, inst) {
                    if (err) {
                        errors[i] = err;
                        gotError = true;
                    }
                    modelCreated();
                }));
            })(data[i], i);
        }

        return instances;

        function modelCreated() {
            if (--wait === 0) {
                callback(gotError ? errors : null, instances);
            }
        }
    }


    var obj;
    // if we come from save
    if (data instanceof Model && !data.id) {
        obj = data;
    } else {
        obj = new Model(data);
    }
    data = obj.toObject(true);

    if (!options.validate) {
        create();
    }
    else {
        // validation required
        obj.isValid(function(valid) {
            if (valid) {
                create();
            } else {
                callback(new ValidationError(obj), obj);
            }
        }, data);
    }

    function create() {
        obj.trigger('create', function(createDone) {
            obj.trigger('save', function(saveDone) {

                this._adapter().create(modelName, this.constructor._forDB(obj.toObject(true)), function (err, id, rev) {
                    if (id) {
                        obj.__data.id = id;
                        obj.__dataWas.id = id;
                        defineReadonlyProp(obj, 'id', id);
                    }
                    if (rev) {
                        obj._rev = rev
                    }
                    if (err) {
                        return callback(err, obj);
                    }
                    saveDone.call(obj, function () {
                        createDone.call(obj, function () {
                            callback(err, obj);
                        });
                    });
                }, obj);
            }, obj);
        }, obj);
    }

    return obj;
};

function stillConnecting(schema, obj, args) {
    if (schema.connected) return false;
    var method = args.callee;
    schema.once('connected', function () {
        method.apply(obj, [].slice.call(args));
    });
    if (!schema.connecting) schema.connect();
    return true;
};

/**
 * Update or insert
 */
AbstractClass.upsert = AbstractClass.updateOrCreate = function upsert(data, callback) {
    if (stillConnecting(this.schema, this, arguments)) return;

    var Model = this;
    if (!data.id) return this.create(data, callback);
    if (this.schema.adapter.updateOrCreate) {
        var inst = new Model(data);
        this.schema.adapter.updateOrCreate(Model.modelName, inst.toObject(true), function (err, data) {
            var obj;
            if (data) {
                inst._initProperties(data);
                obj = inst;
            } else {
                obj = null;
            }
            callback(err, obj);
        });
    } else {
        this.find(data.id, function (err, inst) {
            if (err) return callback(err);
            if (inst) {
                inst.updateAttributes(data, callback);
            } else {
                var obj = new Model(data);
                obj.save(data, callback);
            }
        });
    }
};

/**
 * Find one record, same as `all`, limited by 1 and return object, not collection,
 * if not found, create using data provided as second argument
 * 
 * @param {Object} query - search conditions: {where: {test: 'me'}}.
 * @param {Object} data - object to create.
 * @param {Function} cb - callback called with (err, instance)
 */
AbstractClass.findOrCreate = function findOrCreate(query, data, callback) {
    if (typeof query === 'undefined') {
        query = {where: {}};
    }
    if (typeof data === 'function' || typeof data === 'undefined') {
        callback = data;
        data = query && query.where;
    }
    if (typeof callback === 'undefined') {
        callback = function () {};
    }

    var t = this;
    this.findOne(query, function (err, record) {
        if (err) return callback(err);
        if (record) return callback(null, record);
        t.create(data, callback);
    });
};

/**
 * Check whether object exitst in database
 *
 * @param {id} id - identifier of object (primary key value)
 * @param {Function} cb - callbacl called with (err, exists: Bool)
 */
AbstractClass.exists = function exists(id, cb) {
    if (stillConnecting(this.schema, this, arguments)) return;

    if (id) {
        this.schema.adapter.exists(this.modelName, id, cb);
    } else {
        cb(new Error('Model::exists requires positive id argument'));
    }
};

/**
 * Find object by id
 *
 * @param {id} id - primary key value
 * @param {Function} cb - callback called with (err, instance)
 */
AbstractClass.find = function find(id, cb) {
    if (stillConnecting(this.schema, this, arguments)) return;

    this.schema.adapter.find(this.modelName, id, function (err, data) {
        var obj = null;
        if (data) {
            if (!data.id) {
                data.id = id;
            }
            obj = new this();
            obj._initProperties(data, false);
        }
        cb(err, obj);
    }.bind(this));
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
 * @param {Function} callback (required) called with arguments:
 *
 * - err (null or Error)
 * - Array of instances
 */
AbstractClass.all = function all(params, cb) {
    if (stillConnecting(this.schema, this, arguments)) return;

    if (arguments.length === 1) {
        cb = params;
        params = null;
    }
    if (params) {
        if ('skip' in params) {
            params.offset = params.skip;
        } else if ('offset' in params) {
            params.skip = params.offset;
        }
    }
    var constr = this;
    this.schema.adapter.all(this.modelName, params, function (err, data) {
        if (data && data.forEach) {
            if (!params || !params.onlyKeys) {
                data.forEach(function (d, i) {
                    var obj = new constr;
                    obj._initProperties(d, false);
                    if (params && params.include && params.collect) {
                        data[i] = obj.__cachedRelations[params.collect];
                    } else {
                        data[i] = obj;
                    }
                });
            }
            if (data && data.countBeforeLimit) {
                data.countBeforeLimit = data.countBeforeLimit;
            }
            cb(err, data);
        }
        else
            cb(err, []);
    });
};

/**
 * Iterate through dataset and perform async method iterator. This method
 * designed to work with large datasets loading data by batches.
 *
 * @param {Object} filter - query conditions. Same as for `all` may contain
 * optional member `batchSize` to specify size of batch loaded from db. Optional.
 * @param {Function} iterator - method(obj, next) called on each obj.
 * @param {Function} callback - method(err) called on complete or error.
 */
AbstractClass.iterate = function map(filter, iterator, callback) {
    var Model = this;
    if ('function' === typeof filter) {
        if ('function' === typeof iterator) {
            callback = iterator;
        }
        iterator = filter;
        filter = {};
    }

    var batchSize = filter.limit = filter.batchSize || 1000;
    var batchNumber = -1;

    nextBatch();

    function nextBatch() {
        batchNumber += 1;
        filter.skip = filter.offset = batchNumber * batchSize;
        Model.all(filter, function(err, collection) {
            if (err || collection.length === 0) {
                return done(err);
            }
            var i = -1;
            nextItem();
            function nextItem(err) {
                if (err) {
                    return done(err);
                }
                if (++i >= collection.length) {
                    return nextBatch();
                }
                (global.setImmediate || process.nextTick)(function() {
                    iterator(collection[i], nextItem, filter.offset + i);
                });
            }
        });
    }

    function done(err) {
        if ('function' === typeof callback) {
            callback(err);
        }
    }
};

/**
 * Find one record, same as `all`, limited by 1 and return object, not collection
 * 
 * @param {Object} params - search conditions: {where: {test: 'me'}}
 * @param {Function} cb - callback called with (err, instance)
 */
AbstractClass.findOne = function findOne(params, cb) {
    if (stillConnecting(this.schema, this, arguments)) return;

    if (typeof params === 'function') {
        cb = params;
        params = {};
    }
    params.limit = 1;
    this.all(params, function (err, collection) {
        if (err || !collection || !collection.length > 0) return cb(err, null);
        cb(err, collection[0]);
    });
};

/**
 * Destroy all records
 * @param {Function} cb - callback called with (err)
 */
AbstractClass.destroyAll = function destroyAll(cb) {
    if (stillConnecting(this.schema, this, arguments)) return;

    this.schema.adapter.destroyAll(this.modelName, function (err) {
        if ('function' === typeof cb) {
            cb(err);
        }
    }.bind(this));
};

/**
 * Return count of matched records
 *
 * @param {Object} where - search conditions (optional)
 * @param {Function} cb - callback, called with (err, count)
 */
AbstractClass.count = function (where, cb) {
    if (stillConnecting(this.schema, this, arguments)) return;

    if (typeof where === 'function') {
        cb = where;
        where = null;
    }
    this.schema.adapter.count(this.modelName, cb, where);
};

/**
 * Return string representation of class
 *
 * @override default toString method
 */
AbstractClass.toString = function () {
    return '[Model ' + this.modelName + ']';
};

/**
 * Save instance. When instance haven't id, create method called instead.
 * Triggers: validate, save, update | create
 * @param options {validate: true, throws: false} [optional]
 * @param callback(err, obj)
 */
AbstractClass.prototype.save = function (options, callback) {
    if (stillConnecting(this.constructor.schema, this, arguments)) return;

    if (typeof options == 'function') {
        callback = options;
        options = {};
    }

    callback = callback || function () {};
    options = options || {};

    if (!('validate' in options)) {
        options.validate = true;
    }
    if (!('throws' in options)) {
        options.throws = false;
    }

    var inst = this;
    var data = inst.toObject(true);
    var Model = this.constructor;
    var modelName = Model.modelName;

    if (!this.id) {
        // Pass options and this to create
        var data = { 
            data: this,
            options: options
        };
        return Model.create(data, callback);
    }

    // validate first
    if (!options.validate) {
        return save();
    }

    inst.isValid(function (valid) {
        if (valid) {
            save();
        } else {
            var err = new ValidationError(inst);
            // throws option is dangerous for async usage
            if (options.throws) {
                throw err;
            }
            callback(err, inst);
        }
    });

    // then save
    function save() {
        inst.trigger('save', function (saveDone) {
            inst.trigger('update', function (updateDone) {
                inst._adapter().save(modelName, inst.constructor._forDB(data), function (err) {
                    if (err) {
                        return callback(err, inst);
                    }
                    inst._initProperties(data, false);
                    updateDone.call(inst, function () {
                        saveDone.call(inst, function () {
                            callback(err, inst);
                        });
                    });
                });
            }, data);
        }, data);
    }
};

AbstractClass.prototype.isNewRecord = function () {
    return !this.id;
};

/**
 * Return adapter of current record
 * @private
 */
AbstractClass.prototype._adapter = function () {
    return this.schema.adapter;
};

/**
 * Convert instance to Object
 *
 * @param {Boolean} onlySchema - restrict properties to schema only, default false
 * when onlySchema == true, only properties defined in schema returned, 
 * otherwise all enumerable properties returned
 * @returns {Object} - canonical object representation (no getters and setters)
 */
AbstractClass.prototype.toObject = function (onlySchema) {
    var data = {};
    var ds = this.constructor.schema.definitions[this.constructor.modelName];
    var properties = ds.properties;
    var self = this;

    this.constructor.forEachProperty(function (attr) {
        if (self[attr] instanceof List) {
            data[attr] = self[attr].toObject();
        } else if (self.__data.hasOwnProperty(attr)) {
            data[attr] = self[attr];
        } else {
            data[attr] = null;
        }
    });

    if (!onlySchema) {
        Object.keys(self).forEach(function (attr) {
            if (!data.hasOwnProperty(attr)) {
                data[attr] = this[attr];
            }
        });
    }

    return data;
};

// AbstractClass.prototype.hasOwnProperty = function (prop) {
//     return this.__data && this.__data.hasOwnProperty(prop) ||
//         Object.getOwnPropertyNames(this).indexOf(prop) !== -1;
// };

AbstractClass.prototype.toJSON = function () {
    return this.toObject();
};

/**
 * Delete object from persistence
 *
 * @triggers `destroy` hook (async) before and after destroying object
 */
AbstractClass.prototype.destroy = function (cb) {
    if (stillConnecting(this.constructor.schema, this, arguments)) return;

    this.trigger('destroy', function (destroyed) {
        this._adapter().destroy(this.constructor.modelName, this.id, function (err) {
            if (err) {
                return cb(err);
            }

            destroyed(function () {
                if(cb) cb();
            });
        }.bind(this));
    });
};

/**
 * Update single attribute
 *
 * equals to `updateAttributes({name: value}, cb)
 *
 * @param {String} name - name of property
 * @param {Mixed} value - value of property
 * @param {Function} callback - callback called with (err, instance)
 */
AbstractClass.prototype.updateAttribute = function updateAttribute(name, value, callback) {
    var data = {};
    data[name] = value;
    this.updateAttributes(data, callback);
};

/**
 * Update set of attributes
 *
 * this method performs validation before updating
 *
 * @trigger `validation`, `save` and `update` hooks
 * @param {Object} data - data to update
 * @param {Function} callback - callback called with (err, instance)
 */
AbstractClass.prototype.updateAttributes = function updateAttributes(data, cb) {
    if (stillConnecting(this.constructor.schema, this, arguments)) return;

    var inst = this;
    var model = this.constructor.modelName;

    if (typeof data === 'function') {
        cb = data;
        data = null;
    }

    if (!data) {
        data = {};
    }

    // update instance's properties
    Object.keys(data).forEach(function (key) {
        inst[key] = data[key];
    });

    inst.isValid(function (valid) {
        if (!valid) {
            if (cb) {
                cb(new ValidationError(inst), inst);
            }
        } else {
            inst.trigger('save', function (saveDone) {
                inst.trigger('update', function (done) {

                    Object.keys(data).forEach(function (key) {
                        inst[key] = data[key];
                    });

                    inst._adapter().updateAttributes(model, inst.id, inst.constructor._forDB(inst.toObject(true)), function (err) {
                        if (!err) {
                            // update _was attrs
                            Object.keys(data).forEach(function (key) {
                                inst.__dataWas[key] = inst.__data[key];
                            });
                        }
                        done.call(inst, function () {
                            saveDone.call(inst, function () {
                                if (cb) {
                                    cb(err, inst);
                                }
                            });
                        });
                    });
                }, data);
            }, data);
        }
    }, data);
};

AbstractClass.prototype.fromObject = function (obj) {
    Object.keys(obj).forEach(function (key) {
        this[key] = obj[key];
    }.bind(this));
};

/**
 * Checks is property changed based on current property and initial value
 *
 * @param {String} attr - property name
 * @return Boolean
 */
AbstractClass.prototype.propertyChanged = function propertyChanged(attr) {
    return this.__data[attr] !== this.__dataWas[attr];
};

/**
 * Reload object from persistence
 *
 * @requires `id` member of `object` to be able to call `find`
 * @param {Function} callback - called with (err, instance) arguments
 */
AbstractClass.prototype.reload = function reload(callback) {
    if (stillConnecting(this.constructor.schema, this, arguments)) return;

    this.constructor.find(this.id, callback);
};

/**
 * Reset dirty attributes
 *
 * this method does not perform any database operation it just reset object to it's
 * initial state
 */
AbstractClass.prototype.reset = function () {
    var obj = this;
    Object.keys(obj).forEach(function (k) {
        if (k !== 'id' && !obj.constructor.schema.definitions[obj.constructor.modelName].properties[k]) {
            delete obj[k];
        }
        if (obj.propertyChanged(k)) {
            obj[k] = obj[k + '_was'];
        }
    });
};

AbstractClass.prototype.inspect = function () {
    return util.inspect(this.__data, false, 4, true);
};


/**
 * Check whether `s` is not undefined
 * @param {Mixed} s
 * @return {Boolean} s is undefined
 */
function isdef(s) {
    var undef;
    return s !== undef;
}

/**
 * Define readonly property on object
 *
 * @param {Object} obj
 * @param {String} key
 * @param {Mixed} value
 */
function defineReadonlyProp(obj, key, value) {
    Object.defineProperty(obj, key, {
        writable: false,
        enumerable: true,
        configurable: true,
        value: value
    });
}

},{"./hooks.js":2,"./include.js":3,"./list.js":4,"./relations.js":6,"./validations.js":9,"__browserify_process":17,"util":15}],6:[function(require,module,exports){
/**
 * Dependencies
 */
var i8n = require('inflection');
var defineScope = require('./scope.js').defineScope;

/**
 * Relations mixins for ./model.js
 */
var Model = require('./model.js');

Model.relationNameFor = function relationNameFor(foreignKey) {
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
Model.hasMany = function hasMany(anotherClass, params) {
    var thisClass = this, thisClassName = this.modelName;
    params = params || {};
    if (typeof anotherClass === 'string') {
        params.as = anotherClass;
        if (params.model) {
            anotherClass = params.model;
        } else {
            var anotherClassName = i8n.singularize(anotherClass).toLowerCase();
            for(var name in this.schema.models) {
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
        type: 'hasMany',
        keyFrom: 'id',
        keyTo: fk,
        modelTo: anotherClass,
        multiple: true
    };
    // each instance of this class should have method named
    // pluralize(anotherClass.modelName)
    // which is actually just anotherClass.all({where: {thisModelNameId: this.id}}, cb);
    var scopeMethods = {
        find: find,
        destroy: destroy
    };
    if (params.through) {
        var fk2 = i8n.camelize(anotherClass.modelName + '_id', true);
        scopeMethods.create = function create(data, done) {
            if (typeof data !== 'object') {
                done = data;
                data = {};
            }
            if ('function' !== typeof done) {
                done = function() {};
            }
            var self = this;
            var id = this.id;
            anotherClass.create(data, function(err, ac) {
                if (err) return done(err, ac);
                var d = {};
                d[params.through.relationNameFor(fk)] = self;
                d[params.through.relationNameFor(fk2)] = ac;
                params.through.create(d, function(e) {
                    if (e) {
                        ac.destroy(function() {
                            done(e);
                        });
                    } else {
                        done(err, ac);
                    }
                });
            });
        };
        scopeMethods.add = function(acInst, done) {
            var data = {};
            var query = {};
            query[fk] = this.id;
            data[params.through.relationNameFor(fk)] = this;
            query[fk2] = acInst.id || acInst;
            data[params.through.relationNameFor(fk2)] = acInst;
            params.through.findOrCreate({where: query}, data, done);
        };
        scopeMethods.remove = function(acInst, done) {
            var q = {};
            q[fk] = this.id;
            q[fk2] = acInst.id || acInst;
            params.through.findOne({where: q}, function(err, d) {
                if (err) {
                    return done(err);
                }
                if (!d) {
                    return done();
                }
                d.destroy(done);
            });
        };
        delete scopeMethods.destroy;
    }
    defineScope(this.prototype, params.through || anotherClass, methodName, function () {
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

    function find(id, cb) {
        anotherClass.find(id, function (err, inst) {
            if (err) return cb(err);
            if (!inst) return cb(new Error('Not found'));
            if (inst[fk] && inst[fk].toString() == this.id.toString()) {
                cb(null, inst);
            } else {
                cb(new Error('Permission denied'));
            }
        }.bind(this));
    }

    function destroy(id, cb) {
        this.find(id, function (err, inst) {
            if (err) return cb(err);
            if (inst) {
                inst.destroy(cb);
            } else {
                cb(new Error('Not found'));
            }
        });
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
 * post.author(function(err, user) {
 *     // the user variable is your user object
 * });
 *
 * The related object is cached, so if later you try to get again the author, no additional request will be made.
 * But there is an optional boolean parameter in first position that set whether or not you want to reload the cache:
 * post.author(true, function(err, user) {
 *     // The user is reloaded, even if it was already cached.
 * });
 *
 * This optional parameter default value is false, so the related object will be loaded from cache if available.
 */
Model.belongsTo = function (anotherClass, params) {
    params = params || {};
    if ('string' === typeof anotherClass) {
        params.as = anotherClass;
        if (params.model) {
            anotherClass = params.model;
        } else {
            var anotherClassName = anotherClass.toLowerCase();
            for(var name in this.schema.models) {
                if (name.toLowerCase() === anotherClassName) {
                    anotherClass = this.schema.models[name];
                }
            }
        }
    }
    var methodName = params.as || i8n.camelize(anotherClass.modelName, true);
    var fk = params.foreignKey || methodName + 'Id';

    this.relations[methodName] = {
        type: 'belongsTo',
        keyFrom: fk,
        keyTo: 'id',
        modelTo: anotherClass,
        multiple: false
    };

    this.schema.defineForeignKey(this.modelName, fk, anotherClass.modelName);
    this.prototype['__finders__'] = this.prototype['__finders__'] || {};

    this.prototype['__finders__'][methodName] = function (id, cb) {
        if (id === null) {
            cb(null, null);
            return;
        }
        anotherClass.find(id, function (err,inst) {
            if (err) return cb(err);
            if (!inst) return cb(null, null);
            if (inst.id === this[fk]) {
                cb(null, inst);
            } else {
                cb(new Error('Permission denied'));
            }
        }.bind(this));
    };

    this.prototype[methodName] = function (refresh, p) {
        if (arguments.length === 1) {
            p = refresh;
            refresh = false;
        } else if (arguments.length > 2) {
            throw new Error('Method can\'t be called with more than two arguments');
        }
        var self = this;
        var cachedValue;
        if (!refresh && this.__cachedRelations && (typeof this.__cachedRelations[methodName] !== 'undefined')) {
            cachedValue = this.__cachedRelations[methodName];
        }
        if (p instanceof Model) { // acts as setter
            this[fk] = p.id;
            this.__cachedRelations[methodName] = p;
        } else if (typeof p === 'function') { // acts as async getter
            if (typeof cachedValue === 'undefined') {
                this.__finders__[methodName].apply(self, [this[fk], function(err, inst) {
                    if (!err) {
                        self.__cachedRelations[methodName] = inst;
                    }
                    p(err, inst);
                }]);
                return this[fk];
            } else {
                p(null, cachedValue);
                return cachedValue;
            }
        } else if (typeof p === 'undefined') { // acts as sync getter
            return this[fk];
        } else { // setter
            this[fk] = p;
            delete this.__cachedRelations[methodName];
        }
    };

};

/**
 * Many-to-many relation
 *
 * Post.hasAndBelongsToMany('tags'); creates connection model 'PostTag'
 */
Model.hasAndBelongsToMany = function hasAndBelongsToMany(anotherClass, params) {
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

    function lookupModel(modelName) {
        var lookupClassName = modelName.toLowerCase();
        for (var name in models) {
            if (name.toLowerCase() === lookupClassName) {
                return models[name];
            }
        }
    }

};

},{"./model.js":5,"./scope.js":8,"inflection":10}],7:[function(require,module,exports){
var process=require("__browserify_process"),__dirname="/lib";/**
 * Module dependencies
 */
var AbstractClass = require('./model.js');
var List = require('./list.js');
var EventEmitter = require('events').EventEmitter;
var util = require('util');
var path = require('path');
var fs = require('fs');

var existsSync = fs.existsSync || path.existsSync;

/**
 * Export public API
 */
exports.Schema = Schema;
// exports.AbstractClass = AbstractClass;

/**
 * Helpers
 */
var slice = Array.prototype.slice;

Schema.Text = function Text() {};
Schema.JSON = function JSON() {};

Schema.types = {};
Schema.registerType = function (type) {
    this.types[type.name] = type;
};

Schema.registerType(Schema.Text);
Schema.registerType(Schema.JSON);


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
function Schema(name, settings) {
    var schema = this;
    // just save everything we get
    this.name = name;
    this.settings = settings;

    // Disconnected by default
    this.connected = false;
    this.connecting = false;

    // create blank models pool
    this.models = {};
    this.definitions = {};

    // and initialize schema using adapter
    // this is only one initialization entry point of adapter
    // this module should define `adapter` member of `this` (schema)
    var adapter;
    if (typeof name === 'object') {
        adapter = name;
        this.name = adapter.name;
    } else if (name.match(/^\//)) {
        // try absolute path
        adapter = require(name);
    } else if (existsSync(__dirname + '/adapters/' + name + '.js')) {
        // try built-in adapter
        adapter = require('./adapters/' + name);
    } else {
        // try foreign adapter
        try {
            adapter = require('jugglingdb-' + name);
        } catch (e) {
            return console.log('\nWARNING: JugglingDB adapter "' + name + '" is not installed,\nso your models would not work, to fix run:\n\n    npm install jugglingdb-' + name, '\n');
        }
    }

    adapter.initialize(this, function () {

        // we have an adaper now?
        if (!this.adapter) {
            throw new Error('Adapter is not defined correctly: it should create `adapter` member of schema');
        }

        this.adapter.log = function (query, start) {
            schema.log(query, start);
        };

        this.adapter.logger = function (query) {
            var t1 = Date.now();
            var log = this.log;
            return function (q) {
                log(q || query, t1);
            };
        };

        this.connected = true;
        this.emit('connected');

    }.bind(this));

    schema.connect = function(cb) {
        var schema = this;
        schema.connecting = true;
        if (schema.adapter.connect) {
            schema.adapter.connect(function(err) {
                if (!err) {
                    schema.connected = true;
                    schema.connecting = false;
                    schema.emit('connected');
                }
                if (cb) {
                    cb(err);
                }
            });
        } else {
            if (cb) {
                process.nextTick(cb);
            }
        }
    };
};

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
 * @return newly created class
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
Schema.prototype.define = function defineClass(className, properties, settings) {
    var schema = this;
    var args = slice.call(arguments);

    if (!className) throw new Error('Class name required');
    if (args.length == 1) properties = {}, args.push(properties);
    if (args.length == 2) settings   = {}, args.push(settings);

    properties = properties || {};
    settings = settings || {};

    // every class can receive hash of data as optional param
    var NewClass = function ModelConstructor(data, schema) {
        if (!(this instanceof ModelConstructor)) {
            return new ModelConstructor(data);
        }
        AbstractClass.call(this, data);
        hiddenProperty(this, 'schema', schema || this.constructor.schema);
    };

    hiddenProperty(NewClass, 'schema', schema);
    hiddenProperty(NewClass, 'modelName', className);
    hiddenProperty(NewClass, 'relations', {});

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
        settings: settings
    };

    // pass control to adapter
    this.adapter.define({
        model:      NewClass,
        properties: properties,
        settings:   settings
    });

    NewClass.prototype.__defineGetter__('id', function () {
        return this.__data.id;
    });

    properties.id = properties.id || { type: Number };

    NewClass.forEachProperty = function (cb) {
        Object.keys(properties).forEach(cb);
    };

    NewClass.registerProperty = function (attr) {
        var DataType = properties[attr].type;
        if (DataType instanceof Array) {
            DataType = List;
        } else if (DataType.name === 'Date') {
            var OrigDate = Date;
            DataType = function Date(arg) {
                return new OrigDate(arg);
            };
        } else if (DataType.name === 'JSON' || DataType === JSON) {
            DataType = function JSON(s) {
                return s;
            };
        } else if (DataType.name === 'Text' || DataType === Schema.Text) {
            DataType = function Text(s) {
                return s;
            };
        }

        Object.defineProperty(NewClass.prototype, attr, {
            get: function () {
                if (NewClass.getter[attr]) {
                    return NewClass.getter[attr].call(this);
                } else {
                    return this.__data[attr];
                }
            },
            set: function (value) {
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
            enumerable: true
        });

        NewClass.prototype.__defineGetter__(attr + '_was', function () {
            return this.__dataWas[attr];
        });

        Object.defineProperty(NewClass.prototype, '_' + attr, {
            get: function () {
                return this.__data[attr];
            },
            set: function (value) {
                this.__data[attr] = value;
            },
            configurable: true,
            enumerable: false
        });
    };

    NewClass.forEachProperty(NewClass.registerProperty);

    return NewClass;

};

    function standartize(properties, settings) {
        Object.keys(properties).forEach(function (key) {
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
Schema.prototype.defineProperty = function (model, prop, params) {
    this.definitions[model].properties[prop] = params;
    this.models[model].registerProperty(prop);
    if (this.adapter.defineProperty) {
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
Schema.prototype.extendModel = function (model, props) {
    var t = this;
    standartize(props, {});
    Object.keys(props).forEach(function (propName) {
        var definition = props[propName];
        t.defineProperty(model, propName, definition);
    });
};

/**
 * Drop each model table and re-create.
 * This method make sense only for sql adapters.
 *
 * @warning All data will be lost! Use autoupdate if you need your data.
 */
Schema.prototype.automigrate = function (cb) {
    this.freeze();
    if (this.adapter.automigrate) {
        this.adapter.automigrate(cb);
    } else if (cb) {
        cb();
    }
};

/**
 * Update existing database tables.
 * This method make sense only for sql adapters.
 */
Schema.prototype.autoupdate = function (cb) {
    this.freeze();
    if (this.adapter.autoupdate) {
        this.adapter.autoupdate(cb);
    } else if (cb) {
        cb();
    }
};

/**
 * Check whether migrations needed
 * This method make sense only for sql adapters.
 */
Schema.prototype.isActual = function (cb) {
    this.freeze();
    if (this.adapter.isActual) {
        this.adapter.isActual(cb);
    } else if (cb) {
        cb(null, true);
    }
};

/**
 * Log benchmarked message. Do not redefine this method, if you need to grab
 * chema logs, use `schema.on('log', ...)` emitter event
 *
 * @private used by adapters
 */
Schema.prototype.log = function (sql, t) {
    this.emit('log', sql, t);
};

/**
 * Freeze schema. Behavior depends on adapter
 */
Schema.prototype.freeze = function freeze() {
    if (this.adapter.freezeSchema) {
        this.adapter.freezeSchema();
    }
}

/**
 * Return table name for specified `modelName`
 * @param {String} modelName
 */
Schema.prototype.tableName = function (modelName) {
    return this.definitions[modelName].settings.table = this.definitions[modelName].settings.table || modelName
};

/**
 * Define foreign key
 * @param {String} className
 * @param {String} key - name of key field
 */
Schema.prototype.defineForeignKey = function defineForeignKey(className, key, foreignClassName) {
    // quit if key already defined
    if (this.definitions[className].properties[key]) return;

    if (this.adapter.defineForeignKey) {
        var cb = function (err, keyType) {
            if (err) throw err;
            this.definitions[className].properties[key] = {type: keyType};
        }.bind(this);
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
 */
Schema.prototype.disconnect = function disconnect(cb) {
    if (typeof this.adapter.disconnect === 'function') {
        this.connected = false;
        this.adapter.disconnect(cb);
    } else if (cb) {
        cb();
    }
};

Schema.prototype.copyModel = function copyModel(Master) {
    var schema = this;
    var className = Master.modelName;
    var md = Master.schema.definitions[className];
    var Slave = function SlaveModel() {
        Master.apply(this, [].slice.call(arguments));
        this.schema = schema;
    };

    util.inherits(Slave, Master);

    Slave.__proto__ = Master;

    hiddenProperty(Slave, 'schema', schema);
    hiddenProperty(Slave, 'modelName', className);
    hiddenProperty(Slave, 'relations', Master.relations);

    if (!(className in schema.models)) {

        // store class in model pool
        schema.models[className] = Slave;
        schema.definitions[className] = {
            properties: md.properties,
            settings: md.settings
        };

        if (!schema.isTransaction) {
            schema.adapter.define({
                model:      Slave,
                properties: md.properties,
                settings:   md.settings
            });
        }

    }

    return Slave;
};

Schema.prototype.transaction = function() {
    var schema = this;
    var transaction = new EventEmitter;
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

    transaction.exec = function(cb) {
        transaction.adapter.exec(cb);
    };

    return transaction;
};

/**
 * Define hidden property
 */
function hiddenProperty(where, property, value) {
    Object.defineProperty(where, property, {
        writable: false,
        enumerable: false,
        configurable: false,
        value: value
    });
}

/**
 * Define readonly property on object
 *
 * @param {Object} obj
 * @param {String} key
 * @param {Mixed} value
 */
function defineReadonlyProp(obj, key, value) {
    Object.defineProperty(obj, key, {
        writable: false,
        enumerable: true,
        configurable: true,
        value: value
    });
}


},{"./list.js":4,"./model.js":5,"__browserify_process":17,"events":12,"fs":13,"path":14,"util":15}],8:[function(require,module,exports){
/**
 * Module exports
 */
exports.defineScope = defineScope;

/**
 * Scope mixin for ./model.js
 */
var Model = require('./model.js');

/**
 * Define scope
 * TODO: describe behavior and usage examples
 */
Model.scope = function (name, params) {
    defineScope(this, this, name, params);
};

function defineScope(cls, targetClass, name, params, methods) {

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
        enumerable: false,
        configurable: true,
        get: function () {
            var f = function caller(condOrRefresh, cb) {
                var actualCond = {};
                var actualRefresh = false;
                var saveOnCache = true;
                if (arguments.length === 1) {
                    cb = condOrRefresh;
                } else if (arguments.length === 2) {
                    if (typeof condOrRefresh === 'boolean') {
                        actualRefresh = condOrRefresh;
                    } else {
                        actualCond = condOrRefresh;
                        actualRefresh = true;
                        saveOnCache = false;
                    }
                } else {
                    throw new Error('Method can be only called with one or two arguments');
                }

                if (!this.__cachedRelations || (typeof this.__cachedRelations[name] == 'undefined') || actualRefresh) {
                    var self = this;
                    var params = mergeParams(actualCond, caller._scope);
                    return targetClass.all(params, function(err, data) {
                        if (!err && saveOnCache) {
                            if (!self.__cachedRelations) {
                                self.__cachedRelations = {};
                            }
                            self.__cachedRelations[name] = data;
                        }
                        cb(err, data);
                    });
                } else {
                    cb(null, this.__cachedRelations[name]);
                }
            };
            f._scope = typeof params === 'function' ? params.call(this) : params;
            f.build = build;
            f.create = create;
            f.destroyAll = destroyAll;
            for (var i in methods) {
                f[i] = methods[i].bind(this);
            }

            // define sub-scopes
            Object.keys(targetClass._scopeMeta).forEach(function (name) {
                Object.defineProperty(f, name, {
                    enumerable: false,
                    get: function () {
                        mergeParams(f._scope, targetClass._scopeMeta[name]);
                        return f;
                    }
                });
            }.bind(this));
            return f;
        }
    });

    // and it should have create/build methods with binded thisModelNameId param
    function build(data) {
        return new targetClass(mergeParams(this._scope, {where:data || {}}).where);
    }

    function create(data, cb) {
        if (typeof data === 'function') {
            cb = data;
            data = {};
        }
        this.build(data).save(cb);
    }

    /*
        Callback
        - The callback will be called after all elements are destroyed
        - For every destroy call which results in an error
        - If fetching the Elements on which destroyAll is called results in an error
    */
    function destroyAll(cb) {
        targetClass.all(this._scope, function (err, data) {
            if (err) {
                cb(err);
            } else {
                (function loopOfDestruction (data) {
                    if(data.length > 0) {
                        data.shift().destroy(function(err) {
                            if(err && cb) cb(err);
                            loopOfDestruction(data);
                        });
                    } else {
                        if(cb) cb();
                    }
                }(data));
            }
        });
    }

    function mergeParams(base, update) {
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
function merge(base, update) {
    base = base || {};
    if (update) {
        Object.keys(update).forEach(function (key) {
            base[key] = update[key];
        });
    }
    return base;
}


},{"./model.js":5}],9:[function(require,module,exports){
var process=require("__browserify_process");/**
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
var Validatable = require('./model.js');

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
function validatePresence(attr, conf, err) {
    if (blank(this[attr])) {
        err();
    }
}

/**
 * Length validator
 */
function validateLength(attr, conf, err) {
    if (nullCheck.call(this, attr, conf, err)) return;

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
}

/**
 * Numericality validator
 */
function validateNumericality(attr, conf, err) {
    if (nullCheck.call(this, attr, conf, err)) return;

    if (typeof this[attr] !== 'number') {
        return err('number');
    }
    if (conf.int && this[attr] !== Math.round(this[attr])) {
        return err('int');
    }
}

/**
 * Inclusion validator
 */
function validateInclusion(attr, conf, err) {
    if (nullCheck.call(this, attr, conf, err)) return;

    if (!~conf.in.indexOf(this[attr])) {
        err()
    }
}

/**
 * Exclusion validator
 */
function validateExclusion(attr, conf, err) {
    if (nullCheck.call(this, attr, conf, err)) return;

    if (~conf.in.indexOf(this[attr])) {
        err()
    }
}

/**
 * Format validator
 */
function validateFormat(attr, conf, err) {
    if (nullCheck.call(this, attr, conf, err)) return;

    if (typeof this[attr] === 'string') {
        if (!this[attr].match(conf['with'])) {
            err();
        }
    } else {
        err();
    }
}

/**
 * Custom validator
 */
function validateCustom(attr, conf, err, done) {
    conf.customValidator.call(this, err, done);
}

/**
 * Uniqueness validator
 */
function validateUniqueness(attr, conf, err, done) {
    if (nullCheck.call(this, attr, conf, err)) {
        return done();
    }

    var cond = {where: {}};
    cond.where[attr] = this[attr];
    this.constructor.all(cond, function (error, found) {
        if (error) {
            return err();
        }
        if (found.length > 1) {
            err();
        } else if (found.length === 1 && (!this.id || !found[0].id || found[0].id.toString() != this.id.toString())) {
            err();
        }
        done();
    }.bind(this));
}

var validators = {
    presence:     validatePresence,
    length:       validateLength,
    numericality: validateNumericality,
    inclusion:    validateInclusion,
    exclusion:    validateExclusion,
    format:       validateFormat,
    custom:       validateCustom,
    uniqueness:   validateUniqueness
};

function getConfigurator(name, opts) {
    return function () {
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
 * @param {Function} callback called with (valid)
 * @return {Boolean} true if no async validation configured and all passed
 *
 * @example ExpressJS controller: render user if valid, show flash otherwise
 * ```
 * user.isValid(function (valid) {
 *     if (valid) res.render({user: user});
 *     else res.flash('error', 'User is not valid'), console.log(user.errors), res.redirect('/users');
 * });
 * ```
 */
Validatable.prototype.isValid = function (callback, data) {
    var valid = true, inst = this, wait = 0, async = false;

    // exit with success when no errors
    if (!this.constructor._validations) {
        cleanErrors(this);
        if (callback) {
            this.trigger('validate', function (validationsDone) {
                validationsDone.call(inst, function() {
                    callback(valid);
                });
            });
        }
        return valid;
    }

    Object.defineProperty(this, 'errors', {
        enumerable: false,
        configurable: true,
        value: new Errors
    });

    this.trigger('validate', function (validationsDone) {
        var inst = this,
            asyncFail = false;

        this.constructor._validations.forEach(function (v) {
            if (v[2] && v[2].async) {
                async = true;
                wait += 1;
                process.nextTick(function () {
                    validationFailed(inst, v, done);
                });
            } else {
                if (validationFailed(inst, v)) {
                    valid = false;
                }
            }

        });

        if (!async) {
            validationsDone.call(inst, function() {
                if (valid) cleanErrors(inst);
                if (callback) {
                    callback(valid);
                }
            });
        }

        function done(fail) {
            asyncFail = asyncFail || fail;
            if (--wait === 0) {
                validationsDone.call(inst, function () {
                    if (valid && !asyncFail) cleanErrors(inst);
                    if (callback) {
                        callback(valid && !asyncFail);
                    }
                });
            }
        }

    }, data);

    if (async) {
        // in case of async validation we should return undefined here,
        // because not all validations are finished yet
        return;
    } else {
        return valid;
    }

};

function cleanErrors(inst) {
    Object.defineProperty(inst, 'errors', {
        enumerable: false,
        configurable: true,
        value: false
    });
}

function validationFailed(inst, v, cb) {
    var attr = v[0];
    var conf = v[1];
    var opts = v[2] || {};

    if (typeof attr !== 'string') return false;

    // here we should check skip validation conditions (if, unless)
    // that can be specified in conf
    if (skipValidation(inst, conf, 'if')) return false;
    if (skipValidation(inst, conf, 'unless')) return false;

    var fail = false;
    var validator = validators[conf.validation];
    var validatorArguments = [];
    validatorArguments.push(attr);
    validatorArguments.push(conf);
    validatorArguments.push(function onerror(kind) {
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
    if (cb) {
        validatorArguments.push(function () {
            cb(fail);
        });
    }
    validator.apply(inst, validatorArguments);
    return fail;
}

function skipValidation(inst, conf, kind) {
    var doValidate = true;
    if (typeof conf[kind] === 'function') {
        doValidate = conf[kind].call(inst);
        if (kind === 'unless') doValidate = !doValidate;
    } else if (typeof conf[kind] === 'string') {
        if (typeof inst[conf[kind]] === 'function') {
            doValidate = inst[conf[kind]].call(inst);
            if (kind === 'unless') doValidate = !doValidate;
        } else if (inst.__data.hasOwnProperty(conf[kind])) {
            doValidate = inst[conf[kind]];
            if (kind === 'unless') doValidate = !doValidate;
        } else {
            doValidate = kind === 'if';
        }
    }
    return !doValidate;
}

var defaultMessages = {
    presence: 'can\'t be blank',
    length: {
        min: 'too short',
        max: 'too long',
        is: 'length is wrong'
    },
    common: {
        blank: 'is blank',
        'null': 'is null'
    },
    numericality: {
        'int': 'is not an integer',
        'number': 'is not a number'
    },
    inclusion: 'is not included in the list',
    exclusion: 'is reserved',
    uniqueness: 'is not unique'
};

function nullCheck(attr, conf, err) {
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
 * @param {Mix} v
 * @returns {Boolean} whether `v` blank or not
 */
function blank(v) {
    if (typeof v === 'undefined') return true;
    if (v instanceof Array && v.length === 0) return true;
    if (v === null) return true;
    if (typeof v == 'string' && v === '') return true;
    return false;
}

function configure(cls, validation, args, opts) {
    if (!cls._validations) {
        Object.defineProperty(cls, '_validations', {
            writable: true,
            configurable: true,
            enumerable: false,
            value: []
        });
    }
    args = [].slice.call(args);
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
    args.forEach(function (attr) {
        cls._validations.push([attr, conf, opts]);
    });
}

function Errors() {
    Object.defineProperty(this, 'codes', {
        enumerable: false,
        configurable: true,
        value: {}
    });
}

Errors.prototype.add = function (field, message, code) {
    code = code || 'invalid';
    if (!this[field]) {
        this[field] = [];
        this.codes[field] = [];
    }
    this[field].push(message);
    this.codes[field].push(code);
};

function ErrorCodes(messages) {
    var c = this;
    Object.keys(messages).forEach(function(field) {
        c[field] = messages[field].codes;
    });
}

function ValidationError(obj) {
    if (!(this instanceof ValidationError)) return new ValidationError(obj);

    this.name = 'ValidationError';
    this.message = 'Validation error';
    this.statusCode = 400;
    this.codes = obj.errors && obj.errors.codes;
    this.context = obj && obj.constructor && obj.constructor.modelName;

    Error.call(this);
};

ValidationError.prototype.__proto__ = Error.prototype;

},{"./model.js":5,"__browserify_process":17}],10:[function(require,module,exports){
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
   *     inflection.pluralize( 'octopus' ); // === "octopi"
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
   *     inflection.singularize( 'octopi' ); // === "octopus"
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
      var str_path = str.toLowerCase().split( '/' );
      var i        = 0;
      var j        = str_path.length;

      for( ; i < j; i++ ){
        var str_arr = str_path[ i ].split( '_' );
        var initX   = (( lowFirstLetter && i + 1 === j ) ? ( 1 ) : ( 0 ));
        var k       = initX;
        var l       = str_arr.length;

        for( ; k < l; k++ ){
          str_arr[ k ] = str_arr[ k ].charAt( 0 ).toUpperCase() + str_arr[ k ].substring( 1 );
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

      for( ; i < j; i++ ){
        var d = str_arr[ i ].split( '-' );
        var k = 0;
        var l = d.length;

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
   * @returns {String} Return all found numbers their sequence like "22nd".
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
    }
  };

  if( typeof exports === 'undefined' ) return root.inflection = inflector;

/**
 * @public
 */
  inflector.version = "1.2.5";
/**
 * Exports module.
 */
  module.exports = inflector;
})( this );

},{}],11:[function(require,module,exports){


//
// The shims in this file are not fully implemented shims for the ES5
// features, but do work for the particular usecases there is in
// the other modules.
//

var toString = Object.prototype.toString;
var hasOwnProperty = Object.prototype.hasOwnProperty;

// Array.isArray is supported in IE9
function isArray(xs) {
  return toString.call(xs) === '[object Array]';
}
exports.isArray = typeof Array.isArray === 'function' ? Array.isArray : isArray;

// Array.prototype.indexOf is supported in IE9
exports.indexOf = function indexOf(xs, x) {
  if (xs.indexOf) return xs.indexOf(x);
  for (var i = 0; i < xs.length; i++) {
    if (x === xs[i]) return i;
  }
  return -1;
};

// Array.prototype.filter is supported in IE9
exports.filter = function filter(xs, fn) {
  if (xs.filter) return xs.filter(fn);
  var res = [];
  for (var i = 0; i < xs.length; i++) {
    if (fn(xs[i], i, xs)) res.push(xs[i]);
  }
  return res;
};

// Array.prototype.forEach is supported in IE9
exports.forEach = function forEach(xs, fn, self) {
  if (xs.forEach) return xs.forEach(fn, self);
  for (var i = 0; i < xs.length; i++) {
    fn.call(self, xs[i], i, xs);
  }
};

// Array.prototype.map is supported in IE9
exports.map = function map(xs, fn) {
  if (xs.map) return xs.map(fn);
  var out = new Array(xs.length);
  for (var i = 0; i < xs.length; i++) {
    out[i] = fn(xs[i], i, xs);
  }
  return out;
};

// Array.prototype.reduce is supported in IE9
exports.reduce = function reduce(array, callback, opt_initialValue) {
  if (array.reduce) return array.reduce(callback, opt_initialValue);
  var value, isValueSet = false;

  if (2 < arguments.length) {
    value = opt_initialValue;
    isValueSet = true;
  }
  for (var i = 0, l = array.length; l > i; ++i) {
    if (array.hasOwnProperty(i)) {
      if (isValueSet) {
        value = callback(value, array[i], i, array);
      }
      else {
        value = array[i];
        isValueSet = true;
      }
    }
  }

  return value;
};

// String.prototype.substr - negative index don't work in IE8
if ('ab'.substr(-1) !== 'b') {
  exports.substr = function (str, start, length) {
    // did we get a negative start, calculate how much it is from the beginning of the string
    if (start < 0) start = str.length + start;

    // call the original function
    return str.substr(start, length);
  };
} else {
  exports.substr = function (str, start, length) {
    return str.substr(start, length);
  };
}

// String.prototype.trim is supported in IE9
exports.trim = function (str) {
  if (str.trim) return str.trim();
  return str.replace(/^\s+|\s+$/g, '');
};

// Function.prototype.bind is supported in IE9
exports.bind = function () {
  var args = Array.prototype.slice.call(arguments);
  var fn = args.shift();
  if (fn.bind) return fn.bind.apply(fn, args);
  var self = args.shift();
  return function () {
    fn.apply(self, args.concat([Array.prototype.slice.call(arguments)]));
  };
};

// Object.create is supported in IE9
function create(prototype, properties) {
  var object;
  if (prototype === null) {
    object = { '__proto__' : null };
  }
  else {
    if (typeof prototype !== 'object') {
      throw new TypeError(
        'typeof prototype[' + (typeof prototype) + '] != \'object\''
      );
    }
    var Type = function () {};
    Type.prototype = prototype;
    object = new Type();
    object.__proto__ = prototype;
  }
  if (typeof properties !== 'undefined' && Object.defineProperties) {
    Object.defineProperties(object, properties);
  }
  return object;
}
exports.create = typeof Object.create === 'function' ? Object.create : create;

// Object.keys and Object.getOwnPropertyNames is supported in IE9 however
// they do show a description and number property on Error objects
function notObject(object) {
  return ((typeof object != "object" && typeof object != "function") || object === null);
}

function keysShim(object) {
  if (notObject(object)) {
    throw new TypeError("Object.keys called on a non-object");
  }

  var result = [];
  for (var name in object) {
    if (hasOwnProperty.call(object, name)) {
      result.push(name);
    }
  }
  return result;
}

// getOwnPropertyNames is almost the same as Object.keys one key feature
//  is that it returns hidden properties, since that can't be implemented,
//  this feature gets reduced so it just shows the length property on arrays
function propertyShim(object) {
  if (notObject(object)) {
    throw new TypeError("Object.getOwnPropertyNames called on a non-object");
  }

  var result = keysShim(object);
  if (exports.isArray(object) && exports.indexOf(object, 'length') === -1) {
    result.push('length');
  }
  return result;
}

var keys = typeof Object.keys === 'function' ? Object.keys : keysShim;
var getOwnPropertyNames = typeof Object.getOwnPropertyNames === 'function' ?
  Object.getOwnPropertyNames : propertyShim;

if (new Error().hasOwnProperty('description')) {
  var ERROR_PROPERTY_FILTER = function (obj, array) {
    if (toString.call(obj) === '[object Error]') {
      array = exports.filter(array, function (name) {
        return name !== 'description' && name !== 'number' && name !== 'message';
      });
    }
    return array;
  };

  exports.keys = function (object) {
    return ERROR_PROPERTY_FILTER(object, keys(object));
  };
  exports.getOwnPropertyNames = function (object) {
    return ERROR_PROPERTY_FILTER(object, getOwnPropertyNames(object));
  };
} else {
  exports.keys = keys;
  exports.getOwnPropertyNames = getOwnPropertyNames;
}

// Object.getOwnPropertyDescriptor - supported in IE8 but only on dom elements
function valueObject(value, key) {
  return { value: value[key] };
}

if (typeof Object.getOwnPropertyDescriptor === 'function') {
  try {
    Object.getOwnPropertyDescriptor({'a': 1}, 'a');
    exports.getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  } catch (e) {
    // IE8 dom element issue - use a try catch and default to valueObject
    exports.getOwnPropertyDescriptor = function (value, key) {
      try {
        return Object.getOwnPropertyDescriptor(value, key);
      } catch (e) {
        return valueObject(value, key);
      }
    };
  }
} else {
  exports.getOwnPropertyDescriptor = valueObject;
}

},{}],12:[function(require,module,exports){
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

var util = require('util');

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
  if (!util.isNumber(n) || n < 0)
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
        (util.isObject(this._events.error) && !this._events.error.length)) {
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

  if (util.isUndefined(handler))
    return false;

  if (util.isFunction(handler)) {
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
  } else if (util.isObject(handler)) {
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

  if (!util.isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              util.isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (util.isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (util.isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!util.isUndefined(this._maxListeners)) {
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
  if (!util.isFunction(listener))
    throw TypeError('listener must be a function');

  function g() {
    this.removeListener(type, g);
    listener.apply(this, arguments);
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!util.isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (util.isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (util.isObject(list)) {
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

  if (util.isFunction(listeners)) {
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
  else if (util.isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (util.isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};
},{"util":15}],13:[function(require,module,exports){

// not implemented
// The reason for having an empty file and not throwing is to allow
// untraditional implementation of this module.

},{}],14:[function(require,module,exports){
var process=require("__browserify_process");// Copyright Joyent, Inc. and other Node contributors.
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

var util = require('util');
var shims = require('_shims');

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
    if (!util.isString(path)) {
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
  resolvedPath = normalizeArray(shims.filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
  var isAbsolute = exports.isAbsolute(path),
      trailingSlash = shims.substr(path, -1) === '/';

  // Normalize the path
  path = normalizeArray(shims.filter(path.split('/'), function(p) {
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
  return exports.normalize(shims.filter(paths, function(p, index) {
    if (!util.isString(p)) {
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

},{"__browserify_process":17,"_shims":11,"util":15}],15:[function(require,module,exports){
var Buffer=require("__browserify_Buffer").Buffer;// Copyright Joyent, Inc. and other Node contributors.
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

var shims = require('_shims');

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

  shims.forEach(array, function(val, idx) {
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
    var ret = value.inspect(recurseTimes);
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
  var keys = shims.keys(value);
  var visibleKeys = arrayToHash(keys);

  if (ctx.showHidden) {
    keys = shims.getOwnPropertyNames(value);
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

  shims.forEach(keys, function(key) {
    if (!key.match(/^\d+$/)) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          key, true));
    }
  });
  return output;
}


function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
  var name, str, desc;
  desc = shims.getOwnPropertyDescriptor(value, key) || { value: value[key] };
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
    if (shims.indexOf(ctx.seen, desc.value) < 0) {
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
  var length = shims.reduce(output, function(prev, cur) {
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
  return shims.isArray(ar);
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
  return typeof arg === 'object' && arg;
}
exports.isObject = isObject;

function isDate(d) {
  return isObject(d) && objectToString(d) === '[object Date]';
}
exports.isDate = isDate;

function isError(e) {
  return isObject(e) && objectToString(e) === '[object Error]';
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

function isBuffer(arg) {
  return arg instanceof Buffer;
}
exports.isBuffer = isBuffer;

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
exports.inherits = function(ctor, superCtor) {
  ctor.super_ = superCtor;
  ctor.prototype = shims.create(superCtor.prototype, {
    constructor: {
      value: ctor,
      enumerable: false,
      writable: true,
      configurable: true
    }
  });
};

exports._extend = function(origin, add) {
  // Don't do anything if add isn't an object
  if (!add || !isObject(add)) return origin;

  var keys = shims.keys(add);
  var i = keys.length;
  while (i--) {
    origin[keys[i]] = add[keys[i]];
  }
  return origin;
};

function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

},{"__browserify_Buffer":16,"_shims":11}],16:[function(require,module,exports){
require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
exports.readIEEE754 = function(buffer, offset, isBE, mLen, nBytes) {
  var e, m,
      eLen = nBytes * 8 - mLen - 1,
      eMax = (1 << eLen) - 1,
      eBias = eMax >> 1,
      nBits = -7,
      i = isBE ? 0 : (nBytes - 1),
      d = isBE ? 1 : -1,
      s = buffer[offset + i];

  i += d;

  e = s & ((1 << (-nBits)) - 1);
  s >>= (-nBits);
  nBits += eLen;
  for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8);

  m = e & ((1 << (-nBits)) - 1);
  e >>= (-nBits);
  nBits += mLen;
  for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8);

  if (e === 0) {
    e = 1 - eBias;
  } else if (e === eMax) {
    return m ? NaN : ((s ? -1 : 1) * Infinity);
  } else {
    m = m + Math.pow(2, mLen);
    e = e - eBias;
  }
  return (s ? -1 : 1) * m * Math.pow(2, e - mLen);
};

exports.writeIEEE754 = function(buffer, value, offset, isBE, mLen, nBytes) {
  var e, m, c,
      eLen = nBytes * 8 - mLen - 1,
      eMax = (1 << eLen) - 1,
      eBias = eMax >> 1,
      rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0),
      i = isBE ? (nBytes - 1) : 0,
      d = isBE ? -1 : 1,
      s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0;

  value = Math.abs(value);

  if (isNaN(value) || value === Infinity) {
    m = isNaN(value) ? 1 : 0;
    e = eMax;
  } else {
    e = Math.floor(Math.log(value) / Math.LN2);
    if (value * (c = Math.pow(2, -e)) < 1) {
      e--;
      c *= 2;
    }
    if (e + eBias >= 1) {
      value += rt / c;
    } else {
      value += rt * Math.pow(2, 1 - eBias);
    }
    if (value * c >= 2) {
      e++;
      c /= 2;
    }

    if (e + eBias >= eMax) {
      m = 0;
      e = eMax;
    } else if (e + eBias >= 1) {
      m = (value * c - 1) * Math.pow(2, mLen);
      e = e + eBias;
    } else {
      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen);
      e = 0;
    }
  }

  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8);

  e = (e << mLen) | m;
  eLen += mLen;
  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8);

  buffer[offset + i - d] |= s * 128;
};

},{}],"q9TxCC":[function(require,module,exports){
var assert;
exports.Buffer = Buffer;
exports.SlowBuffer = Buffer;
Buffer.poolSize = 8192;
exports.INSPECT_MAX_BYTES = 50;

function stringtrim(str) {
  if (str.trim) return str.trim();
  return str.replace(/^\s+|\s+$/g, '');
}

function Buffer(subject, encoding, offset) {
  if(!assert) assert= require('assert');
  if (!(this instanceof Buffer)) {
    return new Buffer(subject, encoding, offset);
  }
  this.parent = this;
  this.offset = 0;

  // Work-around: node's base64 implementation
  // allows for non-padded strings while base64-js
  // does not..
  if (encoding == "base64" && typeof subject == "string") {
    subject = stringtrim(subject);
    while (subject.length % 4 != 0) {
      subject = subject + "="; 
    }
  }

  var type;

  // Are we slicing?
  if (typeof offset === 'number') {
    this.length = coerce(encoding);
    // slicing works, with limitations (no parent tracking/update)
    // check https://github.com/toots/buffer-browserify/issues/19
    for (var i = 0; i < this.length; i++) {
        this[i] = subject.get(i+offset);
    }
  } else {
    // Find the length
    switch (type = typeof subject) {
      case 'number':
        this.length = coerce(subject);
        break;

      case 'string':
        this.length = Buffer.byteLength(subject, encoding);
        break;

      case 'object': // Assume object is an array
        this.length = coerce(subject.length);
        break;

      default:
        throw new Error('First argument needs to be a number, ' +
                        'array or string.');
    }

    // Treat array-ish objects as a byte array.
    if (isArrayIsh(subject)) {
      for (var i = 0; i < this.length; i++) {
        if (subject instanceof Buffer) {
          this[i] = subject.readUInt8(i);
        }
        else {
          this[i] = subject[i];
        }
      }
    } else if (type == 'string') {
      // We are a string
      this.length = this.write(subject, 0, encoding);
    } else if (type === 'number') {
      for (var i = 0; i < this.length; i++) {
        this[i] = 0;
      }
    }
  }
}

Buffer.prototype.get = function get(i) {
  if (i < 0 || i >= this.length) throw new Error('oob');
  return this[i];
};

Buffer.prototype.set = function set(i, v) {
  if (i < 0 || i >= this.length) throw new Error('oob');
  return this[i] = v;
};

Buffer.byteLength = function (str, encoding) {
  switch (encoding || "utf8") {
    case 'hex':
      return str.length / 2;

    case 'utf8':
    case 'utf-8':
      return utf8ToBytes(str).length;

    case 'ascii':
    case 'binary':
      return str.length;

    case 'base64':
      return base64ToBytes(str).length;

    default:
      throw new Error('Unknown encoding');
  }
};

Buffer.prototype.utf8Write = function (string, offset, length) {
  var bytes, pos;
  return Buffer._charsWritten =  blitBuffer(utf8ToBytes(string), this, offset, length);
};

Buffer.prototype.asciiWrite = function (string, offset, length) {
  var bytes, pos;
  return Buffer._charsWritten =  blitBuffer(asciiToBytes(string), this, offset, length);
};

Buffer.prototype.binaryWrite = Buffer.prototype.asciiWrite;

Buffer.prototype.base64Write = function (string, offset, length) {
  var bytes, pos;
  return Buffer._charsWritten = blitBuffer(base64ToBytes(string), this, offset, length);
};

Buffer.prototype.base64Slice = function (start, end) {
  var bytes = Array.prototype.slice.apply(this, arguments)
  return require("base64-js").fromByteArray(bytes);
};

Buffer.prototype.utf8Slice = function () {
  var bytes = Array.prototype.slice.apply(this, arguments);
  var res = "";
  var tmp = "";
  var i = 0;
  while (i < bytes.length) {
    if (bytes[i] <= 0x7F) {
      res += decodeUtf8Char(tmp) + String.fromCharCode(bytes[i]);
      tmp = "";
    } else
      tmp += "%" + bytes[i].toString(16);

    i++;
  }

  return res + decodeUtf8Char(tmp);
}

Buffer.prototype.asciiSlice = function () {
  var bytes = Array.prototype.slice.apply(this, arguments);
  var ret = "";
  for (var i = 0; i < bytes.length; i++)
    ret += String.fromCharCode(bytes[i]);
  return ret;
}

Buffer.prototype.binarySlice = Buffer.prototype.asciiSlice;

Buffer.prototype.inspect = function() {
  var out = [],
      len = this.length;
  for (var i = 0; i < len; i++) {
    out[i] = toHex(this[i]);
    if (i == exports.INSPECT_MAX_BYTES) {
      out[i + 1] = '...';
      break;
    }
  }
  return '<Buffer ' + out.join(' ') + '>';
};


Buffer.prototype.hexSlice = function(start, end) {
  var len = this.length;

  if (!start || start < 0) start = 0;
  if (!end || end < 0 || end > len) end = len;

  var out = '';
  for (var i = start; i < end; i++) {
    out += toHex(this[i]);
  }
  return out;
};


Buffer.prototype.toString = function(encoding, start, end) {
  encoding = String(encoding || 'utf8').toLowerCase();
  start = +start || 0;
  if (typeof end == 'undefined') end = this.length;

  // Fastpath empty strings
  if (+end == start) {
    return '';
  }

  switch (encoding) {
    case 'hex':
      return this.hexSlice(start, end);

    case 'utf8':
    case 'utf-8':
      return this.utf8Slice(start, end);

    case 'ascii':
      return this.asciiSlice(start, end);

    case 'binary':
      return this.binarySlice(start, end);

    case 'base64':
      return this.base64Slice(start, end);

    case 'ucs2':
    case 'ucs-2':
      return this.ucs2Slice(start, end);

    default:
      throw new Error('Unknown encoding');
  }
};


Buffer.prototype.hexWrite = function(string, offset, length) {
  offset = +offset || 0;
  var remaining = this.length - offset;
  if (!length) {
    length = remaining;
  } else {
    length = +length;
    if (length > remaining) {
      length = remaining;
    }
  }

  // must be an even number of digits
  var strLen = string.length;
  if (strLen % 2) {
    throw new Error('Invalid hex string');
  }
  if (length > strLen / 2) {
    length = strLen / 2;
  }
  for (var i = 0; i < length; i++) {
    var byte = parseInt(string.substr(i * 2, 2), 16);
    if (isNaN(byte)) throw new Error('Invalid hex string');
    this[offset + i] = byte;
  }
  Buffer._charsWritten = i * 2;
  return i;
};


Buffer.prototype.write = function(string, offset, length, encoding) {
  // Support both (string, offset, length, encoding)
  // and the legacy (string, encoding, offset, length)
  if (isFinite(offset)) {
    if (!isFinite(length)) {
      encoding = length;
      length = undefined;
    }
  } else {  // legacy
    var swap = encoding;
    encoding = offset;
    offset = length;
    length = swap;
  }

  offset = +offset || 0;
  var remaining = this.length - offset;
  if (!length) {
    length = remaining;
  } else {
    length = +length;
    if (length > remaining) {
      length = remaining;
    }
  }
  encoding = String(encoding || 'utf8').toLowerCase();

  switch (encoding) {
    case 'hex':
      return this.hexWrite(string, offset, length);

    case 'utf8':
    case 'utf-8':
      return this.utf8Write(string, offset, length);

    case 'ascii':
      return this.asciiWrite(string, offset, length);

    case 'binary':
      return this.binaryWrite(string, offset, length);

    case 'base64':
      return this.base64Write(string, offset, length);

    case 'ucs2':
    case 'ucs-2':
      return this.ucs2Write(string, offset, length);

    default:
      throw new Error('Unknown encoding');
  }
};

// slice(start, end)
function clamp(index, len, defaultValue) {
  if (typeof index !== 'number') return defaultValue;
  index = ~~index;  // Coerce to integer.
  if (index >= len) return len;
  if (index >= 0) return index;
  index += len;
  if (index >= 0) return index;
  return 0;
}

Buffer.prototype.slice = function(start, end) {
  var len = this.length;
  start = clamp(start, len, 0);
  end = clamp(end, len, len);
  return new Buffer(this, end - start, +start);
};

// copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
Buffer.prototype.copy = function(target, target_start, start, end) {
  var source = this;
  start || (start = 0);
  if (end === undefined || isNaN(end)) {
    end = this.length;
  }
  target_start || (target_start = 0);

  if (end < start) throw new Error('sourceEnd < sourceStart');

  // Copy 0 bytes; we're done
  if (end === start) return 0;
  if (target.length == 0 || source.length == 0) return 0;

  if (target_start < 0 || target_start >= target.length) {
    throw new Error('targetStart out of bounds');
  }

  if (start < 0 || start >= source.length) {
    throw new Error('sourceStart out of bounds');
  }

  if (end < 0 || end > source.length) {
    throw new Error('sourceEnd out of bounds');
  }

  // Are we oob?
  if (end > this.length) {
    end = this.length;
  }

  if (target.length - target_start < end - start) {
    end = target.length - target_start + start;
  }

  var temp = [];
  for (var i=start; i<end; i++) {
    assert.ok(typeof this[i] !== 'undefined', "copying undefined buffer bytes!");
    temp.push(this[i]);
  }

  for (var i=target_start; i<target_start+temp.length; i++) {
    target[i] = temp[i-target_start];
  }
};

// fill(value, start=0, end=buffer.length)
Buffer.prototype.fill = function fill(value, start, end) {
  value || (value = 0);
  start || (start = 0);
  end || (end = this.length);

  if (typeof value === 'string') {
    value = value.charCodeAt(0);
  }
  if (!(typeof value === 'number') || isNaN(value)) {
    throw new Error('value is not a number');
  }

  if (end < start) throw new Error('end < start');

  // Fill 0 bytes; we're done
  if (end === start) return 0;
  if (this.length == 0) return 0;

  if (start < 0 || start >= this.length) {
    throw new Error('start out of bounds');
  }

  if (end < 0 || end > this.length) {
    throw new Error('end out of bounds');
  }

  for (var i = start; i < end; i++) {
    this[i] = value;
  }
}

// Static methods
Buffer.isBuffer = function isBuffer(b) {
  return b instanceof Buffer || b instanceof Buffer;
};

Buffer.concat = function (list, totalLength) {
  if (!isArray(list)) {
    throw new Error("Usage: Buffer.concat(list, [totalLength])\n \
      list should be an Array.");
  }

  if (list.length === 0) {
    return new Buffer(0);
  } else if (list.length === 1) {
    return list[0];
  }

  if (typeof totalLength !== 'number') {
    totalLength = 0;
    for (var i = 0; i < list.length; i++) {
      var buf = list[i];
      totalLength += buf.length;
    }
  }

  var buffer = new Buffer(totalLength);
  var pos = 0;
  for (var i = 0; i < list.length; i++) {
    var buf = list[i];
    buf.copy(buffer, pos);
    pos += buf.length;
  }
  return buffer;
};

Buffer.isEncoding = function(encoding) {
  switch ((encoding + '').toLowerCase()) {
    case 'hex':
    case 'utf8':
    case 'utf-8':
    case 'ascii':
    case 'binary':
    case 'base64':
    case 'ucs2':
    case 'ucs-2':
    case 'utf16le':
    case 'utf-16le':
    case 'raw':
      return true;

    default:
      return false;
  }
};

// helpers

function coerce(length) {
  // Coerce length to a number (possibly NaN), round up
  // in case it's fractional (e.g. 123.456) then do a
  // double negate to coerce a NaN to 0. Easy, right?
  length = ~~Math.ceil(+length);
  return length < 0 ? 0 : length;
}

function isArray(subject) {
  return (Array.isArray ||
    function(subject){
      return {}.toString.apply(subject) == '[object Array]'
    })
    (subject)
}

function isArrayIsh(subject) {
  return isArray(subject) || Buffer.isBuffer(subject) ||
         subject && typeof subject === 'object' &&
         typeof subject.length === 'number';
}

function toHex(n) {
  if (n < 16) return '0' + n.toString(16);
  return n.toString(16);
}

function utf8ToBytes(str) {
  var byteArray = [];
  for (var i = 0; i < str.length; i++)
    if (str.charCodeAt(i) <= 0x7F)
      byteArray.push(str.charCodeAt(i));
    else {
      var h = encodeURIComponent(str.charAt(i)).substr(1).split('%');
      for (var j = 0; j < h.length; j++)
        byteArray.push(parseInt(h[j], 16));
    }

  return byteArray;
}

function asciiToBytes(str) {
  var byteArray = []
  for (var i = 0; i < str.length; i++ )
    // Node's code seems to be doing this and not & 0x7F..
    byteArray.push( str.charCodeAt(i) & 0xFF );

  return byteArray;
}

function base64ToBytes(str) {
  return require("base64-js").toByteArray(str);
}

function blitBuffer(src, dst, offset, length) {
  var pos, i = 0;
  while (i < length) {
    if ((i+offset >= dst.length) || (i >= src.length))
      break;

    dst[i + offset] = src[i];
    i++;
  }
  return i;
}

function decodeUtf8Char(str) {
  try {
    return decodeURIComponent(str);
  } catch (err) {
    return String.fromCharCode(0xFFFD); // UTF 8 invalid char
  }
}

// read/write bit-twiddling

Buffer.prototype.readUInt8 = function(offset, noAssert) {
  var buffer = this;

  if (!noAssert) {
    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset < buffer.length,
        'Trying to read beyond buffer length');
  }

  if (offset >= buffer.length) return;

  return buffer[offset];
};

function readUInt16(buffer, offset, isBigEndian, noAssert) {
  var val = 0;


  if (!noAssert) {
    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 1 < buffer.length,
        'Trying to read beyond buffer length');
  }

  if (offset >= buffer.length) return 0;

  if (isBigEndian) {
    val = buffer[offset] << 8;
    if (offset + 1 < buffer.length) {
      val |= buffer[offset + 1];
    }
  } else {
    val = buffer[offset];
    if (offset + 1 < buffer.length) {
      val |= buffer[offset + 1] << 8;
    }
  }

  return val;
}

Buffer.prototype.readUInt16LE = function(offset, noAssert) {
  return readUInt16(this, offset, false, noAssert);
};

Buffer.prototype.readUInt16BE = function(offset, noAssert) {
  return readUInt16(this, offset, true, noAssert);
};

function readUInt32(buffer, offset, isBigEndian, noAssert) {
  var val = 0;

  if (!noAssert) {
    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 3 < buffer.length,
        'Trying to read beyond buffer length');
  }

  if (offset >= buffer.length) return 0;

  if (isBigEndian) {
    if (offset + 1 < buffer.length)
      val = buffer[offset + 1] << 16;
    if (offset + 2 < buffer.length)
      val |= buffer[offset + 2] << 8;
    if (offset + 3 < buffer.length)
      val |= buffer[offset + 3];
    val = val + (buffer[offset] << 24 >>> 0);
  } else {
    if (offset + 2 < buffer.length)
      val = buffer[offset + 2] << 16;
    if (offset + 1 < buffer.length)
      val |= buffer[offset + 1] << 8;
    val |= buffer[offset];
    if (offset + 3 < buffer.length)
      val = val + (buffer[offset + 3] << 24 >>> 0);
  }

  return val;
}

Buffer.prototype.readUInt32LE = function(offset, noAssert) {
  return readUInt32(this, offset, false, noAssert);
};

Buffer.prototype.readUInt32BE = function(offset, noAssert) {
  return readUInt32(this, offset, true, noAssert);
};


/*
 * Signed integer types, yay team! A reminder on how two's complement actually
 * works. The first bit is the signed bit, i.e. tells us whether or not the
 * number should be positive or negative. If the two's complement value is
 * positive, then we're done, as it's equivalent to the unsigned representation.
 *
 * Now if the number is positive, you're pretty much done, you can just leverage
 * the unsigned translations and return those. Unfortunately, negative numbers
 * aren't quite that straightforward.
 *
 * At first glance, one might be inclined to use the traditional formula to
 * translate binary numbers between the positive and negative values in two's
 * complement. (Though it doesn't quite work for the most negative value)
 * Mainly:
 *  - invert all the bits
 *  - add one to the result
 *
 * Of course, this doesn't quite work in Javascript. Take for example the value
 * of -128. This could be represented in 16 bits (big-endian) as 0xff80. But of
 * course, Javascript will do the following:
 *
 * > ~0xff80
 * -65409
 *
 * Whoh there, Javascript, that's not quite right. But wait, according to
 * Javascript that's perfectly correct. When Javascript ends up seeing the
 * constant 0xff80, it has no notion that it is actually a signed number. It
 * assumes that we've input the unsigned value 0xff80. Thus, when it does the
 * binary negation, it casts it into a signed value, (positive 0xff80). Then
 * when you perform binary negation on that, it turns it into a negative number.
 *
 * Instead, we're going to have to use the following general formula, that works
 * in a rather Javascript friendly way. I'm glad we don't support this kind of
 * weird numbering scheme in the kernel.
 *
 * (BIT-MAX - (unsigned)val + 1) * -1
 *
 * The astute observer, may think that this doesn't make sense for 8-bit numbers
 * (really it isn't necessary for them). However, when you get 16-bit numbers,
 * you do. Let's go back to our prior example and see how this will look:
 *
 * (0xffff - 0xff80 + 1) * -1
 * (0x007f + 1) * -1
 * (0x0080) * -1
 */
Buffer.prototype.readInt8 = function(offset, noAssert) {
  var buffer = this;
  var neg;

  if (!noAssert) {
    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset < buffer.length,
        'Trying to read beyond buffer length');
  }

  if (offset >= buffer.length) return;

  neg = buffer[offset] & 0x80;
  if (!neg) {
    return (buffer[offset]);
  }

  return ((0xff - buffer[offset] + 1) * -1);
};

function readInt16(buffer, offset, isBigEndian, noAssert) {
  var neg, val;

  if (!noAssert) {
    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 1 < buffer.length,
        'Trying to read beyond buffer length');
  }

  val = readUInt16(buffer, offset, isBigEndian, noAssert);
  neg = val & 0x8000;
  if (!neg) {
    return val;
  }

  return (0xffff - val + 1) * -1;
}

Buffer.prototype.readInt16LE = function(offset, noAssert) {
  return readInt16(this, offset, false, noAssert);
};

Buffer.prototype.readInt16BE = function(offset, noAssert) {
  return readInt16(this, offset, true, noAssert);
};

function readInt32(buffer, offset, isBigEndian, noAssert) {
  var neg, val;

  if (!noAssert) {
    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 3 < buffer.length,
        'Trying to read beyond buffer length');
  }

  val = readUInt32(buffer, offset, isBigEndian, noAssert);
  neg = val & 0x80000000;
  if (!neg) {
    return (val);
  }

  return (0xffffffff - val + 1) * -1;
}

Buffer.prototype.readInt32LE = function(offset, noAssert) {
  return readInt32(this, offset, false, noAssert);
};

Buffer.prototype.readInt32BE = function(offset, noAssert) {
  return readInt32(this, offset, true, noAssert);
};

function readFloat(buffer, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset + 3 < buffer.length,
        'Trying to read beyond buffer length');
  }

  return require('./buffer_ieee754').readIEEE754(buffer, offset, isBigEndian,
      23, 4);
}

Buffer.prototype.readFloatLE = function(offset, noAssert) {
  return readFloat(this, offset, false, noAssert);
};

Buffer.prototype.readFloatBE = function(offset, noAssert) {
  return readFloat(this, offset, true, noAssert);
};

function readDouble(buffer, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset + 7 < buffer.length,
        'Trying to read beyond buffer length');
  }

  return require('./buffer_ieee754').readIEEE754(buffer, offset, isBigEndian,
      52, 8);
}

Buffer.prototype.readDoubleLE = function(offset, noAssert) {
  return readDouble(this, offset, false, noAssert);
};

Buffer.prototype.readDoubleBE = function(offset, noAssert) {
  return readDouble(this, offset, true, noAssert);
};


/*
 * We have to make sure that the value is a valid integer. This means that it is
 * non-negative. It has no fractional component and that it does not exceed the
 * maximum allowed value.
 *
 *      value           The number to check for validity
 *
 *      max             The maximum value
 */
function verifuint(value, max) {
  assert.ok(typeof (value) == 'number',
      'cannot write a non-number as a number');

  assert.ok(value >= 0,
      'specified a negative value for writing an unsigned value');

  assert.ok(value <= max, 'value is larger than maximum value for type');

  assert.ok(Math.floor(value) === value, 'value has a fractional component');
}

Buffer.prototype.writeUInt8 = function(value, offset, noAssert) {
  var buffer = this;

  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset < buffer.length,
        'trying to write beyond buffer length');

    verifuint(value, 0xff);
  }

  if (offset < buffer.length) {
    buffer[offset] = value;
  }
};

function writeUInt16(buffer, value, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 1 < buffer.length,
        'trying to write beyond buffer length');

    verifuint(value, 0xffff);
  }

  for (var i = 0; i < Math.min(buffer.length - offset, 2); i++) {
    buffer[offset + i] =
        (value & (0xff << (8 * (isBigEndian ? 1 - i : i)))) >>>
            (isBigEndian ? 1 - i : i) * 8;
  }

}

Buffer.prototype.writeUInt16LE = function(value, offset, noAssert) {
  writeUInt16(this, value, offset, false, noAssert);
};

Buffer.prototype.writeUInt16BE = function(value, offset, noAssert) {
  writeUInt16(this, value, offset, true, noAssert);
};

function writeUInt32(buffer, value, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 3 < buffer.length,
        'trying to write beyond buffer length');

    verifuint(value, 0xffffffff);
  }

  for (var i = 0; i < Math.min(buffer.length - offset, 4); i++) {
    buffer[offset + i] =
        (value >>> (isBigEndian ? 3 - i : i) * 8) & 0xff;
  }
}

Buffer.prototype.writeUInt32LE = function(value, offset, noAssert) {
  writeUInt32(this, value, offset, false, noAssert);
};

Buffer.prototype.writeUInt32BE = function(value, offset, noAssert) {
  writeUInt32(this, value, offset, true, noAssert);
};


/*
 * We now move onto our friends in the signed number category. Unlike unsigned
 * numbers, we're going to have to worry a bit more about how we put values into
 * arrays. Since we are only worrying about signed 32-bit values, we're in
 * slightly better shape. Unfortunately, we really can't do our favorite binary
 * & in this system. It really seems to do the wrong thing. For example:
 *
 * > -32 & 0xff
 * 224
 *
 * What's happening above is really: 0xe0 & 0xff = 0xe0. However, the results of
 * this aren't treated as a signed number. Ultimately a bad thing.
 *
 * What we're going to want to do is basically create the unsigned equivalent of
 * our representation and pass that off to the wuint* functions. To do that
 * we're going to do the following:
 *
 *  - if the value is positive
 *      we can pass it directly off to the equivalent wuint
 *  - if the value is negative
 *      we do the following computation:
 *         mb + val + 1, where
 *         mb   is the maximum unsigned value in that byte size
 *         val  is the Javascript negative integer
 *
 *
 * As a concrete value, take -128. In signed 16 bits this would be 0xff80. If
 * you do out the computations:
 *
 * 0xffff - 128 + 1
 * 0xffff - 127
 * 0xff80
 *
 * You can then encode this value as the signed version. This is really rather
 * hacky, but it should work and get the job done which is our goal here.
 */

/*
 * A series of checks to make sure we actually have a signed 32-bit number
 */
function verifsint(value, max, min) {
  assert.ok(typeof (value) == 'number',
      'cannot write a non-number as a number');

  assert.ok(value <= max, 'value larger than maximum allowed value');

  assert.ok(value >= min, 'value smaller than minimum allowed value');

  assert.ok(Math.floor(value) === value, 'value has a fractional component');
}

function verifIEEE754(value, max, min) {
  assert.ok(typeof (value) == 'number',
      'cannot write a non-number as a number');

  assert.ok(value <= max, 'value larger than maximum allowed value');

  assert.ok(value >= min, 'value smaller than minimum allowed value');
}

Buffer.prototype.writeInt8 = function(value, offset, noAssert) {
  var buffer = this;

  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset < buffer.length,
        'Trying to write beyond buffer length');

    verifsint(value, 0x7f, -0x80);
  }

  if (value >= 0) {
    buffer.writeUInt8(value, offset, noAssert);
  } else {
    buffer.writeUInt8(0xff + value + 1, offset, noAssert);
  }
};

function writeInt16(buffer, value, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 1 < buffer.length,
        'Trying to write beyond buffer length');

    verifsint(value, 0x7fff, -0x8000);
  }

  if (value >= 0) {
    writeUInt16(buffer, value, offset, isBigEndian, noAssert);
  } else {
    writeUInt16(buffer, 0xffff + value + 1, offset, isBigEndian, noAssert);
  }
}

Buffer.prototype.writeInt16LE = function(value, offset, noAssert) {
  writeInt16(this, value, offset, false, noAssert);
};

Buffer.prototype.writeInt16BE = function(value, offset, noAssert) {
  writeInt16(this, value, offset, true, noAssert);
};

function writeInt32(buffer, value, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 3 < buffer.length,
        'Trying to write beyond buffer length');

    verifsint(value, 0x7fffffff, -0x80000000);
  }

  if (value >= 0) {
    writeUInt32(buffer, value, offset, isBigEndian, noAssert);
  } else {
    writeUInt32(buffer, 0xffffffff + value + 1, offset, isBigEndian, noAssert);
  }
}

Buffer.prototype.writeInt32LE = function(value, offset, noAssert) {
  writeInt32(this, value, offset, false, noAssert);
};

Buffer.prototype.writeInt32BE = function(value, offset, noAssert) {
  writeInt32(this, value, offset, true, noAssert);
};

function writeFloat(buffer, value, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 3 < buffer.length,
        'Trying to write beyond buffer length');

    verifIEEE754(value, 3.4028234663852886e+38, -3.4028234663852886e+38);
  }

  require('./buffer_ieee754').writeIEEE754(buffer, value, offset, isBigEndian,
      23, 4);
}

Buffer.prototype.writeFloatLE = function(value, offset, noAssert) {
  writeFloat(this, value, offset, false, noAssert);
};

Buffer.prototype.writeFloatBE = function(value, offset, noAssert) {
  writeFloat(this, value, offset, true, noAssert);
};

function writeDouble(buffer, value, offset, isBigEndian, noAssert) {
  if (!noAssert) {
    assert.ok(value !== undefined && value !== null,
        'missing value');

    assert.ok(typeof (isBigEndian) === 'boolean',
        'missing or invalid endian');

    assert.ok(offset !== undefined && offset !== null,
        'missing offset');

    assert.ok(offset + 7 < buffer.length,
        'Trying to write beyond buffer length');

    verifIEEE754(value, 1.7976931348623157E+308, -1.7976931348623157E+308);
  }

  require('./buffer_ieee754').writeIEEE754(buffer, value, offset, isBigEndian,
      52, 8);
}

Buffer.prototype.writeDoubleLE = function(value, offset, noAssert) {
  writeDouble(this, value, offset, false, noAssert);
};

Buffer.prototype.writeDoubleBE = function(value, offset, noAssert) {
  writeDouble(this, value, offset, true, noAssert);
};

},{"./buffer_ieee754":1,"assert":6,"base64-js":4}],"buffer-browserify":[function(require,module,exports){
module.exports=require('q9TxCC');
},{}],4:[function(require,module,exports){
(function (exports) {
	'use strict';

	var lookup = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	function b64ToByteArray(b64) {
		var i, j, l, tmp, placeHolders, arr;
	
		if (b64.length % 4 > 0) {
			throw 'Invalid string. Length must be a multiple of 4';
		}

		// the number of equal signs (place holders)
		// if there are two placeholders, than the two characters before it
		// represent one byte
		// if there is only one, then the three characters before it represent 2 bytes
		// this is just a cheap hack to not do indexOf twice
		placeHolders = b64.indexOf('=');
		placeHolders = placeHolders > 0 ? b64.length - placeHolders : 0;

		// base64 is 4/3 + up to two characters of the original data
		arr = [];//new Uint8Array(b64.length * 3 / 4 - placeHolders);

		// if there are placeholders, only get up to the last complete 4 chars
		l = placeHolders > 0 ? b64.length - 4 : b64.length;

		for (i = 0, j = 0; i < l; i += 4, j += 3) {
			tmp = (lookup.indexOf(b64[i]) << 18) | (lookup.indexOf(b64[i + 1]) << 12) | (lookup.indexOf(b64[i + 2]) << 6) | lookup.indexOf(b64[i + 3]);
			arr.push((tmp & 0xFF0000) >> 16);
			arr.push((tmp & 0xFF00) >> 8);
			arr.push(tmp & 0xFF);
		}

		if (placeHolders === 2) {
			tmp = (lookup.indexOf(b64[i]) << 2) | (lookup.indexOf(b64[i + 1]) >> 4);
			arr.push(tmp & 0xFF);
		} else if (placeHolders === 1) {
			tmp = (lookup.indexOf(b64[i]) << 10) | (lookup.indexOf(b64[i + 1]) << 4) | (lookup.indexOf(b64[i + 2]) >> 2);
			arr.push((tmp >> 8) & 0xFF);
			arr.push(tmp & 0xFF);
		}

		return arr;
	}

	function uint8ToBase64(uint8) {
		var i,
			extraBytes = uint8.length % 3, // if we have 1 byte left, pad 2 bytes
			output = "",
			temp, length;

		function tripletToBase64 (num) {
			return lookup[num >> 18 & 0x3F] + lookup[num >> 12 & 0x3F] + lookup[num >> 6 & 0x3F] + lookup[num & 0x3F];
		};

		// go through the array every three bytes, we'll deal with trailing stuff later
		for (i = 0, length = uint8.length - extraBytes; i < length; i += 3) {
			temp = (uint8[i] << 16) + (uint8[i + 1] << 8) + (uint8[i + 2]);
			output += tripletToBase64(temp);
		}

		// pad the end with zeros, but make sure to not forget the extra bytes
		switch (extraBytes) {
			case 1:
				temp = uint8[uint8.length - 1];
				output += lookup[temp >> 2];
				output += lookup[(temp << 4) & 0x3F];
				output += '==';
				break;
			case 2:
				temp = (uint8[uint8.length - 2] << 8) + (uint8[uint8.length - 1]);
				output += lookup[temp >> 10];
				output += lookup[(temp >> 4) & 0x3F];
				output += lookup[(temp << 2) & 0x3F];
				output += '=';
				break;
		}

		return output;
	}

	module.exports.toByteArray = b64ToByteArray;
	module.exports.fromByteArray = uint8ToBase64;
}());

},{}],5:[function(require,module,exports){


//
// The shims in this file are not fully implemented shims for the ES5
// features, but do work for the particular usecases there is in
// the other modules.
//

var toString = Object.prototype.toString;
var hasOwnProperty = Object.prototype.hasOwnProperty;

// Array.isArray is supported in IE9
function isArray(xs) {
  return toString.call(xs) === '[object Array]';
}
exports.isArray = typeof Array.isArray === 'function' ? Array.isArray : isArray;

// Array.prototype.indexOf is supported in IE9
exports.indexOf = function indexOf(xs, x) {
  if (xs.indexOf) return xs.indexOf(x);
  for (var i = 0; i < xs.length; i++) {
    if (x === xs[i]) return i;
  }
  return -1;
};

// Array.prototype.filter is supported in IE9
exports.filter = function filter(xs, fn) {
  if (xs.filter) return xs.filter(fn);
  var res = [];
  for (var i = 0; i < xs.length; i++) {
    if (fn(xs[i], i, xs)) res.push(xs[i]);
  }
  return res;
};

// Array.prototype.forEach is supported in IE9
exports.forEach = function forEach(xs, fn, self) {
  if (xs.forEach) return xs.forEach(fn, self);
  for (var i = 0; i < xs.length; i++) {
    fn.call(self, xs[i], i, xs);
  }
};

// Array.prototype.map is supported in IE9
exports.map = function map(xs, fn) {
  if (xs.map) return xs.map(fn);
  var out = new Array(xs.length);
  for (var i = 0; i < xs.length; i++) {
    out[i] = fn(xs[i], i, xs);
  }
  return out;
};

// Array.prototype.reduce is supported in IE9
exports.reduce = function reduce(array, callback, opt_initialValue) {
  if (array.reduce) return array.reduce(callback, opt_initialValue);
  var value, isValueSet = false;

  if (2 < arguments.length) {
    value = opt_initialValue;
    isValueSet = true;
  }
  for (var i = 0, l = array.length; l > i; ++i) {
    if (array.hasOwnProperty(i)) {
      if (isValueSet) {
        value = callback(value, array[i], i, array);
      }
      else {
        value = array[i];
        isValueSet = true;
      }
    }
  }

  return value;
};

// String.prototype.substr - negative index don't work in IE8
if ('ab'.substr(-1) !== 'b') {
  exports.substr = function (str, start, length) {
    // did we get a negative start, calculate how much it is from the beginning of the string
    if (start < 0) start = str.length + start;

    // call the original function
    return str.substr(start, length);
  };
} else {
  exports.substr = function (str, start, length) {
    return str.substr(start, length);
  };
}

// String.prototype.trim is supported in IE9
exports.trim = function (str) {
  if (str.trim) return str.trim();
  return str.replace(/^\s+|\s+$/g, '');
};

// Function.prototype.bind is supported in IE9
exports.bind = function () {
  var args = Array.prototype.slice.call(arguments);
  var fn = args.shift();
  if (fn.bind) return fn.bind.apply(fn, args);
  var self = args.shift();
  return function () {
    fn.apply(self, args.concat([Array.prototype.slice.call(arguments)]));
  };
};

// Object.create is supported in IE9
function create(prototype, properties) {
  var object;
  if (prototype === null) {
    object = { '__proto__' : null };
  }
  else {
    if (typeof prototype !== 'object') {
      throw new TypeError(
        'typeof prototype[' + (typeof prototype) + '] != \'object\''
      );
    }
    var Type = function () {};
    Type.prototype = prototype;
    object = new Type();
    object.__proto__ = prototype;
  }
  if (typeof properties !== 'undefined' && Object.defineProperties) {
    Object.defineProperties(object, properties);
  }
  return object;
}
exports.create = typeof Object.create === 'function' ? Object.create : create;

// Object.keys and Object.getOwnPropertyNames is supported in IE9 however
// they do show a description and number property on Error objects
function notObject(object) {
  return ((typeof object != "object" && typeof object != "function") || object === null);
}

function keysShim(object) {
  if (notObject(object)) {
    throw new TypeError("Object.keys called on a non-object");
  }

  var result = [];
  for (var name in object) {
    if (hasOwnProperty.call(object, name)) {
      result.push(name);
    }
  }
  return result;
}

// getOwnPropertyNames is almost the same as Object.keys one key feature
//  is that it returns hidden properties, since that can't be implemented,
//  this feature gets reduced so it just shows the length property on arrays
function propertyShim(object) {
  if (notObject(object)) {
    throw new TypeError("Object.getOwnPropertyNames called on a non-object");
  }

  var result = keysShim(object);
  if (exports.isArray(object) && exports.indexOf(object, 'length') === -1) {
    result.push('length');
  }
  return result;
}

var keys = typeof Object.keys === 'function' ? Object.keys : keysShim;
var getOwnPropertyNames = typeof Object.getOwnPropertyNames === 'function' ?
  Object.getOwnPropertyNames : propertyShim;

if (new Error().hasOwnProperty('description')) {
  var ERROR_PROPERTY_FILTER = function (obj, array) {
    if (toString.call(obj) === '[object Error]') {
      array = exports.filter(array, function (name) {
        return name !== 'description' && name !== 'number' && name !== 'message';
      });
    }
    return array;
  };

  exports.keys = function (object) {
    return ERROR_PROPERTY_FILTER(object, keys(object));
  };
  exports.getOwnPropertyNames = function (object) {
    return ERROR_PROPERTY_FILTER(object, getOwnPropertyNames(object));
  };
} else {
  exports.keys = keys;
  exports.getOwnPropertyNames = getOwnPropertyNames;
}

// Object.getOwnPropertyDescriptor - supported in IE8 but only on dom elements
function valueObject(value, key) {
  return { value: value[key] };
}

if (typeof Object.getOwnPropertyDescriptor === 'function') {
  try {
    Object.getOwnPropertyDescriptor({'a': 1}, 'a');
    exports.getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  } catch (e) {
    // IE8 dom element issue - use a try catch and default to valueObject
    exports.getOwnPropertyDescriptor = function (value, key) {
      try {
        return Object.getOwnPropertyDescriptor(value, key);
      } catch (e) {
        return valueObject(value, key);
      }
    };
  }
} else {
  exports.getOwnPropertyDescriptor = valueObject;
}

},{}],6:[function(require,module,exports){
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

// UTILITY
var util = require('util');
var shims = require('_shims');
var pSlice = Array.prototype.slice;

// 1. The assert module provides functions that throw
// AssertionError's when particular conditions are not met. The
// assert module must conform to the following interface.

var assert = module.exports = ok;

// 2. The AssertionError is defined in assert.
// new assert.AssertionError({ message: message,
//                             actual: actual,
//                             expected: expected })

assert.AssertionError = function AssertionError(options) {
  this.name = 'AssertionError';
  this.actual = options.actual;
  this.expected = options.expected;
  this.operator = options.operator;
  this.message = options.message || getMessage(this);
};

// assert.AssertionError instanceof Error
util.inherits(assert.AssertionError, Error);

function replacer(key, value) {
  if (util.isUndefined(value)) {
    return '' + value;
  }
  if (util.isNumber(value) && (isNaN(value) || !isFinite(value))) {
    return value.toString();
  }
  if (util.isFunction(value) || util.isRegExp(value)) {
    return value.toString();
  }
  return value;
}

function truncate(s, n) {
  if (util.isString(s)) {
    return s.length < n ? s : s.slice(0, n);
  } else {
    return s;
  }
}

function getMessage(self) {
  return truncate(JSON.stringify(self.actual, replacer), 128) + ' ' +
         self.operator + ' ' +
         truncate(JSON.stringify(self.expected, replacer), 128);
}

// At present only the three keys mentioned above are used and
// understood by the spec. Implementations or sub modules can pass
// other keys to the AssertionError's constructor - they will be
// ignored.

// 3. All of the following functions must throw an AssertionError
// when a corresponding condition is not met, with a message that
// may be undefined if not provided.  All assertion methods provide
// both the actual and expected values to the assertion error for
// display purposes.

function fail(actual, expected, message, operator, stackStartFunction) {
  throw new assert.AssertionError({
    message: message,
    actual: actual,
    expected: expected,
    operator: operator,
    stackStartFunction: stackStartFunction
  });
}

// EXTENSION! allows for well behaved errors defined elsewhere.
assert.fail = fail;

// 4. Pure assertion tests whether a value is truthy, as determined
// by !!guard.
// assert.ok(guard, message_opt);
// This statement is equivalent to assert.equal(true, !!guard,
// message_opt);. To test strictly for the value true, use
// assert.strictEqual(true, guard, message_opt);.

function ok(value, message) {
  if (!value) fail(value, true, message, '==', assert.ok);
}
assert.ok = ok;

// 5. The equality assertion tests shallow, coercive equality with
// ==.
// assert.equal(actual, expected, message_opt);

assert.equal = function equal(actual, expected, message) {
  if (actual != expected) fail(actual, expected, message, '==', assert.equal);
};

// 6. The non-equality assertion tests for whether two objects are not equal
// with != assert.notEqual(actual, expected, message_opt);

assert.notEqual = function notEqual(actual, expected, message) {
  if (actual == expected) {
    fail(actual, expected, message, '!=', assert.notEqual);
  }
};

// 7. The equivalence assertion tests a deep equality relation.
// assert.deepEqual(actual, expected, message_opt);

assert.deepEqual = function deepEqual(actual, expected, message) {
  if (!_deepEqual(actual, expected)) {
    fail(actual, expected, message, 'deepEqual', assert.deepEqual);
  }
};

function _deepEqual(actual, expected) {
  // 7.1. All identical values are equivalent, as determined by ===.
  if (actual === expected) {
    return true;

  } else if (util.isBuffer(actual) && util.isBuffer(expected)) {
    if (actual.length != expected.length) return false;

    for (var i = 0; i < actual.length; i++) {
      if (actual[i] !== expected[i]) return false;
    }

    return true;

  // 7.2. If the expected value is a Date object, the actual value is
  // equivalent if it is also a Date object that refers to the same time.
  } else if (util.isDate(actual) && util.isDate(expected)) {
    return actual.getTime() === expected.getTime();

  // 7.3 If the expected value is a RegExp object, the actual value is
  // equivalent if it is also a RegExp object with the same source and
  // properties (`global`, `multiline`, `lastIndex`, `ignoreCase`).
  } else if (util.isRegExp(actual) && util.isRegExp(expected)) {
    return actual.source === expected.source &&
           actual.global === expected.global &&
           actual.multiline === expected.multiline &&
           actual.lastIndex === expected.lastIndex &&
           actual.ignoreCase === expected.ignoreCase;

  // 7.4. Other pairs that do not both pass typeof value == 'object',
  // equivalence is determined by ==.
  } else if (!util.isObject(actual) && !util.isObject(expected)) {
    return actual == expected;

  // 7.5 For all other Object pairs, including Array objects, equivalence is
  // determined by having the same number of owned properties (as verified
  // with Object.prototype.hasOwnProperty.call), the same set of keys
  // (although not necessarily the same order), equivalent values for every
  // corresponding key, and an identical 'prototype' property. Note: this
  // accounts for both named and indexed properties on Arrays.
  } else {
    return objEquiv(actual, expected);
  }
}

function isArguments(object) {
  return Object.prototype.toString.call(object) == '[object Arguments]';
}

function objEquiv(a, b) {
  if (util.isNullOrUndefined(a) || util.isNullOrUndefined(b))
    return false;
  // an identical 'prototype' property.
  if (a.prototype !== b.prototype) return false;
  //~~~I've managed to break Object.keys through screwy arguments passing.
  //   Converting to array solves the problem.
  if (isArguments(a)) {
    if (!isArguments(b)) {
      return false;
    }
    a = pSlice.call(a);
    b = pSlice.call(b);
    return _deepEqual(a, b);
  }
  try {
    var ka = shims.keys(a),
        kb = shims.keys(b),
        key, i;
  } catch (e) {//happens when one is a string literal and the other isn't
    return false;
  }
  // having the same number of owned properties (keys incorporates
  // hasOwnProperty)
  if (ka.length != kb.length)
    return false;
  //the same set of keys (although not necessarily the same order),
  ka.sort();
  kb.sort();
  //~~~cheap key test
  for (i = ka.length - 1; i >= 0; i--) {
    if (ka[i] != kb[i])
      return false;
  }
  //equivalent values for every corresponding key, and
  //~~~possibly expensive deep test
  for (i = ka.length - 1; i >= 0; i--) {
    key = ka[i];
    if (!_deepEqual(a[key], b[key])) return false;
  }
  return true;
}

// 8. The non-equivalence assertion tests for any deep inequality.
// assert.notDeepEqual(actual, expected, message_opt);

assert.notDeepEqual = function notDeepEqual(actual, expected, message) {
  if (_deepEqual(actual, expected)) {
    fail(actual, expected, message, 'notDeepEqual', assert.notDeepEqual);
  }
};

// 9. The strict equality assertion tests strict equality, as determined by ===.
// assert.strictEqual(actual, expected, message_opt);

assert.strictEqual = function strictEqual(actual, expected, message) {
  if (actual !== expected) {
    fail(actual, expected, message, '===', assert.strictEqual);
  }
};

// 10. The strict non-equality assertion tests for strict inequality, as
// determined by !==.  assert.notStrictEqual(actual, expected, message_opt);

assert.notStrictEqual = function notStrictEqual(actual, expected, message) {
  if (actual === expected) {
    fail(actual, expected, message, '!==', assert.notStrictEqual);
  }
};

function expectedException(actual, expected) {
  if (!actual || !expected) {
    return false;
  }

  if (Object.prototype.toString.call(expected) == '[object RegExp]') {
    return expected.test(actual);
  } else if (actual instanceof expected) {
    return true;
  } else if (expected.call({}, actual) === true) {
    return true;
  }

  return false;
}

function _throws(shouldThrow, block, expected, message) {
  var actual;

  if (util.isString(expected)) {
    message = expected;
    expected = null;
  }

  try {
    block();
  } catch (e) {
    actual = e;
  }

  message = (expected && expected.name ? ' (' + expected.name + ').' : '.') +
            (message ? ' ' + message : '.');

  if (shouldThrow && !actual) {
    fail(actual, expected, 'Missing expected exception' + message);
  }

  if (!shouldThrow && expectedException(actual, expected)) {
    fail(actual, expected, 'Got unwanted exception' + message);
  }

  if ((shouldThrow && actual && expected &&
      !expectedException(actual, expected)) || (!shouldThrow && actual)) {
    throw actual;
  }
}

// 11. Expected to throw an error:
// assert.throws(block, Error_opt, message_opt);

assert.throws = function(block, /*optional*/error, /*optional*/message) {
  _throws.apply(this, [true].concat(pSlice.call(arguments)));
};

// EXTENSION! This is annoying to write outside this module.
assert.doesNotThrow = function(block, /*optional*/message) {
  _throws.apply(this, [false].concat(pSlice.call(arguments)));
};

assert.ifError = function(err) { if (err) {throw err;}};
},{"_shims":5,"util":7}],7:[function(require,module,exports){
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

var shims = require('_shims');

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

  shims.forEach(array, function(val, idx) {
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
    var ret = value.inspect(recurseTimes);
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
  var keys = shims.keys(value);
  var visibleKeys = arrayToHash(keys);

  if (ctx.showHidden) {
    keys = shims.getOwnPropertyNames(value);
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

  shims.forEach(keys, function(key) {
    if (!key.match(/^\d+$/)) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          key, true));
    }
  });
  return output;
}


function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
  var name, str, desc;
  desc = shims.getOwnPropertyDescriptor(value, key) || { value: value[key] };
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
    if (shims.indexOf(ctx.seen, desc.value) < 0) {
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
  var length = shims.reduce(output, function(prev, cur) {
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
  return shims.isArray(ar);
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
  return typeof arg === 'object' && arg;
}
exports.isObject = isObject;

function isDate(d) {
  return isObject(d) && objectToString(d) === '[object Date]';
}
exports.isDate = isDate;

function isError(e) {
  return isObject(e) && objectToString(e) === '[object Error]';
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

function isBuffer(arg) {
  return arg instanceof Buffer;
}
exports.isBuffer = isBuffer;

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
exports.inherits = function(ctor, superCtor) {
  ctor.super_ = superCtor;
  ctor.prototype = shims.create(superCtor.prototype, {
    constructor: {
      value: ctor,
      enumerable: false,
      writable: true,
      configurable: true
    }
  });
};

exports._extend = function(origin, add) {
  // Don't do anything if add isn't an object
  if (!add || !isObject(add)) return origin;

  var keys = shims.keys(add);
  var i = keys.length;
  while (i--) {
    origin[keys[i]] = add[keys[i]];
  }
  return origin;
};

function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

},{"_shims":5}]},{},[])
;;module.exports=require("buffer-browserify")

},{}],17:[function(require,module,exports){
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
            if (ev.source === window && ev.data === 'process-tick') {
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

},{}]},{},[1])
(1)
});
;