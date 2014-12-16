!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.waterline=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/**
 * Aggregate Queries Adapter Normalization
 */

var _ = require('lodash'),
    async = require('async'),
    normalize = require('../utils/normalize'),
    hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;

module.exports = {

  // If an optimized createEach exists, use it, otherwise use an asynchronous loop with create()
  createEach: function(valuesList, cb) {
    var self = this,
        connName,
        adapter;

    // Normalize Arguments
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = "No createEach() or create() method defined in adapter!";

    // Custom user adapter behavior
    if(hasOwnProperty(this.dictionary, 'createEach')) {
      connName = this.dictionary.createEach;
      adapter = this.connections[connName]._adapter;

      if(hasOwnProperty(adapter, 'createEach')) {
        return adapter.createEach(connName, this.collection, valuesList, cb);
      }
    }

    // Default behavior
    // WARNING: Not transactional!  (unless your data adapter is)
    var results = [];

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'create')) return cb(new Error(err));

    connName = this.dictionary.create;
    adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'create')) return cb(new Error(err));

    async.forEachSeries(valuesList, function (values, cb) {
      adapter.create(connName, self.collection, values, function(err, row) {
        if(err) return cb(err);
        results.push(row);
        cb();
      });
    }, function(err) {
      if(err) return cb(err);
      cb(null, results);
    });
  },

  // If an optimized findOrCreateEach exists, use it, otherwise use an asynchronous loop with create()
  findOrCreateEach: function(attributesToCheck, valuesList, cb) {
    var self = this,
        connName,
        adapter;

    // Normalize Arguments
    cb = normalize.callback(cb);

    // Clone sensitive data
    attributesToCheck = _.clone(attributesToCheck);
    valuesList = _.clone(valuesList);

    // Custom user adapter behavior
    if(hasOwnProperty(this.dictionary, 'findOrCreateEach')) {
      connName = this.dictionary.findOrCreateEach;
      adapter = this.connections[connName]._adapter;

      if(hasOwnProperty(adapter, 'findOrCreateEach')) {
        return adapter.findOrCreateEach(connName, this.collection, valuesList, cb);
      }
    }

    // Build a list of models
    var models = [];

    async.forEachSeries(valuesList, function (values, cb) {
      if (!_.isObject(values)) return cb(new Error('findOrCreateEach: Unexpected value in valuesList.'));

      // Check that each of the criteria keys match:
      // build a criteria query
      var criteria = {};
      attributesToCheck.forEach(function (attrName) {
        criteria[attrName] = values[attrName];
      });

      return self.findOrCreate.call(self, criteria, values, function (err, model) {
        if(err) return cb(err);

        // Add model to list
        if(model) models.push(model);

        cb(null, model);
      });
    }, function (err) {
      if(err) return cb(err);
      cb(null, models);
    });
  }

};

},{"../utils/helpers":70,"../utils/normalize":76,"async":"async","lodash":"lodash"}],2:[function(require,module,exports){
/**
 * Compound Queries Adapter Normalization
 */

var _ = require('lodash'),
    normalize = require('../utils/normalize'),
    hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;

module.exports = {

  findOrCreate: function(criteria, values, cb) {
    var self = this,
        connName,
        adapter;

    // If no values were specified, use criteria
    if (!values) values = criteria.where ? criteria.where : criteria;

    // Normalize Arguments
    criteria = normalize.criteria(criteria);
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = "No find() or create() method defined in adapter!";

    // Custom user adapter behavior
    if(hasOwnProperty(this.dictionary, 'findOrCreate')) {
      connName = this.dictionary.findOrCreate;
      adapter = this.connections[connName]._adapter;

      if(hasOwnProperty(adapter, 'findOrCreate')) {
        return adapter.findOrCreate(connName, this.collection, values, cb);
      }
    }

    // Default behavior
    // WARNING: Not transactional!  (unless your data adapter is)
    this.findOne(criteria, function(err, result) {
      if(err) return cb(err);
      if(result) return cb(null, result[0]);

      self.create(values, cb);
    });
  }

};

},{"../utils/helpers":70,"../utils/normalize":76,"lodash":"lodash"}],3:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash'),
    normalize = require('../../utils/normalize'),
    getRelations = require('../../utils/getRelations'),
    hasOwnProperty = require('../../utils/helpers').object.hasOwnProperty;



/**
 * DDL Adapter Normalization
 */

module.exports = {

  define: function(cb) {
    var self = this;

    // Normalize Arguments
    cb = normalize.callback(cb);

    // Build Default Error Message
    var errMsg = 'No define() method defined in adapter!';

    // Grab attributes from definition
    var schema = _.clone(this.query._schema.schema) || {};

    // Find any junctionTables that reference this collection
    var relations = getRelations({
      schema: self.query.waterline.schema,
      parentCollection: self.collection
    });

    //
    // TODO: if junction tables don't exist, define them
    // console.log(relations);
    //

    // Verify that collection doesn't already exist
    // and then define it and trigger callback
    this.describe(function(err, existingAttributes) {
      if(err) return cb(err);
      if(existingAttributes) return cb(new Error('Trying to define a collection (' + self.collection + ') which already exists.'));

      // Remove hasMany association keys before sending down to adapter
      Object.keys(schema).forEach(function(key) {
        if(schema[key].type) return;
        delete schema[key];
      });

      // Find the connection to run this on
      if(!hasOwnProperty(self.dictionary, 'define')) return cb();

      var connName = self.dictionary.define;
      var adapter = self.connections[connName]._adapter;

      if(!hasOwnProperty(adapter, 'define')) return cb(new Error(errMsg));
      adapter.define(connName, self.collection, schema, cb);
    });
  },

  describe: function(cb) {

    // Normalize Arguments
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = 'No describe() method defined in adapter!';

    // Find the connection to run this on
    // NOTE: if `describe` doesn't exist, an error is not being returned.
    if(!hasOwnProperty(this.dictionary, 'describe')) return cb();

    var connName = this.dictionary.describe;
    var adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'describe')) return cb(new Error(err));
    adapter.describe(connName, this.collection, cb);
  },

  drop: function(relations, cb) {
    // Allow relations to be optional
    if(typeof relations === 'function') {
      cb = relations;
      relations = [];
    }

    relations = [];

    //
    // TODO:
    // Use a more normalized strategy to get relations so we can omit the extra argument above.
    // e.g. getRelations({ schema: self.query.waterline.schema, parentCollection: self.collection });
    //

    // Normalize Arguments
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = 'No drop() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'drop')) return cb(new Error(err));

    var connName = this.dictionary.drop;
    var adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'drop')) return cb(new Error(err));
    adapter.drop(connName, this.collection, relations, cb);
  },

  alter: function (cb) {

    // Normalize arguments
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = 'No alter() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'alter')) return cb(new Error(err));

    var connName = this.dictionary.alter;
    var adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'alter')) return cb(new Error(err));
    adapter.alter(connName, this.collection, cb);
  }

};

},{"../../utils/getRelations":69,"../../utils/helpers":70,"../../utils/normalize":76,"lodash":"lodash"}],4:[function(require,module,exports){
/**
 * Module Dependencies
 */

var normalize = require('../utils/normalize');
var schema = require('../utils/schema');
var hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;




/**
 * DQL Adapter Normalization
 */
module.exports = {

  hasJoin: function() {
    return hasOwnProperty(this.dictionary, 'join');
  },


  /**
   * join()
   *
   * If `join` is defined in the adapter, Waterline will use it to optimize
   * the `.populate()` implementation when joining collections within the same
   * database connection.
   *
   * @param  {[type]}   criteria
   * @param  {Function} cb
   */
  join: function(criteria, cb) {

    // Normalize Arguments
    criteria = normalize.criteria(criteria);
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = 'No join() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'join')) return cb(new Error(err));

    var connName = this.dictionary.join;
    var adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'join')) return cb(new Error(err));

    // Parse Join Criteria and set references to any collection tableName properties.
    // This is done here so that everywhere else in the codebase can use the collection identity.
    criteria = schema.serializeJoins(criteria, this.query.waterline.schema);

    adapter.join(connName, this.collection, criteria, cb);
  },


  /**
   * create()
   *
   * Create one or more models.
   *
   * @param  {[type]}   values [description]
   * @param  {Function} cb     [description]
   * @return {[type]}          [description]
   */
  create: function(values, cb) {

    var globalId = this.query.globalId;

    // Normalize Arguments
    cb = normalize.callback(cb);

    if(Array.isArray(values)) return this.createEach.call(this, values, cb);

    // Build Default Error Message
    var err = 'No create() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'create')) return cb(new Error(err));

    var connName = this.dictionary.create;
    var adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'create')) return cb(new Error(err));
    adapter.create(connName, this.collection, values, normalize.callback(function afterwards (err, createdRecord) {
      if (err) {
        if (typeof err === 'object') err.model = globalId;
        return cb(err);
      }
      else return cb(null, createdRecord);
    }));
  },



  /**
   * find()
   *
   * Find a set of models.
   *
   * @param  {[type]}   criteria [description]
   * @param  {Function} cb       [description]
   * @return {[type]}            [description]
   */
  find: function(criteria, cb) {

    // Normalize Arguments
    criteria = normalize.criteria(criteria);
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = 'No find() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'find')) return cb(new Error(err));

    var connName = this.dictionary.find;
    var adapter = this.connections[connName]._adapter;

    if(!adapter.find) return cb(new Error(err));
    adapter.find(connName, this.collection, criteria, cb);
  },


  /**
   * findOne()
   *
   * Find exactly one model.
   *
   * @param  {[type]}   criteria [description]
   * @param  {Function} cb       [description]
   * @return {[type]}            [description]
   */
  findOne: function(criteria, cb) {

    // Normalize Arguments
    cb = normalize.callback(cb);

    // Build Default Error Message
    var err = '.findOne() requires a criteria. If you want the first record try .find().limit(1)';

    // If no criteria is specified or where is empty return an error
    if(!criteria || criteria.where === null) return cb(new Error(err));

    // Detects if there is a `findOne` in the adapter. Use it if it exists.
    if(hasOwnProperty(this.dictionary, 'findOne')) {
      var connName = this.dictionary.findOne;
      var adapter = this.connections[connName]._adapter;

      if(adapter.findOne) {
        // Normalize Arguments
        criteria = normalize.criteria(criteria);
        return adapter.findOne(connName, this.collection, criteria, cb);
      }
    }

    // Fallback to use `find()` to simulate a `findOne()`
    // Enforce limit to 1
    criteria.limit = 1;

    this.find(criteria, function(err, models) {
      if(!models) return cb(err);
      if(models.length < 1) return cb(err);

      cb(null, models);
    });
  },

  /**
   * [count description]
   * @param  {[type]}   criteria [description]
   * @param  {Function} cb       [description]
   * @return {[type]}            [description]
   */
  count: function(criteria, cb) {
    var connName;

    // Normalize Arguments
    cb = normalize.callback(cb);
    criteria = normalize.criteria(criteria);

    // Build Default Error Message
    var err = '.count() requires the adapter define either a count method or a find method';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'count')) {

      // If a count method isn't defined make sure a find method is
      if(!hasOwnProperty(this.dictionary, 'find')) return cb(new Error(err));

      // Use the find method
      connName = this.dictionary.find;
    }

    if(!connName) connName = this.dictionary.count;
    var adapter = this.connections[connName]._adapter;

    if(hasOwnProperty(adapter, 'count')) return adapter.count(connName, this.collection, criteria, cb);

    this.find(criteria, function(err, models) {
      if(err) return cb(err);
      var count = models && models.length || 0;
      cb(err, count);
    });
  },


  /**
   * [update description]
   * @param  {[type]}   criteria [description]
   * @param  {[type]}   values   [description]
   * @param  {Function} cb       [description]
   * @return {[type]}            [description]
   */
  update: function (criteria, values, cb) {
    var globalId = this.query.globalId;


    // Normalize Arguments
    cb = normalize.callback(cb);
    criteria = normalize.criteria(criteria);

    if (criteria === false) {
      return cb(null, []);
    }
    else if(!criteria) {
      return cb(new Error('No criteria or id specified!'));
    }

    // Build Default Error Message
    var err = 'No update() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'update')) return cb(new Error(err));

    var connName = this.dictionary.update;
    var adapter = this.connections[connName]._adapter;

    adapter.update(connName, this.collection, criteria, values, normalize.callback(function afterwards (err, updatedRecords) {
      if (err) {
        if (typeof err === 'object') err.model = globalId;
        return cb(err);
      }
      return cb(null, updatedRecords);
    }));
  },


  /**
   * [destroy description]
   * @param  {[type]}   criteria [description]
   * @param  {Function} cb       [description]
   * @return {[type]}            [description]
   */
  destroy: function(criteria, cb) {

    // Normalize Arguments
    cb = normalize.callback(cb);
    criteria = normalize.criteria(criteria);

    // Build Default Error Message
    var err = 'No destroy() method defined in adapter!';

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'destroy')) return cb(new Error(err));

    var connName = this.dictionary.destroy;
    var adapter = this.connections[connName]._adapter;

    adapter.destroy(connName, this.collection, criteria, cb);
  }

};

},{"../utils/helpers":70,"../utils/normalize":76,"../utils/schema":77}],5:[function(require,module,exports){
/**
 * Base Adapter Definition
 */

var _ = require('lodash');

var Adapter = module.exports = function(options) {

  // Ensure the connections are set
  this.connections = options.connections || {};

  // Ensure the dictionary is built
  this.dictionary = options.dictionary || {};

  // Set a Query instance to get access to top
  // level query functions
  this.query = options.query || {};

  // Set Collection Name
  this.collection = options.collection || '';

  // Set Model Identity
  this.identity = options.identity || '';

  return this;
};

_.extend(
  Adapter.prototype,
  require('./dql'),
  require('./ddl'),
  require('./compoundQueries'),
  require('./aggregateQueries'),
  require('./setupTeardown'),
  require('./sync'),
  require('./stream')
);

},{"./aggregateQueries":1,"./compoundQueries":2,"./ddl":3,"./dql":4,"./setupTeardown":6,"./stream":7,"./sync":8,"lodash":"lodash"}],6:[function(require,module,exports){
/**
 * Setup and Teardown Adapter Normalization
 */

module.exports = {

  // Teardown is fired once-per-adapter
  // Should tear down any open connections, etc. for each collection
  // (i.e. tear down any remaining connections to the underlying data model)
  // (i.e. flush data to disk before the adapter shuts down)
  teardown: function(cb) {
    if (this.adapter.teardown)
      return this.adapter.teardown.apply(this, arguments);

    cb();
  }

};

},{}],7:[function(require,module,exports){
/**
 * Module Dependencies
 */

var normalize = require('../utils/normalize'),
    hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;

/**
 * Stream Normalization
 */

module.exports = {

  // stream.write() is used to send data
  // Must call stream.end() to complete stream
  stream: function (criteria, stream) {

    // Normalize Arguments
    criteria = normalize.criteria(criteria);

    // Build Default Error Message
    var err = "No stream() method defined in adapter!";

    // Find the connection to run this on
    if(!hasOwnProperty(this.dictionary, 'stream')) return stream.end(new Error(err));

    var connName = this.dictionary.stream;
    var adapter = this.connections[connName]._adapter;

    if(!hasOwnProperty(adapter, 'stream')) return stream.end(new Error(err));
    adapter.stream(connName, this.collection, criteria, stream);
  }

};

},{"../utils/helpers":70,"../utils/normalize":76}],8:[function(require,module,exports){
// TODO: probably can eliminate this file
module.exports = {
  migrateDrop: require('./strategies/drop.js'),
  migrateAlter: require('./strategies/alter.js'),
  migrateSafe: require('./strategies/safe.js')
};

},{"./strategies/alter.js":9,"./strategies/drop.js":10,"./strategies/safe.js":11}],9:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash'),
  async = require('async'),
  getRelations = require('../../../utils/getRelations');



/**
 * Try and synchronize the underlying physical-layer schema
 * to work with our app's collections. (i.e. models)
 *
 * @param  {Function} cb
 */
module.exports = function(cb) {
  var self = this;


  //
  // TODO:
  // Refuse to run this migration strategy in production.
  //

  // Find any junctionTables that reference this collection
  var relations = getRelations({
    schema: self.query.waterline.schema,
    parentCollection: self.collection
  });

  var backupData;

  // Check that collection exists--
  self.describe(function afterDescribe(err, attrs) {

    if(err) return cb(err);

    // if it doesn't go ahead and add it and get out
    if(!attrs) return self.define(cb);

    var collectionName = _.find(self.query.waterline.schema, {tableName: self.collection}).identity;

    // Create a mapping of column names -> attribute names
    var columnNamesMap = _.reduce(self.query.waterline.schema[collectionName].attributes, function(memo, val, key) {
      // If the attribute has a custom column name, use it as the key for the mapping
      if (val.columnName) {
        memo[val.columnName] = key;
      }
      // Otherwise just use the attribute name
      else {
        memo[key] = key;
      }
      return memo;
    }, {});

    // Transform column names into attribute names using the columnNamesMap,
    // removing attributes that no longer exist (they will be dropped)
    attrs = _.compact(_.keys(attrs).map(function(key) {
      return columnNamesMap[key];
    }));

    //
    // TODO:
    // Take a look and see if anything important has changed.
    // If it has (at all), we still have to follow the naive strategy below,
    // but it will at least save time in the general case.
    // (because it really sucks to have to wait for all of this to happen
    //  every time you initialize Waterline.)
    //


    //
    // OK so we have to fix up the schema and migrate the data...
    //
    // ... we'll let Waterline do it for us.
    //
    // Load all data from this collection into memory.
    // If this doesn't work, crash to avoid corrupting any data.
    // (see `waterline/lib/adapter/ddl/README.md` for more info about this)
    //
    // Make sure we only select the existing keys for the schema.
    // The default "find all" will select each attribute in the schema, which
    // now includes attributes that haven't been added to the table yet, so
    // on SQL databases the query will fail with "unknown field" error.
    self.find({select: attrs}, function (err, existingData) {

      if (err) {
        //
        // TODO:
        // If this was a memory error, log a more useful error
        // explaining what happened.
        //
        return cb(err);
      }

      //
      // From this point forward, we must be very careful.
      //
      backupData = _.cloneDeep(existingData);

      // Check to see if there is anything obviously troublesome
      // that will cause the drop and redefinition of our schemaful
      // collections to fail.
      // (i.e. violation of uniqueness constraints)
      var attrs = self.query.waterline.collections[self.identity]._attributes;
      var pk = self.query.waterline.collections[self.identity].primaryKey;
      var attrsAsArray = _.reduce(_.cloneDeep(attrs), function (memo,attrDef,attrName) {
        attrDef.name = attrName;
        memo.push(attrDef);
        return memo;
      }, []);
      var uniqueAttrs = _.where(attrsAsArray, {unique: true});
      async.each(uniqueAttrs, function (uniqueAttr, each_cb) {
        var uniqueData = _.uniq(_.pluck(existingData, uniqueAttr.name));

        // Remove any unique values who have their values set to undefined or null
        var cleansedExistingData = _.filter(existingData, function(val) {
          return [undefined, null].indexOf(val[uniqueAttr.name]) < 0;
        });

        // Remove any undefined or null values from the unique data
        var cleansedUniqueData = _.filter(uniqueData, function(val) {
          return [undefined, null].indexOf(val) < 0;
        });

        return each_cb();
      }, function afterAsyncEach (err) {
        if (err) return cb(err);

        // Now we'll drop the collection.
        self.drop(relations, function (err) {
          if (err) return uhoh(err, backupData, cb);

          // Now we'll redefine the collection.
          self.define(function (err) {
            if (err) return uhoh(err, backupData, cb);

            // Now we'll create the `backupData` again,
            // being careful not to run any lifecycle callbacks
            // and disable automatic updating of `createdAt` and
            // `updatedAt` attributes:
            //
            // ((((TODO: actually be careful about said things))))
            //
            self.createEach(backupData, function(err) {
              if (err) return uhoh(err, backupData, cb);

              // Done.
              return cb();
            });

          }); // </define>
        }); // </drop>
      }); // </find>
    });





    //
    // The old way-- (doesn't always work, and is way more
    // complex than we should spend time on for now)
    //
    //   ||      ||      ||      ||      ||      ||
    //   \/      \/      \/      \/      \/      \/
    //
    // Otherwise, if it *DOES* exist, we'll try and guess what changes need to be made
    // self.alter(function(err) {
    //   if(err) return cb(err);
    //   cb();
    // });

  });
};






/**
 * uh oh.
 *
 * If we can't persist the data again, we'll log an error message, then
 * stream the data to stdout as JSON to make sure that it gets persisted
 * SOMEWHERE at least.
 *
 * (this is another reason this automigration strategy cannot be used in
 * production currently..)
 *
 * @param  {[type]}   err        [description]
 * @param  {[type]}   backupData [description]
 * @param  {Function} cb         [description]
 * @return {[type]}              [description]
 */

function uhoh (err, backupData, cb) {

  console.error('Waterline encountered a fatal error when trying to perform the `alter` auto-migration strategy.');
  console.error('In a couple of seconds, the data (cached in memory) will be logged to stdout.');
  console.error('(a failsafe put in place to preserve development data)');
  console.error();
  console.error('In the mean time, here\'s the error:');
  console.error();
  console.error(err);
  console.error();
  console.error();

  setTimeout(function () {
    console.error('================================');
    console.error('Data backup:');
    console.error('================================');
    console.error('');
    console.log(backupData);
    return cb(err);
  }, 1200);

}

},{"../../../utils/getRelations":69,"async":"async","lodash":"lodash"}],10:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash'),
  getRelations = require('../../../utils/getRelations');



/**
 * Drop and recreate collection
 *
 * @param  {Function} cb
 */

module.exports = function drop (cb) {
  var self = this;

  //
  // TODO:
  // Refuse to run this migration strategy in production.
  //

  // Find any junctionTables that reference this collection
  // var relations = getRelations({
  //   schema: self.query.waterline.schema,
  //   parentCollection: self.collection
  // });

  // Pass along relations to the drop method
  // console.log('Dropping ' + self.collection);
  this.drop(function afterDrop(err, data) {
    if (err) return cb(err);

    self.define(function () {
      cb.apply(null, Array.prototype.slice.call(arguments));
    });
  });
};

},{"../../../utils/getRelations":69,"lodash":"lodash"}],11:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');



/**
 * Do absolutely nothing to the schema of the underlying datastore.
 *
 * @param  {Function} cb
 */
module.exports = function(cb) {
  cb();
};

},{"lodash":"lodash"}],12:[function(require,module,exports){

/**
 * Default Collection properties
 * @type {Object}
 */
module.exports = {
	
	migrate: 'alter'
	
};
},{}],13:[function(require,module,exports){
/**
 * Dependencies
 */

var _ = require('lodash'),
    extend = require('../utils/extend'),
    inherits = require('util').inherits;

// Various Pieces
var Core = require('../core'),
    Query = require('../query');

/**
 * Collection
 *
 * A prototype for managing a collection of database
 * records.
 *
 * This file is the prototype for collections defined using Waterline.
 * It contains the entry point for all ORM methods (e.g. User.find())
 *
 * Methods in this file defer to the adapter for their true implementation:
 * the implementation here just validates and normalizes the parameters.
 *
 * @param {Object} waterline, reference to parent
 * @param {Object} options
 * @param {Function} callback
 */

var Collection = module.exports = function(waterline, connections, cb) {

  var self = this;

  // Set the named connections
  this.connections = connections || {};

  // Cache reference to the parent
  this.waterline = waterline;

  // Default Attributes
  this.attributes = this.attributes || {};

  // Instantiate Base Collection
  Core.call(this);

  // Instantiate Query Language
  Query.call(this);

  return this;
};

inherits(Collection, Core);
inherits(Collection, Query);

// Make Extendable
Collection.extend = extend;

},{"../core":17,"../query":55,"../utils/extend":68,"lodash":"lodash","util":"util"}],14:[function(require,module,exports){
/**
 * Module Dependencies
 */

var hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;

/**
 * Collection Loader
 *
 * @param {Object} connections
 * @param {Object} collection
 * @api public
 */

var CollectionLoader = module.exports = function(collection, connections, defaults) {

  this.defaults = defaults;

  // Normalize and validate the collection
  this.collection = this._validate(collection, connections);

  // Find the named connections used in the collection
  this.namedConnections = this._getConnections(collection, connections);

  return this;
};

/**
 * Initalize the collection
 *
 * @param {Object} context
 * @param {Function} callback
 * @api public
 */

CollectionLoader.prototype.initialize = function initialize(context) {
  return new this.collection(context, this.namedConnections);
};

/**
 * Validate Collection structure.
 *
 * @param {Object} collection
 * @param {Object} connections
 * @api private
 */

CollectionLoader.prototype._validate = function _validate(collection, connections) {

  // Throw Error if no Tablename/Identity is set
  if(!hasOwnProperty(collection.prototype, 'tableName') && !hasOwnProperty(collection.prototype, 'identity')) {
    throw new Error('A tableName or identity property must be set.');
  }

  // Ensure identity is lowercased
  collection.prototype.identity = collection.prototype.identity.toLowerCase();

  // Set the defaults
  collection.prototype.defaults = this.defaults;

  // Find the connections used by this collection
  // If none is specified check if a default connection exist
  if(!hasOwnProperty(collection.prototype, 'connection')) {

    // Check if a default connection was specified
    if(!hasOwnProperty(connections, 'default')) {
      throw new Error('No adapter was specified for collection: ' + collection.prototype.identity);
    }

    // Set the connection as the default
    collection.prototype.connection = 'default';
  }

  return collection;
};

/**
 * Get the named connections
 *
 * @param {Object} collection
 * @param {Object} connections
 * @api private
 */

CollectionLoader.prototype._getConnections = function _getConnections(collection, connections) {

  // Hold the used connections
  var usedConnections = {};

  // Normalize connection to array
  if(!Array.isArray(collection.prototype.connection)) {
    collection.prototype.connection = [collection.prototype.connection];
  }

  // Set the connections used for the adapter
  collection.prototype.connection.forEach(function(conn) {

    // Ensure the named connection exist
    if(!hasOwnProperty(connections, conn)) {
      var msg = 'The connection ' + conn + ' specified in ' + collection.prototype.identity + ' does not exists.';
      throw new Error(msg);
    }

    usedConnections[conn] = connections[conn];
  });

  return usedConnections;
};

},{"../utils/helpers":70}],15:[function(require,module,exports){
/**
 * Module Dependencies
 */
var _ = require('lodash'),
  util = require('util'),
  hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;

/**
 * Connections are active "connections" to a specific adapter for a specific configuration.
 * This allows you to have collections share named connections.
 *
 * @param {Object} adapters
 * @param {Object} objects
 * @api public
 */

var Connections = module.exports = function(adapters, options) {

  // Hold the active connections
  this._connections = {};

  // Build the connections
  this._build(adapters, options);

  return this._connections;
};


/**
 * Builds up a named connections object with a clone of the adapter
 * it will use for the connection.
 *
 * @param {Object} adapters
 * @param {Object} options
 * @api private
 */
Connections.prototype._build = function _build(adapters, options) {

  var self = this;

  // For each of the configured connections in options, find the required
  // adapter by name and build up an object that can be attached to the
  // internal connections object.
  Object.keys(options).forEach(function(key) {
    var config = options[key],
        msg,
        connection;

    // Ensure an adapter module is specified
    if(!hasOwnProperty(config, 'adapter')) {
      msg = util.format('Connection ("%s") is missing a required property (`adapter`).  You should indicate the name of one of your adapters.', key);
      throw new Error(msg);
    }

    // Ensure the adapter exists in the adapters options
    if(!hasOwnProperty(adapters, config.adapter)) {
      if (typeof config.adapter !== 'string') {
        msg = util.format('Invalid `adapter` property in connection `%s`.  It should be a string (the name of one of the adapters you passed into `waterline.initialize()`)', key);
      }
      else msg = util.format('Unknown adapter "%s" for connection `%s`.  You should double-check that the connection\'s `adapter` property matches the name of one of your adapters.  Or perhaps you forgot to include your "%s" adapter when you called `waterline.initialize()`...', config.adapter, key, config.adapter);
      throw new Error(msg);
    }

    // Build the connection config
    connection = {
      config: _.merge({}, adapters[config.adapter].defaults, config),
      _adapter: _.cloneDeep(adapters[config.adapter]),
      _collections: []
    };

    // Attach the connections to the connection library
    self._connections[key] = connection;
  });

};

},{"../utils/helpers":70,"lodash":"lodash","util":"util"}],16:[function(require,module,exports){
/**
 * Module Dependencies
 */

var _ = require('lodash');

/**
 * Handle Building an Adapter/Connection dictionary
 *
 * @param {Object} connections
 * @param {Array} ordered
 * @return {Object}
 * @api public
 */

var Dictionary = module.exports = function(connections, ordered) {

  // Build up a dictionary of methods for the collection's adapters and which connection
  // they will run on.
  this.dictionary = {};

  // Build the Dictionary
  this._build(connections);

  // Smash together Dictionary methods into a single level
  var dictionary = this._smash(ordered);

  return dictionary;
};

/**
 * Build Dictionary
 *
 * @param {Object} connections
 * @api private
 */

Dictionary.prototype._build = function _build(connections) {
  var self = this;

  Object.keys(connections).forEach(function(conn) {
    var connection = connections[conn];
    var methods = {};
    var adapter = connection._adapter || {};

    Object.keys(adapter).forEach(function(key) {
      methods[key] = conn;
    });

    self.dictionary[conn] = _.cloneDeep(methods);
  });

};

/**
 * Combine Dictionary into a single level object.
 *
 * Appends methods from other adapters onto the left most connection adapter.
 *
 * @param {Array} ordered
 * @return {Object}
 * @api private
 */

Dictionary.prototype._smash = function _smash(ordered) {
  var self = this;

  // Ensure Ordered is defined
  ordered = ordered || [];
  
  // Smash the methods together into a single layer object using the lodash merge
  // functionality.
  var adapter = {};

  // Reverse the order of connections so we will start at the end merging objects together
  ordered.reverse();

  ordered.forEach(function(adapterName) {
    adapter = _.merge(adapter, self.dictionary[adapterName]);
  });

  return adapter;
};

},{"lodash":"lodash"}],17:[function(require,module,exports){
/**
 * Dependencies
 */

var _ = require('lodash'),
    schemaUtils = require('../utils/schema'),
    COLLECTION_DEFAULTS = require('../collection/defaults'),
    Model = require('../model'),
    Cast = require('./typecast'),
    Schema = require('./schema'),
    Dictionary = require('./dictionary'),
    Validator = require('./validations'),
    Transformer = require('./transformations'),
    hasOwnProperty = require('../utils/helpers').object.hasOwnProperty;

/**
 * Core
 *
 * Setup the basic Core of a collection to extend.
 */

var Core = module.exports = function(options) {

  options = options || {};

  // Set Defaults
  this.adapter = this.adapter || {};
  this._attributes = _.clone(this.attributes);
  this.connections = this.connections || {};

  this.defaults = _.merge(COLLECTION_DEFAULTS, this.defaults);

  // Construct our internal objects
  this._cast = new Cast();
  this._schema = new Schema(this);
  this._validator = new Validator();

  // Normalize attributes, extract instance methods, and callbacks
  // Note: this is ordered for a reason!
  this._callbacks = schemaUtils.normalizeCallbacks(this);
  this._instanceMethods = schemaUtils.instanceMethods(this.attributes);
  this._attributes = schemaUtils.normalizeAttributes(this._attributes);

  this.hasSchema = Core._normalizeSchemaFlag.call(this);

  this.migrate = Object.getPrototypeOf(this).hasOwnProperty('migrate') ?
    this.migrate : this.defaults.migrate;

  // Initalize the internal values from the Collection
  Core._initialize.call(this, options);

  return this;
};

/**
 * Initialize
 *
 * Setups internal mappings from an extended collection.
 */

Core._initialize = function(options) {
  var self = this;

  options = options || {};

  // Extend a base Model with instance methods
  this._model = new Model(this, this._instanceMethods);

  // Cache the attributes from the schema builder
  var schemaAttributes = this.waterline.schema[this.identity].attributes;

  // Remove auto attributes for validations
  var _validations = _.clone(this._attributes);
  if(this.autoPK) delete _validations.id;
  if(this.autoCreatedAt) delete _validations.createdAt;
  if(this.autoUpdatedAt) delete _validations.updatedAt;

  // If adapter exposes any reserved attributes, pass them to the schema
  var connIdx = Array.isArray(this.connection) ? this.connection[0] : this.connection;

  var adapterInfo = {};
  if(this.connections[connIdx] && this.connections[connIdx]._adapter) {
    adapterInfo = this.connections[connIdx]._adapter;
  }

  var reservedAttributes = adapterInfo.reservedAttributes || {};

  // Initialize internal objects from attributes
  this._schema.initialize(this._attributes, this.hasSchema, reservedAttributes);
  this._cast.initialize(this._schema.schema);
  this._validator.initialize(_validations, this.types, this.defaults.validations);

  // Set the collection's primaryKey attribute
  Object.keys(schemaAttributes).forEach(function(key) {
    if(hasOwnProperty(schemaAttributes[key], 'primaryKey') && schemaAttributes[key].primaryKey) {
      self.primaryKey = key;
    }
  });

  // Build Data Transformer
  this._transformer = new Transformer(schemaAttributes, this.waterline.schema);

  // Transform Schema
  this._schema.schema = this._transformer.serialize(this._schema.schema);

  // Build up a dictionary of which methods run on which connection
  this.adapterDictionary = new Dictionary(_.cloneDeep(this.connections), this.connection);

  // Add this collection to the connection
  Object.keys(this.connections).forEach(function(conn) {
    self.connections[conn]._collections = self.connections[conn]._collections || [];
    self.connections[conn]._collections.push(self.identity);
  });

  // Remove remnants of user defined attributes
  delete this.attributes;
};

/**
 * Normalize Schema Flag
 *
 * Normalize schema setting by looking at the model first to see if it is defined, if not look at
 * the connection and see if it's defined and if not finally look into the adapter and check if
 * there is a default setting. If not found anywhere be safe and set to true.
 *
 * @api private
 * @return {Boolean}
 */

Core._normalizeSchemaFlag = function() {

  // If schema is defined on the collection, return the value
  if(hasOwnProperty(Object.getPrototypeOf(this), 'schema')) {
    return Object.getPrototypeOf(this).schema;
  }

  // Grab the first connection used
  if(!this.connection || !Array.isArray(this.connection)) return true;
  var connection = this.connections[this.connection[0]];

  // Check the user defined config
  if(hasOwnProperty(connection, 'config') && hasOwnProperty(connection.config, 'schema')) {
    return connection.config.schema;
  }

  // Check the defaults defined in the adapter
  if(!hasOwnProperty(connection, '_adapter')) return true;
  if(!hasOwnProperty(connection._adapter, 'schema')) return true;

  return connection._adapter.schema;
};

},{"../collection/defaults":12,"../model":26,"../utils/helpers":70,"../utils/schema":77,"./dictionary":16,"./schema":18,"./transformations":19,"./typecast":20,"./validations":21,"lodash":"lodash"}],18:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash'),
    types = require('../utils/types'),
    utils = require('../utils/helpers'),
    hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Builds a Schema Object from an attributes
 * object in a model.
 *
 * Loops through an attributes object to build a schema
 * containing attribute name as key and a type for casting
 * in the database. Also includes a default value if supplied.
 *
 * Example:
 *
 * attributes: {
 *   name: 'string',
 *   phone: {
 *     type: 'string',
 *     defaultsTo: '555-555-5555'
 *   }
 * }
 *
 * Returns: {
 *   name: { type: 'string' },
 *   phone: { type: 'string, defaultsTo: '555-555-5555' }
 * }
 *
 * @param {Object} context
 * @return {Object}
 */

var Schema = module.exports = function(context) {
  this.context = context || {};
  this.schema = {};

  return this;
};

/**
 * Initialize the internal schema object
 *
 * @param {Object} attrs
 * @param {Object} associations
 * @param {Boolean} hasSchema
 */

Schema.prototype.initialize = function(attrs, hasSchema, reservedAttributes) {
  var self = this;

  // Build normal attributes
  Object.keys(attrs).forEach(function(key) {
    if(hasOwnProperty(attrs[key], 'collection')) return;
    self.schema[key] = self.objectAttribute(key, attrs[key]);
  });

  // Build Reserved Attributes
  if(Array.isArray(reservedAttributes)) {
    reservedAttributes.forEach(function(key) {
      self.schema[key] = {};
    });
  }

  // Set hasSchema to determine if values should be cleansed or not
  this.hasSchema = typeof hasSchema !== 'undefined' ? hasSchema : true;
};

/**
 * Handle the building of an Object attribute
 *
 * Cleans any unnecessary attributes such as validation properties off of
 * the internal schema and set's defaults for incorrect values.
 *
 * @param {Object} value
 * @return {Object}
 */

Schema.prototype.objectAttribute = function(attrName, value) {
  var attr = {};

  for(var key in value) {
    switch(key) {

      // Set schema[attribute].type
      case 'type':
        // Allow validation types in attributes and transform them to strings
        attr.type = ~types.indexOf(value[key]) ? value[key] : 'string';
        break;

      // Set schema[attribute].defaultsTo
      case 'defaultsTo':
        attr.defaultsTo = value[key];
        break;

      // Set schema[attribute].primaryKey
      case 'primaryKey':
        attr.primaryKey = value[key];
        attr.unique = true;
        break;

      // Set schema[attribute].foreignKey
      case 'foreignKey':
        attr.foreignKey = value[key];
        break;

      // Set schema[attribute].references
      case 'references':
        attr.references = value[key];
        break;

      // Set schema[attribute].on
      case 'on':
        attr.on = value[key];
        break;

      // Set schema[attribute].via
      case 'via':
        attr.via = value[key];
        break;

      // Set schema[attribute].autoIncrement
      case 'autoIncrement':
        attr.autoIncrement = value[key];
        attr.type = 'integer';
        break;

      // Set schema[attribute].unique
      case 'unique':
        attr.unique = value[key];
        break;

      // Set schema[attribute].index
      case 'index':
        attr.index = value[key];
        break;

      // Set schema[attribute].enum
      case 'enum':
        attr.enum = value[key];
        break;

      // Set schema[attribute].size
      case 'size':
        attr.size = value[key];
        break;

      // Set schema[attribute].notNull
      case 'notNull':
        attr.notNull = value[key];
        break;

      // Handle Belongs To Attributes
      case 'model':
        var type;
        var attrs = this.context.waterline.schema[value[key].toLowerCase()].attributes;

        for(var attribute in attrs) {
          if(hasOwnProperty(attrs[attribute], 'primaryKey') && attrs[attribute].primaryKey) {
            type = attrs[attribute].type;
            break;
          }
        }

        attr.type = type.toLowerCase();
        attr.model = value[key].toLowerCase();
        attr.foreignKey = true;
        attr.alias = attrName;
        break;
    }
  }

  return attr;
};


/**
 * Clean Values
 *
 * Takes user inputted data and strips out any values not defined in
 * the schema.
 *
 * This is run after all the validations and right before being sent to the
 * adapter. This allows you to add temporary properties when doing validation
 * callbacks and have them stripped before being sent to the database.
 *
 * @param {Object} values to clean
 * @return {Object} clone of values, stripped of any extra properties
 */

Schema.prototype.cleanValues = function(values) {
  var clone = {};

  // Return if hasSchema === false
  if(!this.hasSchema) return values;

  for(var key in values) {
    if(hasOwnProperty(this.schema, key)) clone[key] = values[key];
  }

  return clone;
};

},{"../utils/helpers":70,"../utils/types":81,"lodash":"lodash"}],19:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash'),
    utils = require('../utils/helpers'),
    hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Transformation
 *
 * Allows for a Waterline Collection to have different
 * attributes than what actually exist in an adater's representation.
 *
 * @param {Object} attributes
 * @param {Object} tables
 */

var Transformation = module.exports = function(attributes, tables) {

  // Hold an internal mapping of keys to transform
  this._transformations = {};

  // Initialize
  this.initialize(attributes, tables);

  return this;
};

/**
 * Initial mapping of transformations.
 *
 * @param {Object} attributes
 * @param {Object} tables
 */

Transformation.prototype.initialize = function(attributes, tables) {
  var self = this;

  Object.keys(attributes).forEach(function(attr) {

    // Ignore Functions and Strings
    if(['function', 'string'].indexOf(typeof attributes[attr]) > -1) return;

    // If not an object, ignore
    if(attributes[attr] !== Object(attributes[attr])) return;

    // Loop through an attribute and check for transformation keys
    Object.keys(attributes[attr]).forEach(function(key) {

      // Currently just works with `columnName`, `collection`, `groupKey`
      if(key !== 'columnName') return;

      // Error if value is not a string
      if(typeof attributes[attr][key] !== 'string') {
        throw new Error('columnName transformation must be a string');
      }

      // Set transformation attr to new key
      if(key === 'columnName') {
        if(attr === attributes[attr][key]) return;
        self._transformations[attr] = attributes[attr][key];
      }

    });
  });
};

/**
 * Transforms a set of attributes into a representation used
 * in an adapter.
 *
 * @param {Object} attributes to transform
 * @return {Object}
 */

Transformation.prototype.serialize = function(attributes) {
  var self = this,
      values = _.clone(attributes);

  function recursiveParse(obj) {

    // Return if no object
    if(!obj) return;

    // Handle array of types for findOrCreateEach
    if(typeof obj === 'string') {
      if(hasOwnProperty(self._transformations, obj)) {
        values = self._transformations[obj];
        return;
      }

      return;
    }

    Object.keys(obj).forEach(function(property) {

      // Just a double check to exit if hasOwnProperty fails
      if(!hasOwnProperty(obj, property)) return;

      // Recursively parse `OR` criteria objects to transform keys
      if(Array.isArray(obj[property]) && property === 'or') return recursiveParse(obj[property]);

      // If Nested Object call function again passing the property as obj
      if((toString.call(obj[property]) !== '[object Date]') && (_.isPlainObject(obj[property]))) {

        // check if object key is in the transformations
        if(hasOwnProperty(self._transformations, property)) {
          obj[self._transformations[property]] = _.clone(obj[property]);
          delete obj[property];

          return recursiveParse(obj[self._transformations[property]]);
        }

        return recursiveParse(obj[property]);
      }

      // Check if property is a transformation key
      if(hasOwnProperty(self._transformations, property)) {

        obj[self._transformations[property]] = obj[property];
        delete obj[property];
      }
    });
  }

  // Recursivly parse attributes to handle nested criteria
  recursiveParse(values);

  return values;
};

/**
 * Transforms a set of attributes received from an adapter
 * into a representation used in a collection.
 *
 * @param {Object} attributes to transform
 * @return {Object}
 */

Transformation.prototype.unserialize = function(attributes) {
  var self = this,
      values = _.clone(attributes);

  // Loop through the attributes and change them
  Object.keys(this._transformations).forEach(function(key) {
    var transformed = self._transformations[key];

    if(!hasOwnProperty(attributes, transformed)) return;

    values[key] = attributes[transformed];
    if(transformed !== key) delete values[transformed];
  });

  return values;
};

},{"../utils/helpers":70,"lodash":"lodash"}],20:[function(require,module,exports){
/**
 * Module dependencies
 */

var types = require('../utils/types'),
    utils = require('../utils/helpers'),
    hasOwnProperty = utils.object.hasOwnProperty,
    _ = require('lodash');

/**
 * Cast Types
 *
 * Will take values and cast they to the correct type based on the
 * type defined in the schema.
 *
 * Especially handy for converting numbers passed as strings to the
 * correct integer type.
 *
 * Should be run before sending values to an adapter.
 */

var Cast = module.exports = function() {
  this._types = {};

  return this;
};

/**
 * Builds an internal _types object that contains each
 * attribute with it's type. This can later be used to
 * transform values into the correct type.
 *
 * @param {Object} attrs
 */

Cast.prototype.initialize = function(attrs) {
  var self = this;

  Object.keys(attrs).forEach(function(key) {
    self._types[key] = ~types.indexOf(attrs[key].type) ? attrs[key].type : 'string';
  });
};

/**
 * Converts a set of values into the proper types
 * based on the Collection's schema.
 *
 * @param {Object} values
 * @return {Object}
 * @api public
 */

Cast.prototype.run = function(values) {
  var self = this;

  Object.keys(values).forEach(function(key) {

    // Set undefined to null
    if(_.isUndefined(values[key])) values[key] = null;
    if(!hasOwnProperty(self._types, key) || values[key] === null || !hasOwnProperty(values, key)) {
      return;
    }

    // If the value is a plain object, don't attempt to cast it
    if(_.isPlainObject(values[key])) return;

    // Find the value's type
    var type = self._types[key];

    // Casting Function
    switch(type) {
      case 'string':
      case 'text':
        values[key] = self.string(values[key]);
        break;

      case 'integer':
        values[key] = self.integer(key, values[key]);
        break;

      case 'float':
        values[key] = self.float(values[key]);
        break;

      case 'date':
      case 'time':
      case 'datetime':
        values[key] = self.date(values[key]);
        break;

      case 'boolean':
        values[key] = self.boolean(values[key]);
        break;

      case 'array':
        values[key] = self.array(values[key]);
        break;
    }
  });

  return values;
};

/**
 * Cast String Values
 *
 * @param {String} str
 * @return {String}
 * @api private
 */

Cast.prototype.string = function string(str) {
  return typeof str.toString !== 'undefined' ? str.toString() : '' + str;
};

/**
 * Cast Integer Values
 *
 * @param {String} key
 * @param {Integer} value
 * @return {Integer}
 * @api private
 */

Cast.prototype.integer = function integer(key, value) {
  var _value;

  // Attempt to see if the value is resembles a MongoID
  // if so let's not try and cast it and instead return a string representation of
  // it. Needed for sails-mongo.
  if(utils.matchMongoId(value)) return value.toString();

  // Attempt to parseInt
  try {
    _value = parseInt(value, 10);
  } catch(e) {
    return value;
  }

  return _value;
};

/**
 * Cast Float Values
 *
 * @param {Float} value
 * @return {Float}
 * @api private
 */

Cast.prototype.float = function float(value) {
  var _value;

  try {
    _value = parseFloat(value);
  } catch(e) {
    return value;
  }

  return _value;
};

/**
 * Cast Boolean Values
 *
 * @param {Boolean} value
 * @return {Boolean}
 * @api private
 */

Cast.prototype.boolean = function boolean(value) {
  var parsed;

  if(_.isString(value)) {
    if(value === "true") return true;
    if(value === "false") return false;
    return false;
  }

  // Nicely cast [0, 1] to true and false
  try {
    parsed = parseInt(value, 10);
  } catch(e) {
    return false;
  }

  if(parsed === 0) return false;
  if(parsed === 1) return true;

  if(value === true || value === false) return value;

  return false;
};

/**
 * Cast Date Values
 *
 * @param {String|Date} value
 * @return {Date}
 * @api private
 */

Cast.prototype.date = function date(value) {
  var _value;
  if (value.__proto__ == Date.prototype) {
    _value = new Date(value.getTime());
  }
  else {
    _value = new Date(Date.parse(value));
  }

  if(_value.toString() === 'Invalid Date') return value;
  return _value;
};

/**
 * Cast Array Values
 *
 * @param {Array|String} value
 * @return {Array}
 * @api private
 */

Cast.prototype.array = function array(value) {
  if(Array.isArray(value)) return value;
  return [value];
};

},{"../utils/helpers":70,"../utils/types":81,"lodash":"lodash"}],21:[function(require,module,exports){
/**
 * Handles validation on a model
 *
 * Uses Anchor for validating
 * https://github.com/balderdashy/anchor
 */

var _ = require('lodash');
var anchor = require('anchor');
var async = require('async');
var utils = require('../utils/helpers');
var hasOwnProperty = utils.object.hasOwnProperty;
var WLValidationError = require('../error/WLValidationError');




/**
 * Build up validations using the Anchor module.
 *
 * @param {String} adapter
 */

var Validator = module.exports = function(adapter) {
  this.validations = {};
};

/**
 * Builds a Validation Object from a normalized attributes
 * object.
 *
 * Loops through an attributes object to build a validation object
 * containing attribute name as key and a series of validations that
 * are run on each model. Skips over type and defaultsTo as they are
 * schema properties.
 *
 * Example:
 *
 * attributes: {
 *   name: {
 *     type: 'string',
 *     length: { min: 2, max: 5 }
 *   }
 *   email: {
 *     type: 'string',
 *     required: true
 *   }
 * }
 *
 * Returns: {
 *   name: { length: { min:2, max: 5 }},
 *   email: { required: true }
 * }
 */

Validator.prototype.initialize = function(attrs, types, defaults) {
  var self = this;

  defaults = defaults || {};

  this.reservedProperties = ['defaultsTo', 'primaryKey', 'autoIncrement', 'unique', 'index', 'collection', 'dominant', 'through',
          'columnName', 'foreignKey', 'references', 'on', 'groupKey', 'model', 'via', 'size',
          'example', 'validationMessage', 'validations', 'populateSettings', 'onKey', 'protected'];


  if(defaults.ignoreProperties && Array.isArray(defaults.ignoreProperties)) {
    this.reservedProperties = this.reservedProperties.concat(defaults.ignoreProperties);
  }

  // add custom type definitions to anchor
  types = types || {};
  anchor.define(types);

  Object.keys(attrs).forEach(function(attr) {
    self.validations[attr] = {};

    Object.keys(attrs[attr]).forEach(function(prop) {

      // Ignore null values
      if(attrs[attr][prop] === null) return;

      // If property is reserved don't do anything with it
      if(self.reservedProperties.indexOf(prop) > -1) return;

      // use the Anchor `in` method for enums
      if(prop === 'enum') {
        self.validations[attr]['in'] = attrs[attr][prop];
        return;
      }

      self.validations[attr][prop] = attrs[attr][prop];
    });
  });
};

/**
 * Validate
 *
 * Accepts an object of values and runs them through the
 * schema's validations using Anchor.
 *
 * @param {Object} values to check
 * @param {Boolean} presentOnly only validate present values
 * @param {Function} callback
 * @return Array of errors
 */

Validator.prototype.validate = function(values, presentOnly, cb) {
  var self = this,
      errors = {},
      validations = Object.keys(this.validations);

  // Handle optional second arg
  if(typeof presentOnly === 'function') {
    cb = presentOnly;
  }
  // Use present values only or all validations
  else if(presentOnly) {
    validations = _.intersection(validations, Object.keys(values));
  }

  function validate(validation, cb) {
    var curValidation = self.validations[validation];

    // Build Requirements
    var requirements = anchor(curValidation);

    // Grab value and set to null if undefined
    var value = values[validation];
    if(typeof value == 'undefined') value = null;

    // If value is not required and empty then don't
    // try and validate it
    if(!curValidation.required) {
      if(value === null || value === '') return cb();
    }

    // if required is set to 'false', don't enforce as required rule
    if (curValidation.hasOwnProperty('required')&&!curValidation.required) {
        return cb();
    }

    // If Boolean and required manually check
    if(curValidation.required && curValidation.type === 'boolean' && (typeof value !== 'undefined' && value !== null)) {
      if(value.toString() == 'true' || value.toString() == 'false') return cb();
    }

    // If type is integer and the value matches a mongoID let it validate
    if(hasOwnProperty(self.validations[validation], 'type') && self.validations[validation].type === 'integer') {
      if(utils.matchMongoId(value)) return cb();
    }

    // Rule values may be specified as sync or async functions.
    // Call them and replace the rule value with the function's result
    // before running validations.
    async.each( Object.keys(requirements.data), function (key, cb) {
      if (typeof requirements.data[key] !== 'function') return cb();

      // Run synchronous function
      if (requirements.data[key].length < 1) {
        requirements.data[key] = requirements.data[key].apply(values, []);
        return cb();
      }

      // Run async function
      requirements.data[key].call(values, function (result) {
        requirements.data[key] = result;
        cb();
      });
    }, function() {

      // Validate with Anchor
      var err = anchor(value).to(requirements.data, values);

      // If No Error return
      if(!err) return cb();

      // Build an Error Object
      errors[validation] = [];

      err.forEach(function(obj) {
        if(obj.property) delete obj.property;
        errors[validation].push({ rule: obj.rule, message: obj.message });
      });

      return cb();
    });

  }

  // Validate all validations in parallel
  async.each(validations, validate, function allValidationsChecked () {
    if(Object.keys(errors).length === 0) return cb();

    cb(errors);
  });

};

},{"../error/WLValidationError":24,"../utils/helpers":70,"anchor":83,"async":"async","lodash":"lodash"}],22:[function(require,module,exports){
/**
 * Module dependencies
 */

var util = require('util');
var _ = require('lodash');



/**
 * WLError
 *
 * All errors passed to a query callback in Waterline extend
 * from this base error class.
 *
 * @param  {Object} properties
 * @constructor {WLError}
 */
function WLError( properties ) {

  // Call super constructor (Error)
  WLError.super_.call(this);

  // Fold defined properties into the new WLError instance.
  properties = properties||{};
  _.extend(this, properties);

  // Generate stack trace
  // (or use `originalError` if it is a true error instance)
  if (_.isObject(this.originalError) && this.originalError instanceof Error) {
    this._e = this.originalError;
  }
  else this._e = new Error();

  // Doctor up a modified version of the stack trace called `rawStack`:
  this.rawStack = (this._e.stack.replace(/^Error(\r|\n)*(\r|\n)*/, ''));


  // Customize `details`:
  // Try to dress up the wrapped "original" error as much as possible.
  // @type {String} a detailed explanation of this error
  if (typeof this.originalError === 'string') {
    this.details = this.originalError;
  }
  // Run toString() on Errors:
  else if ( this.originalError && util.isError(this.originalError) ) {
    this.details = this.originalError.toString();
  }
  // But for other objects, use util.inspect()
  else if (this.originalError) {
    this.details = util.inspect(this.originalError);
  }

  // If `details` is set, prepend it with "Details:"
  if (this.details) {
    this.details = 'Details:  '+this.details +'\n';
  }

}
util.inherits(WLError, Error);


// Default properties
WLError.prototype.status =
500;
WLError.prototype.code =
'E_UNKNOWN';
WLError.prototype.reason =
'Encountered an unexpected error';
WLError.prototype.details =
'';


/**
 * Override JSON serialization.
 * (i.e. when this error is passed to `res.json()` or `JSON.stringify`)
 *
 * For example:
 * ```json
 * {
 *   status: 500,
 *   code: 'E_UNKNOWN'
 * }
 * ```
 *
 * @return {Object}
 */
WLError.prototype.toJSON =
WLError.prototype.toPOJO =
function () {
  var obj = {
    error: this.code,
    status: this.status,
    summary: this.reason,
    raw: this.originalError
  };

  // Only include `raw` if its truthy.
  if (!obj.raw) delete obj.raw;

  return obj;
};



/**
 * Override output for `sails.log[.*]`
 *
 * @return {String}
 *
 * For example:
 * ```sh
 * Waterline: ORM encountered an unexpected error:
 * { ValidationError: { name: [ [Object], [Object] ] } }
 * ```
 */
WLError.prototype.toLog = function () {
  return this.inspect();
};


/**
 * Override output for `util.inspect`
 * (also when this error is logged using `console.log`)
 *
 * @return {String}
 */
WLError.prototype.inspect = function () {
  return util.format('Error (%s) :: %s\n%s\n\n%s', this.code, this.reason, this.rawStack, this.details);
};



/**
 * @return {String}
 */
WLError.prototype.toString = function () {
  return util.format('[Error (%s) %s]', this.code, this.reason, this.details);
};



module.exports = WLError;

},{"lodash":"lodash","util":"util"}],23:[function(require,module,exports){
/**
 * Module dependencies
 */

var WLError = require('./WLError');
var util = require('util');
var _ = require('lodash');



/**
 * WLUsageError
 *
 * @extends WLError
 */
function WLUsageError (properties) {

  // Call superclass
  WLUsageError.super_.call(this, properties);
}
util.inherits(WLUsageError, WLError);


// Override WLError defaults with WLUsageError properties.
WLUsageError.prototype.code =
'E_USAGE';
WLUsageError.prototype.status =
0;
WLUsageError.prototype.reason =
'Invalid usage';


module.exports = WLUsageError;

},{"./WLError":22,"lodash":"lodash","util":"util"}],24:[function(require,module,exports){
/**
 * Module dependencies
 */

var WLError = require('./WLError');
var WLUsageError = require('./WLUsageError');
var util = require('util');
var _ = require('lodash');



/**
 * WLValidationError
 *
 * @extends WLError
 */
function WLValidationError (properties) {

  // Call superclass
  WLValidationError.super_.call(this, properties);

  // Ensure valid usage
  if ( typeof this.invalidAttributes !== 'object' ) {
    return new WLUsageError({
      reason: 'An `invalidAttributes` object must be passed into the constructor for `WLValidationError`'
    });
  }
  // if ( typeof this.model !== 'string' ) {
  //   return new WLUsageError({
  //     reason: 'A `model` string (the collection\'s `globalId`) must be passed into the constructor for `WLValidationError`'
  //   });
  // }

  // Customize the `reason` based on the # of invalid attributes
  // (`reason` may not be overridden)
  var isSingular = this.length === 1;
  this.reason = util.format('%d attribute%s %s invalid',
    this.length,
    isSingular ? '' : 's',
    isSingular ? 'is' : 'are');

  // Always apply the 'E_VALIDATION' error code, even if it was overridden.
  this.code = 'E_VALIDATION';

  // Status may be overridden.
  this.status = properties.status || 400;

  // Model should always be set.
  // (this should be the globalId of model, or "collection")
  this.model = properties.model;

  // Ensure messages exist for each invalidAttribute
  this.invalidAttributes = _.mapValues(this.invalidAttributes, function (rules, attrName) {
    return _.map(rules, function (rule) {
      if (!rule.message) {
        rule.message = util.format('A record with that `%s` already exists (`%s`).', attrName, rule.value);
      }
      return rule;
    });
  });

  // Customize the `details`
  this.details = util.format('Invalid attributes sent to %s:\n',this.model) +
  _.reduce(this.messages, function (memo, messages, attrName) {
    memo += ' • ' + attrName + '\n';
    memo += _.reduce(messages, function (memo, message) {
      memo += '   • ' + message + '\n';
      return memo;
    }, '');
    return memo;
  }, '');

}
util.inherits(WLValidationError, WLError);


/**
 * `rules`
 *
 * @return {Object[Array[String]]} dictionary of validation rule ids, indexed by attribute
 */
WLValidationError.prototype.__defineGetter__('rules', function(){
  return _.mapValues(this.invalidAttributes, function (rules, attrName) {
    return _.pluck(rules, 'rule');
  });
});




/**
 * `messages` (aka `errors`)
 *
 * @return {Object[Array[String]]} dictionary of validation messages, indexed by attribute
 */
WLValidationError.prototype.__defineGetter__('messages', function(){
  return _.mapValues(this.invalidAttributes, function (rules, attrName) {
    return _.pluck(rules, 'message');
  });
});
WLValidationError.prototype.__defineGetter__('errors', function(){
  return this.messages;
});


/**
 * `attributes` (aka `keys`)
 *
 * @return {Array[String]} of invalid attribute names
 */
WLValidationError.prototype.__defineGetter__('attributes', function(){
  return _.keys(this.invalidAttributes);
});
WLValidationError.prototype.__defineGetter__('keys', function(){
  return this.attributes;
});


/**
 * `.length`
 *
 * @return {Integer} number of invalid attributes
 */
WLValidationError.prototype.__defineGetter__('length', function(){
  return this.attributes.length;
});



/**
 * `.ValidationError`
 * (backwards-compatibility)
 *
 * @return {Object[Array[Object]]} number of invalid attributes
 */
WLValidationError.prototype.__defineGetter__('ValidationError', function(){
  //
  // TODO:
  // Down the road- emit deprecation event here--
  // (will log information about new error handling options)
  //
  return this.invalidAttributes;
});



/**
 * [toJSON description]
 * @type {[type]}
 */
WLValidationError.prototype.toJSON =
WLValidationError.prototype.toPOJO =
function () {
  return {
    error: this.code,
    status: this.status,
    summary: this.reason,
    model: this.model,
    invalidAttributes: this.invalidAttributes
  };
};


module.exports = WLValidationError;

},{"./WLError":22,"./WLUsageError":23,"lodash":"lodash","util":"util"}],25:[function(require,module,exports){
/**
 * Module dependencies
 */

var util = require('util'),
  _ = require('lodash'),
  WLError = require('./WLError'),
  WLValidationError = require('./WLValidationError');


/**
 * A classifier which normalizes a mystery error into a simple,
 * consistent format.  This ensures that our instance which is
 * "new"-ed up belongs to one of a handful of distinct categories
 * and has a predictable method signature and properties.
 *
 * The returned error instance will always be or extend from
 * `WLError` (which extends from `Error`)
 *
 * NOTE:
 * This method should eventually be deprecated in a
 * future version of Waterline.  It exists to help
 * w/ error type negotiation.  In general, Waterline
 * should use WLError, or errors which extend from it
 * to construct error objects of the appropriate type.
 * In other words, no ** new ** errors should need to
 * be wrapped in a call to `errorify` - instead, code
 * necessary to handle any new error conditions should
 * construct a `WLError` directly and return that.
 *
 * @param  {???} err
 * @return {WLError}
 */
module.exports = function errorify(err) {

  // If specified `err` is already a WLError, just return it.
  if (typeof err === 'object' && err instanceof WLError) return err;

  return duckType(err);
};



/**
 * Determine which type of error we're working with.
 * Err... using hacks.
 *
 * @return {[type]} [description]
 */
function duckType(err) {

  // Validation or constraint violation error (`E_VALIDATION`)
  //
  // i.e. detected before talking to adapter, like `minLength`
  // i.e. constraint violation reported by adapter, like `unique`
  if (/*_isValidationError(err) || */_isConstraintViolation(err)) {

    // Dress `unique` rule violations to be consistent with other
    // validation errors.
    return new WLValidationError(err);
  }

  // Unexpected miscellaneous error  (`E_UNKNOWN`)
  //
  // (i.e. helmet fire. The database crashed or something. Or there's an adapter
  //  bug. Or a bug in WL core.)
  return new WLError({
    originalError: err
  });
}


/**
 * @param  {?} err
 * @return {Boolean} whether this is an adapter-level constraint
 * violation (e.g. `unique`)
 */
function _isConstraintViolation(err) {

  // If a proper error code is specified, this error can be classified.
  if (err && typeof err === 'object' && err.code === 'E_UNIQUE') {
    return true;
  }

  // Otherwise, there is not enough information to call this a
  // constraint violation error and provide proper explanation to
  // the architect.
  else return false;
}


// /**
//  * @param  {?} err
//  * @return {Boolean} whether this is a validation error (e.g. minLength exceeded for attribute)
//  */
// function _isValidationError(err) {
//   return _.isObject(err) && err.ValidationError;
// }


},{"./WLError":22,"./WLValidationError":24,"lodash":"lodash","util":"util"}],26:[function(require,module,exports){

/**
 * Module dependencies
 */

var _ = require('lodash');
var Bluebird = require('bluebird');
var Model = require('./lib/model');
var defaultMethods = require('./lib/defaultMethods');
var internalMethods = require('./lib/internalMethods');

/**
 * Build Extended Model Prototype
 *
 * @param {Object} context
 * @param {Object} mixins
 * @return {Object}
 * @api public
 */

module.exports = function(context, mixins) {

  /**
   * Extend the model prototype with default instance methods
   */

  var prototypeFns = {

    toObject: function() {
      return new defaultMethods.toObject(context, this);
    },

    save: function(cb) {
      return new defaultMethods.save(context, this, cb);
    },

    destroy: function(cb) {
      return new defaultMethods.destroy(context, this, cb);
    },

    _defineAssociations: function() {
      new internalMethods.defineAssociations(context, this);
    },

    _normalizeAssociations: function() {
      new internalMethods.normalizeAssociations(context, this);
    },

    _cast: function(values) {
      _.keys(context._attributes).forEach(function(key) {
        var type = context._attributes[key].type;

        // Attempt to parse Array or JSON type
        if(type === 'array' || type === 'json') {
          if(!_.isString(values[key])) return;
          try {
            values[key] = JSON.parse(values[key]);
          } catch(e) {
            return;
          }
        }

        // Convert booleans back to true/false
        if(type === 'boolean') {
          var val = values[key];
          if(val === 0) values[key] = false;
          if(val === 1) values[key] = true;
        }

      });
    },

    /**
     * Model.validate()
     *
     * Takes the currently set attributes and validates the model
     * Shorthand for Model.validate({ attributes }, cb)
     *
     * @param {Function} callback - (err)
     * @return {Promise}
     */

    validate: function(cb) {
      // Collect current values
      var values = this.toObject();

      if(cb) {
        context.validate(values, function(err) {
          if(err) return cb(err);
          cb();
        });
        return;
      }

      else {
        return new Bluebird(function (resolve, reject) {
          context.validate(values, function(err) {
            if(err) return reject(err);
            resolve();
          });
        });
      }
    }

  };

  // If any of the attributes are protected, the default toJSON method should
  // remove them.
  var protectedAttributes = _.compact(_.map(context._attributes, function(attr, key) {return attr.protected ? key : undefined;}));
  if (protectedAttributes.length) {
    prototypeFns.toJSON = function() {
      var obj = this.toObject();
      _.each(protectedAttributes, function(key) {
        delete obj[key];
      });
      return obj;
    };
  }
  // Otherwise just return the raw object
  else {
    prototypeFns.toJSON = function() {
      return this.toObject();
    };
  }

  var prototype = _.extend(prototypeFns, mixins);

  var model = Model.extend(prototype);

  // Return the extended model for use in Waterline
  return model;
};

},{"./lib/defaultMethods":32,"./lib/internalMethods":36,"./lib/model":38,"bluebird":"bluebird","lodash":"lodash"}],27:[function(require,module,exports){

/**
 * Handles an Association
 */

var Association = module.exports = function() {
  this.addModels = [];
  this.removeModels = [];
  this.value = [];
};

/**
 * Set Value
 *
 * @param {Number|Object} value
 * @api private
 */

Association.prototype._setValue = function(value) {
  if(Array.isArray(value)) {
    this.value = value;
    return;
  }

  this.value = this.value = [value];
};

/**
 * Get Value
 *
 * @api private
 */

Association.prototype._getValue = function() {
  var self = this,
      value = this.value;

  // Attach association methods to values array
  // This allows access using the getter and the desired
  // API for synchronously adding and removing associations.

  value.add = function add (obj) {
    self.addModels.push(obj);
  };

  value.remove = function remove (obj) {
    self.removeModels.push(obj);
  };

  return value;
};

},{}],28:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');
var async = require('async');
var utils = require('../../../utils/helpers');
var hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Add associations for a model.
 *
 * If an object was used a new record should be created and linked to the parent.
 * If only a primary key was used then the record should only be linked to the parent.
 *
 * Called in the model instance context.
 *
 * @param {Object} collection
 * @param {Object} proto
 * @param {Object} records
 * @param {Function} callback
 */

var Add = module.exports = function(collection, proto, records, cb) {

  this.collection = collection;
  this.proto = proto;
  this.failedTransactions = [];
  this.primaryKey = null;

  var values = proto.toObject();
  var attributes = collection.waterline.schema[collection.identity].attributes;

  this.primaryKey = this.findPrimaryKey(attributes, values);

  if(!this.primaryKey) return cb(new Error('No Primary Key set to associate the record with! ' +
      'Try setting an attribute as a primary key or include an ID property.'));

  if(!proto.toObject()[this.primaryKey]) return cb(new Error('No Primary Key set to associate the record with! ' +
      'Primary Key must have a value, it can\'t be an optional value.'));

  // Loop through each of the associations on this model and add any associations
  // that have been specified. Do this in series and limit the actual saves to 10
  // at a time so that connection pools are not exhausted.
  //
  // In the future when transactions are available this will all be done on a single
  // connection and can be re-written.

  this.createCollectionAssociations(records, cb);
};

/**
 * Find Primary Key
 *
 * @param {Object} attributes
 * @param {Object} values
 * @api private
 */

Add.prototype.findPrimaryKey = function(attributes, values) {
  var primaryKey = null;

  for(var attribute in attributes) {
    if(hasOwnProperty(attributes[attribute], 'primaryKey') && attributes[attribute].primaryKey) {
      primaryKey = attribute;
      break;
    }
  }

  // If no primary key check for an ID property
  if(!primaryKey && hasOwnProperty(values, 'id')) primaryKey = 'id';

  return primaryKey;
};

/**
 * Create Collection Associations
 *
 * @param {Object} records
 * @param {Function} callback
 * @api private
 */

Add.prototype.createCollectionAssociations = function(records, cb) {
  var self = this;

  async.eachSeries(Object.keys(records), function(associationKey, next) {
    self.createAssociations(associationKey, records[associationKey], next);
  },

  function(err) {
    if(err || self.failedTransactions.length > 0) {
      return cb(null, self.failedTransactions);
    }

    cb();
  });
};

/**
 * Create Records for an Association property on a collection
 *
 * @param {String} key
 * @param {Array} records
 * @param {Function} callback
 * @api private
 */

Add.prototype.createAssociations = function(key, records, cb) {
  var self = this;

  // Grab the collection the attribute references
  // this allows us to make a query on it
  var attribute = this.collection._attributes[key];
  var collectionName = attribute.collection.toLowerCase();
  var associatedCollection = this.collection.waterline.collections[collectionName];
  var schema = this.collection.waterline.schema[this.collection.identity].attributes[key];

  // Limit Adds to 10 at a time to prevent the connection pool from being exhausted
  async.eachLimit(records, 10, function(association, next) {

    // If an object was passed in it should be created.
    // This allows new records to be created through the association interface
    if(association !== null && typeof association === 'object' && Object.keys(association).length > 0) {

      // Check if the record contains a primary key, if so just link the values
      if(hasOwnProperty(association, associatedCollection.primaryKey)) {
        var pk = associatedCollection.primaryKey;
        return self.updateRecord(associatedCollection, schema, association[pk], next);
      }

      return self.createNewRecord(associatedCollection, schema, association, next);
    }

    // If the value is a primary key just update the association's foreign key
    // This will either create the new association through a foreign key or re-associatiate
    // with another collection.
    self.updateRecord(associatedCollection, schema, association, next);

  }, cb);
};

/**
 * Create A New Record
 *
 * @param {Object} collection
 * @param {Object} attribute
 * @param {Object} values
 * @param {Function} callback
 * @api private
 */

Add.prototype.createNewRecord = function(collection, attribute, values, cb) {
  var self = this;

  // Check if this is a many-to-many by looking at the junctionTable flag
  var schema = this.collection.waterline.schema[attribute.collection.toLowerCase()];
  var junctionTable = schema.junctionTable || false;

  // If this isn't a many-to-many then add the foreign key in to the values
  if(!junctionTable) {
    values[attribute.onKey] = this.proto[this.primaryKey];
  }

  collection.create(values, function(err, record) {
    if(err) {

      // If no via was specified and the insert failed on a one-to-many build up an error message that
      // properly reflects the error.
      if(!junctionTable && !hasOwnProperty(attribute, 'via')) {
        err = new Error('You attempted to create a has many relationship but didn\'t link the two ' +
          'atttributes together. Please setup a link using the via keyword.');
      }

      self.failedTransactions.push({
        type: 'insert',
        collection: collection.identity,
        values: values,
        err: err
      });
    }

    // if no junction table then return
    if(!junctionTable) return cb();

    // if junction table but there was an error don't try and link the records
    if(err) return cb();

    // Find the collection's Primary Key value
    var primaryKey = self.findPrimaryKey(collection._attributes, record.toObject());

    if(!primaryKey) {
      self.failedTransactions.push({
        type: 'insert',
        collection: collection.identity,
        values: {},
        err: new Error('No Primary Key value was found on the joined collection')
      });
    }

    // Find the Many To Many Collection
    var joinCollection = self.collection.waterline.collections[attribute.collection.toLowerCase()];

    // The related record was created now the record in the junction table
    // needs to be created to link the two records
    self.createManyToMany(joinCollection, attribute, record[primaryKey], cb);
  });
};

/**
 * Update A Record
 *
 * @param {Object} collection
 * @param {Object} attribute
 * @param {Object} values
 * @param {Function} callback
 * @api private
 */

Add.prototype.updateRecord = function(collection, attribute, values, cb) {
  var self = this;

  // Check if this is a many-to-many by looking at the junctionTable flag
  var schema = this.collection.waterline.schema[attribute.collection.toLowerCase()];
  var junctionTable = schema.junctionTable || false;

  // If so build out the criteria and create a new record in the junction table
  if(junctionTable) {
    var joinCollection = this.collection.waterline.collections[attribute.collection.toLowerCase()];
    return this.createManyToMany(joinCollection, attribute, values, cb);
  }

  // Grab the associated collection's primaryKey
  var attributes = this.collection.waterline.schema[collection.identity].attributes;
  var associationKey = this.findPrimaryKey(attributes, attributes);

  if(!associationKey) return cb(new Error('No Primary Key defined on the child record you ' +
    'are trying to associate the record with! Try setting an attribute as a primary key or ' +
    'include an ID property.'));

  // Build up criteria and updated values used to update the record
  var criteria = {};
  var _values = {};

  criteria[associationKey] = values;
  _values[attribute.onKey] = this.proto[this.primaryKey];

  collection.update(criteria, _values, function(err) {

    if(err) {
      self.failedTransactions.push({
        type: 'update',
        collection: collection.identity,
        criteria: criteria,
        values: _values,
        err: err
      });
    }

    cb();
  });
};

/**
 * Create A Many To Many Join Table Record
 *
 * @param {Object} collection
 * @param {Object} attribute
 * @param {Object} values
 * @param {Function} callback
 * @api private
 */

Add.prototype.createManyToMany = function(collection, attribute, pk, cb) {
  var self = this;

  // Grab the associated collection's primaryKey
  var collectionAttributes = this.collection.waterline.schema[attribute.collection.toLowerCase()];
  var associationKey = collectionAttributes.attributes[attribute.on].via;

  if(!associationKey) return cb(new Error('No Primary Key set on the child record you ' +
    'are trying to associate the record with! Try setting an attribute as a primary key or ' +
    'include an ID property.'));

  // Build up criteria and updated values used to create the record
  var criteria = {};
  var _values = {};

  criteria[associationKey] = pk;
  criteria[attribute.onKey] = this.proto[this.primaryKey];
  _values = _.clone(criteria);

  async.auto({

    validateAssociation: function(next) {
      var associatedCollectionName = collectionAttributes.attributes[associationKey].references;
      var associatedCollection = self.collection.waterline.collections[associatedCollectionName];
      var primaryKey = self.findPrimaryKey(associatedCollection.attributes, {});
      var _criteria = {};
      _criteria[primaryKey] = pk;

      associatedCollection.findOne(_criteria, function(err, record) {
        if(err) return next(err);
        if(!record) return next(new Error("Associated Record For " + associatedCollectionName +
          " with " + primaryKey + " = " + pk + " No Longer Exists"));

        next();
      });
    },

    validateRecord: function(next) {

      // First look up the record to ensure it doesn't exist
      collection.findOne(criteria, function(err, val) {
        if(err || val) {
          return next(new Error("Trying to '.add()' an instance which already exists!"));
        }
        next();
      });
    },

    createRecord: ['validateAssociation', 'validateRecord', function(next) {
      collection.create(_values, next);
    }]

  }, function(err) {
    if(err) {
      self.failedTransactions.push({
        type: 'insert',
        collection: collection.identity,
        criteria: criteria,
        values: _values,
        err: err
      });
    }

    return cb();

  });
};

/**
 * Find Association Key
 *
 * @param {Object} collection
 * @return {String}
 * @api private
 */

Add.prototype.findAssociationKey = function(collection) {
  var associationKey = null;

  for(var attribute in collection.attributes) {
    var attr = collection.attributes[attribute];
    var identity = this.collection.identity;

    if(!hasOwnProperty(attr, 'references')) continue;
    var attrCollection = attr.references;

    if(attrCollection !== identity) {
      associationKey = attr.columnName;
    }
  }

  return associationKey;
};

},{"../../../utils/helpers":70,"async":"async","lodash":"lodash"}],29:[function(require,module,exports){
var _ = require('lodash');
var async = require('async');
var utils = require('../../../utils/helpers');
var hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Remove associations from a model.
 *
 * Accepts a primary key value of an associated record that already exists in the database.
 *
 *
 * @param {Object} collection
 * @param {Object} proto
 * @param {Object} records
 * @param {Function} callback
 */

var Remove = module.exports = function(collection, proto, records, cb) {

  this.collection = collection;
  this.proto = proto;
  this.failedTransactions = [];
  this.primaryKey = null;

  var values = proto.toObject();
  var attributes = collection.waterline.schema[collection.identity].attributes;

  this.primaryKey = this.findPrimaryKey(attributes, values);

  if(!this.primaryKey) return cb(new Error('No Primary Key set to associate the record with! ' +
      'Try setting an attribute as a primary key or include an ID property.'));

  if(!proto.toObject()[this.primaryKey]) return cb(new Error('No Primary Key set to associate ' +
      'the record with! Primary Key must have a value, it can\'t be an optional value.'));

  // Loop through each of the associations on this model and remove any associations
  // that have been specified. Do this in series and limit the actual saves to 10
  // at a time so that connection pools are not exhausted.
  //
  // In the future when transactions are available this will all be done on a single
  // connection and can be re-written.
  this.removeCollectionAssociations(records, cb);
};

/**
 * Find Primary Key
 *
 * @param {Object} attributes
 * @param {Object} values
 * @api private
 */

Remove.prototype.findPrimaryKey = function(attributes, values) {
  var primaryKey = null;

  for(var attribute in attributes) {
    if(hasOwnProperty(attributes[attribute], 'primaryKey') && attributes[attribute].primaryKey) {
      primaryKey = attribute;
      break;
    }
  }

  // If no primary key check for an ID property
  if(!primaryKey && hasOwnProperty(values, 'id')) primaryKey = 'id';

  return primaryKey;
};

/**
 * Remove Collection Associations
 *
 * @param {Object} records
 * @param {Function} callback
 * @api private
 */

Remove.prototype.removeCollectionAssociations = function(records, cb) {
  var self = this;

  async.eachSeries(Object.keys(records), function(associationKey, next) {
    self.removeAssociations(associationKey, records[associationKey], next);
  },

  function(err) {
    if(err || self.failedTransactions.length > 0) {
      return cb(null, self.failedTransactions);
    }

    cb();
  });
};

/**
 * Remove Associations
 *
 * @param {String} key
 * @param {Array} records
 * @param {Function} callback
 * @api private
 */

Remove.prototype.removeAssociations = function(key, records, cb) {
  var self = this;

  // Grab the collection the attribute references
  // this allows us to make a query on it
  var attribute = this.collection._attributes[key];
  var collectionName = attribute.collection.toLowerCase();
  var associatedCollection = this.collection.waterline.collections[collectionName];
  var schema = this.collection.waterline.schema[this.collection.identity].attributes[key];

  // Limit Removes to 10 at a time to prevent the connection pool from being exhausted
  async.eachLimit(records, 10, function(association, next) {
    self.removeRecord(associatedCollection, schema, association, next);
  }, cb);

};

/**
 * Remove A Single Record
 *
 * @param {Object} collection
 * @param {Object} attribute
 * @param {Object} values
 * @param {Function} callback
 * @api private
 */

Remove.prototype.removeRecord = function(collection, attribute, values, cb) {
  var self = this;

  // Validate `values` is a correct primary key format
  var validAssociationKey = this.validatePrimaryKey(values);

  if(!validAssociationKey) {
    this.failedTransactions.push({
      type: 'remove',
      collection: collection.identity,
      values: values,
      err: new Error('Remove association only accepts a single primary key value')
    });

    return cb();
  }

  // Check if this is a many-to-many by looking at the junctionTable flag
  var schema = this.collection.waterline.schema[attribute.collection.toLowerCase()];
  var junctionTable = schema.junctionTable || false;

  // If so build out the criteria and remove a record from the junction table
  if(junctionTable) {
    var joinCollection = this.collection.waterline.collections[attribute.collection.toLowerCase()];
    return this.removeManyToMany(joinCollection, attribute, values, cb);
  }

  // Grab the associated collection's primaryKey
  var attributes = this.collection.waterline.schema[collection.identity].attributes;
  var associationKey = this.findPrimaryKey(attributes, attributes);

  if(!associationKey) return cb(new Error('No Primary Key defined on the child record you ' +
    'are trying to un-associate the record with! Try setting an attribute as a primary key or ' +
    'include an ID property.'));

  // Build up criteria and updated values used to update the record
  var criteria = {};
  var _values = {};

  criteria[associationKey] = values;
  _values[attribute.on] = null;

  collection.update(criteria, _values, function(err) {

    if(err) {
      self.failedTransactions.push({
        type: 'update',
        collection: collection.identity,
        criteria: criteria,
        values: _values,
        err: err
      });
    }

    cb();
  });
};

/**
 * Validate A Primary Key
 *
 * Only support primary keys being passed in to the remove function. Check if it's a mongo
 * id or anything that has a toString method.
 *
 * @param {Integer|String} key
 * @return {Boolean}
 * @api private
 */

Remove.prototype.validatePrimaryKey = function(key) {
  var validAssociation = false;

  // Attempt to see if the value is an ID and resembles a MongoID
  if(_.isString(key) && utils.matchMongoId(key)) validAssociation = true;

  // Check it can be turned into a string
  if(key.toString() !== '[object Object]') validAssociation = true;

  return validAssociation;
};

/**
 * Remove A Many To Many Join Table Record
 *
 * @param {Object} collection
 * @param {Object} attribute
 * @param {Object} values
 * @param {Function} callback
 * @api private
 */

Remove.prototype.removeManyToMany = function(collection, attribute, pk, cb) {
  var self = this;

  // Grab the associated collection's primaryKey
  var collectionAttributes = this.collection.waterline.schema[attribute.collection.toLowerCase()];
  var associationKey = collectionAttributes.attributes[attribute.on].via;

  if(!associationKey) return cb(new Error('No Primary Key set on the child record you ' +
    'are trying to associate the record with! Try setting an attribute as a primary key or ' +
    'include an ID property.'));

  // Build up criteria and updated values used to create the record
  var criteria = {};
  criteria[associationKey] = pk;
  criteria[attribute.on] = this.proto[this.primaryKey];

  // Run a destroy on the join table record
  collection.destroy(criteria, function(err) {

    if(err) {
      self.failedTransactions.push({
        type: 'destroy',
        collection: collection.identity,
        criteria: criteria,
        err: err
      });
    }

    cb();
  });
};

/**
 * Find Association Key
 *
 * @param {Object} collection
 * @return {String}
 * @api private
 */

Remove.prototype.findAssociationKey = function(collection) {
  var associationKey = null;

  for(var attribute in collection.attributes) {
    var attr = collection.attributes[attribute];
    var identity = this.collection.identity;

    if(!hasOwnProperty(attr, 'references')) continue;
    var attrCollection = attr.references.toLowerCase();

    if(attrCollection !== identity) {
      associationKey = attr.columnName;
    }
  }

  return associationKey;
};

},{"../../../utils/helpers":70,"async":"async","lodash":"lodash"}],30:[function(require,module,exports){

/**
 * Module dependencies
 */

var _ = require('lodash');
var utils = require('../../../utils/helpers');
var nestedOperations = require('../../../utils/nestedOperations');
var hop = utils.object.hasOwnProperty;

/**
 * Update the current instance with the currently set values
 *
 * Called in the model instance context.
 *
 * @param {Object} collection
 * @param {Object} proto
 * @param {Array} mutatedModels
 * @param {Function} callback
 */

var Update = module.exports = function(collection, proto, mutatedModels, cb) {

  var values = typeof proto.toObject === 'function' ? proto.toObject() : proto;
  var attributes = collection.waterline.schema[collection.identity].attributes;
  var primaryKey = this.findPrimaryKey(attributes, values);

  if(!primaryKey) return cb(new Error('No Primary Key set to update the record with! ' +
    'Try setting an attribute as a primary key or include an ID property.'));

  if(!values[primaryKey]) return cb(new Error('No Primary Key set to update the record with! ' +
    'Primary Key must have a value, it can\'t be an optional value.'));

  // Build Search Criteria
  var criteria = {};
  criteria[primaryKey] = values[primaryKey];

  // Clone values so they can be mutated
  var _values = _.cloneDeep(values);

  // For any nested model associations (objects not collection arrays) that were not changed,
  // lets set the value to just the foreign key so that an update query is not performed on the
  // associatied model.
  var keys = _.keys(_values);
  keys.forEach(function(key) {

    // If the key was changed, keep it expanded
    if(mutatedModels.indexOf(key) !== -1) return;

    // Reduce it down to a foreign key value
    var vals = {};
    vals[key] = _values[key];

    // Delete and replace the value with a reduced version
    delete _values[key];
    var reduced = nestedOperations.reduceAssociations(collection.identity, collection.waterline.schema, vals);
    _values = _.merge(_values, reduced);
  });

  // Update the collection with the new values
  collection.update(criteria, _values, cb);
};


/**
 * Find Primary Key
 *
 * @param {Object} attributes
 * @param {Object} values
 * @api private
 */

Update.prototype.findPrimaryKey = function(attributes, values) {
  var primaryKey = null;

  for(var attribute in attributes) {
    if(hop(attributes[attribute], 'primaryKey') && attributes[attribute].primaryKey) {
      primaryKey = attribute;
      break;
    }
  }

  // If no primary key check for an ID property
  if(!primaryKey && hop(values, 'id')) primaryKey = 'id';

  return primaryKey;
};

},{"../../../utils/helpers":70,"../../../utils/nestedOperations":72,"lodash":"lodash"}],31:[function(require,module,exports){

/**
 * Module dependencies
 */

var utils = require('../../../utils/helpers');
var hasOwnProperty = utils.object.hasOwnProperty;
var defer = require('../../../utils/defer');
var noop = function() {};

/**
 * Model.destroy()
 *
 * Destroys an instance of a model
 *
 * @param {Object} context,
 * @param {Object} proto
 * @param {Function} callback
 * @return {Promise}
 * @api public
 */

var Destroy = module.exports = function(context, proto, cb) {

  var deferred;
  var err;

  if(typeof cb !== 'function') {
    deferred = defer();
  }

  cb = cb || noop;

  var values = proto.toObject();
  var attributes = context.waterline.schema[context.identity].attributes;
  var primaryKey = this.findPrimaryKey(attributes, values);

  if(!primaryKey) {
    err = new Error('No Primary Key set to update the record with! ' +
    'Try setting an attribute as a primary key or include an ID property.');

    if(deferred) {
      deferred.reject(err);
    }

    return cb(err);
  }

  if(!values[primaryKey]) {
    err = new Error('No Primary Key set to update the record with! ' +
    'Primary Key must have a value, it can\'t be an optional value.');

    if(deferred) {
      deferred.reject(err);
    }

    return cb(err);
  }

  // Build Search Criteria
  var criteria = {};
  criteria[primaryKey] = values[primaryKey];

  // Execute Query
  context.destroy(criteria, function(err, status) {
    if (err) {

      if(deferred) {
        deferred.reject(err);
      }

      return cb(err);
    }

    if(deferred) {
      deferred.resolve(status);
    }

    cb.apply(this, arguments);
  });

  if(deferred) {
    return deferred.promise;
  }
};

/**
 * Find Primary Key
 *
 * @param {Object} attributes
 * @param {Object} values
 * @api private
 */

Destroy.prototype.findPrimaryKey = function(attributes, values) {
  var primaryKey = null;

  for(var attribute in attributes) {
    if(hasOwnProperty(attributes[attribute], 'primaryKey') && attributes[attribute].primaryKey) {
      primaryKey = attribute;
      break;
    }
  }

  // If no primary key check for an ID property
  if(!primaryKey && hasOwnProperty(values, 'id')) primaryKey = 'id';

  return primaryKey;
};

},{"../../../utils/defer":67,"../../../utils/helpers":70}],32:[function(require,module,exports){

/**
 * Export Default Methods
 */

module.exports = {
  toObject: require('./toObject'),
  destroy: require('./destroy'),
  save: require('./save')
};

},{"./destroy":31,"./save":33,"./toObject":34}],33:[function(require,module,exports){
var _ = require('lodash');
var async = require('async');
var deep = require('deep-diff');
var updateInstance = require('../associationMethods/update');
var addAssociation = require('../associationMethods/add');
var removeAssociation = require('../associationMethods/remove');
var hop = require('../../../utils/helpers').object.hasOwnProperty;
var defer = require('../../../utils/defer');
var noop = function() {};

/**
 * Model.save()
 *
 * Takes the currently set attributes and updates the database.
 * Shorthand for Model.update({ attributes }, cb)
 *
 * @param {Object} context
 * @param {Object} proto
 * @param {Function} callback
 * @return {Promise}
 * @api public
 */

module.exports = function(context, proto, cb) {

  var deferred;

  if(typeof cb !== 'function') {
    deferred = defer();
  }

  cb = cb || noop;

  /**
   * TO-DO:
   * This should all be wrapped in a transaction. That's coming next but for the meantime
   * just hope we don't get in a nasty state where the operation fails!
   */

  var mutatedModels = [];

  async.auto({

    // Compare any populated model values to their current state.
    // If they have been mutated then the values will need to be synced.
    compareModelValues: function(next) {
      var modelKeys = Object.keys(proto.associationsCache);

      async.each(modelKeys, function(key, nextKey) {

        if(!hop(proto, key) || proto[key] === undefined) return nextKey();

        var currentVal = proto[key];
        var previousVal = proto.associationsCache[key];

        // Normalize previousVal to an object
        if(Array.isArray(previousVal)) previousVal = previousVal[0];

        if(deep(currentVal, previousVal)) {
          mutatedModels.push(key);
        }

        nextKey();
      }, next);
    },

    // Update The Current Record
    updateRecord: ['compareModelValues', function(next) {

      // Shallow clone proto.toObject() to remove all the functions
      var data = _.clone(proto.toObject());

      new updateInstance(context, data, mutatedModels, function(err, data) {
        next(err, data);
      });
    }],


    // Build a set of associations to add and remove.
    // These are populated from using model[associationKey].add() and
    // model[associationKey].remove().
    buildAssociationOperations: ['compareModelValues', function(next) {

      // Build a dictionary to hold operations based on association key
      var operations = {
        addKeys: {},
        removeKeys: {}
      };

      Object.keys(proto.associations).forEach(function(key) {

        // Ignore belongsTo associations
        if(proto.associations[key].hasOwnProperty('model')) return;

        // Grab what records need adding
        if(proto.associations[key].addModels.length > 0) {
          operations.addKeys[key] = proto.associations[key].addModels;
        }

        // Grab what records need removing
        if(proto.associations[key].removeModels.length > 0) {
          operations.removeKeys[key] = proto.associations[key].removeModels;
        }
      });

      return next(null, operations);
    }],

    // Create new associations for each association key
    addAssociations: ['buildAssociationOperations', 'updateRecord', function(next, results) {
      var keys = results.buildAssociationOperations.addKeys;
      return new addAssociation(context, proto, keys, function(err, failedTransactions) {
        if(err) return next(err);

        // reset addKeys
        for(var key in results.buildAssociationOperations.addKeys) {
          proto.associations[key].addModels = [];
        }

        next(null, failedTransactions);
      });
    }],

    // Remove associations for each association key
    // Run after the addAssociations so that the connection pools don't get exhausted.
    // Once transactions are ready we can remove this restriction as they will be run on the same
    // connection.
    removeAssociations: ['buildAssociationOperations', 'addAssociations', function(next, results) {
      var keys = results.buildAssociationOperations.removeKeys;
      return new removeAssociation(context, proto, keys, function(err, failedTransactions) {
        if(err) return next(err);

        // reset removeKeys
        for(var key in results.buildAssociationOperations.removeKeys) {
          proto.associations[key].removeModels = [];
        }

        next(null, failedTransactions);
      });
    }]

  },

  function(err, results) {
    if(err) {
      if(deferred) {
        deferred.reject(err);
      }
      return cb(err);
    }

    // Collect all failed transactions if any
    var failedTransactions = [];

    if(results.addAssociations) {
      failedTransactions = failedTransactions.concat(results.addAssociations);
    }

    if(results.removeAssociations) {
      failedTransactions = failedTransactions.concat(results.removeAssociations);
    }

    if(failedTransactions.length > 0) {
      if(deferred) {
        deferred.reject(failedTransactions);
      }
      return cb(failedTransactions);
    }

    // Rebuild proper criteria object from the original query
    var PK = context.primaryKey;

    if(!results.updateRecord.length) {
      var error = new Error('Error updating a record.');
      if(deferred) {
        deferred.reject(error);
      }
      return cb(error);
    }

    var obj = results.updateRecord[0].toObject();
    var populations = Object.keys(proto.associations);
    var criteria = {};
    criteria[PK] = obj[PK];

    // Build up a new query and re-populate everything
    var query = context.findOne(criteria);
    populations.forEach(function(pop) {
      query.populate(pop);
    });

    query.exec(function(err, data) {
      if(err) {
        if(deferred) {
          deferred.reject(err);
        }
        return cb(err);
      }

      if(deferred) {
        deferred.resolve(data);
      }

      cb(null, data);
    });
  });

  if(deferred) {
    return deferred.promise;
  }
};

},{"../../../utils/defer":67,"../../../utils/helpers":70,"../associationMethods/add":28,"../associationMethods/remove":29,"../associationMethods/update":30,"async":"async","deep-diff":90,"lodash":"lodash"}],34:[function(require,module,exports){

/**
 * Module dependencies
 */

var _ = require('lodash');
var utils = require('../../../utils/helpers');
var hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Model.toObject()
 *
 * Returns a cloned object containing just the model
 * values. Useful for doing operations on the current values
 * minus the instance methods.
 *
 * @param {Object} context, Waterline collection instance
 * @param {Object} proto, model prototype
 * @api public
 * @return {Object}
 */

var toObject = module.exports = function(context, proto) {

  this.context = context;
  this.proto = proto;

  // Hold joins used in the query
  this.usedJoins = [];

  this.object = Object.create(proto.__proto__);

  this.addAssociations();
  this.addProperties();
  this.makeObject();
  this.filterJoins();
  this.filterFunctions();

  return this.object;
};


/**
 * Add Association Keys
 *
 * If a showJoins flag is active, add all association keys.
 *
 * @param {Object} keys
 * @api private
 */

toObject.prototype.addAssociations = function() {
  var self = this;

  if(!this.proto._properties) return;
  if(!this.proto._properties.showJoins) return;

  // Copy prototype over for attributes
  for(var association in this.proto.associations) {

    // Handle hasMany attributes
    if(hasOwnProperty(this.proto.associations[association], 'value')) {

      var records = [];
      var values = this.proto.associations[association].value;

      values.forEach(function(record) {
        if(typeof record !== 'object') return;
        // Since `typeof null` === `"object"`, we should also check for that case:
        if (record === null) return;
        var item = Object.create(record.__proto__);
        Object.keys(record).forEach(function(key) {
          item[key] = _.cloneDeep(record[key]);
        });
        records.push(item);
      });

      this.object[association] = records;
      continue;
    }

    // Handle belongsTo attributes
    var record = this.proto[association];

    // _.isObject() does not match null, so we're good here.
    if(_.isObject(record) && !Array.isArray(record)) {

      var item = Object.create(record.__proto__);

      Object.keys(record).forEach(function(key) {
        item[key] = _.cloneDeep(record[key]);
      });

      this.object[association] = item;
    } else if (!_.isUndefined(record)) {
      this.object[association] = record;
    }
  }
};

/**
 * Add Properties
 *
 * Copies over non-association attributes to the newly created object.
 *
 * @api private
 */

toObject.prototype.addProperties = function() {
  var self = this;

  Object.keys(this.proto).forEach(function(key) {
    if(hasOwnProperty(self.object, key)) return;
    self.object[key] = _.cloneDeep(self.proto[key]);
  });

};

/**
 * Make Object
 *
 * Runs toJSON on all associated values
 *
 * @api private
 */

toObject.prototype.makeObject = function() {
  var self = this;

  if(!this.proto._properties) return;
  if(!this.proto._properties.showJoins) return;

  // Handle Joins
  Object.keys(this.proto.associations).forEach(function(association) {

    // Don't run toJSON on records that were not populated
    if(!self.proto._properties || !self.proto._properties.joins) return;

    // Build up a join key name based on the attribute's model/collection name
    var joinsName = association;
    if(self.context._attributes[association].model) joinsName = self.context._attributes[association].model.toLowerCase();
    if(self.context._attributes[association].collection) joinsName = self.context._attributes[association].collection.toLowerCase();

    // Check if the join was used
    if(self.proto._properties.joins.indexOf(joinsName) < 0 && self.proto._properties.joins.indexOf(association) < 0) return;
    self.usedJoins.push(association);

    // Call toJSON on each associated record
    if(Array.isArray(self.object[association])) {
      var records = [];

      self.object[association].forEach(function(item) {
        if(!hasOwnProperty(item.__proto__, 'toJSON')) return;
        records.push(item.toJSON());
      });

      self.object[association] = records;
      return;
    }

    if(!self.object[association]) return;

    // Association was null or not valid
    // (don't try to `hasOwnProperty` it so we don't throw)
    if (typeof self.object[association] !== 'object') {
      self.object[association] = self.object[association];
      return;
    }

    if(!hasOwnProperty(self.object[association].__proto__, 'toJSON')) return;
    self.object[association] = self.object[association].toJSON();
  });

};

/**
 * Remove Non-Joined Associations
 *
 * @api private
 */

toObject.prototype.filterJoins = function() {
  var attributes = this.context._attributes;
  var properties = this.proto._properties;

  for(var attribute in attributes) {
    if(!hasOwnProperty(attributes[attribute], 'model') && !hasOwnProperty(attributes[attribute], 'collection')) continue;

    // If no properties and a collection attribute, delete the association and return
    if(!properties && hasOwnProperty(attributes[attribute], 'collection')) {
      delete this.object[attribute];
      continue;
    }

    // If showJoins is false remove the association object
    if(properties && !properties.showJoins) {

      // Don't delete belongs to keys
      if(!attributes[attribute].model) delete this.object[attribute];
    }

    if(properties && properties.joins) {
      if(this.usedJoins.indexOf(attribute) < 0) {

        // Don't delete belongs to keys
        if(!attributes[attribute].model) delete this.object[attribute];
      }
    }
  }
};

/**
 * Filter Functions
 *
 * @api private
 */

toObject.prototype.filterFunctions = function() {
  for(var key in this.object) {
    if(typeof this.object[key] === 'function') {
      delete this.object[key];
    }
  }
};

},{"../../../utils/helpers":70,"lodash":"lodash"}],35:[function(require,module,exports){

/**
 * Module dependencies
 */

var _ = require('lodash');
var Association = require('../association');
var utils = require('../../../utils/helpers');
var hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Add association getters and setters for any has_many
 * attributes.
 *
 * @param {Object} context
 * @param {Object} proto
 * @api private
 */

var Define = module.exports = function(context, proto) {
  var self = this;

  this.proto = proto;

  // Build Associations Listing
  Object.defineProperty(proto, 'associations', {
    enumerable: false,
    writable: true,
    value: {}
  });

  // Build associations cache to hold original values.
  // Used to check if values have been mutated and need to be synced when
  // a model.save call is made.
  Object.defineProperty(proto, 'associationsCache', {
    enumerable: false,
    writable: true,
    value: {}
  });

  var attributes = _.cloneDeep(context._attributes) || {};
  var collections = this.collectionKeys(attributes);
  var models = this.modelKeys(attributes);

  if(collections.length === 0 && models.length === 0) return;

  // Create an Association getter and setter for each collection
  collections.forEach(function(collection) {
    self.buildHasManyProperty(collection);
  });

  // Attach Models to the prototype and set in the associations object
  models.forEach(function(model) {
    self.buildBelongsToProperty(model);
  });
};

/**
 * Find Collection Keys
 *
 * @param {Object} attributes
 * @api private
 * @return {Array}
 */

Define.prototype.collectionKeys = function(attributes) {
  var collections = [];

  // Find any collection keys
  for(var attribute in attributes) {
    if(!hasOwnProperty(attributes[attribute], 'collection')) continue;
    collections.push(attribute);
  }

  return collections;
};

/**
 * Find Model Keys
 *
 * @param {Object} attributes
 * @api private
 * @return {Array}
 */

Define.prototype.modelKeys = function(attributes) {
  var models = [];

  // Find any collection keys
  for(var attribute in attributes) {
    if(!hasOwnProperty(attributes[attribute], 'model')) continue;
    models.push({ key: attribute, val: attributes[attribute] });
  }

  return models;
};

/**
 * Create Getter/Setter for hasMany associations
 *
 * @param {String} collection
 * @api private
 */

Define.prototype.buildHasManyProperty = function(collection) {
  var self = this;

  // Attach to a non-enumerable property
  this.proto.associations[collection] = new Association();

  // Attach getter and setter to the model
  Object.defineProperty(this.proto, collection, {
    set: function(val) { self.proto.associations[collection]._setValue(val); },
    get: function() { return self.proto.associations[collection]._getValue(); },
    enumerable: true,
    configurable: true
  });
};

/**
 * Add belongsTo attributes to associations object
 *
 * @param {String} collection
 * @api private
 */

Define.prototype.buildBelongsToProperty = function(model) {

  // Attach to a non-enumerable property
  this.proto.associations[model.key] = model.val;

  // Build a cache for this model
  this.proto.associationsCache[model.key] = {};
};

},{"../../../utils/helpers":70,"../association":27,"lodash":"lodash"}],36:[function(require,module,exports){

/**
 * Export Internal Methods
 */

module.exports = {
  normalizeAssociations: require('./normalizeAssociations'),
  defineAssociations: require('./defineAssociations')
};

},{"./defineAssociations":35,"./normalizeAssociations":37}],37:[function(require,module,exports){

/**
 * Check and normalize belongs_to and has_many association keys
 *
 * Ensures that a belongs_to association is an object and that a has_many association
 * is an array.
 *
 * @param {Object} context,
 * @param {Object} proto
 * @api private
 */

var Normalize = module.exports = function(context, proto) {

  this.proto = proto;

  var attributes = context.waterline.collections[context.identity].attributes || {};

  this.collections(attributes);
  this.models(attributes);
};

/**
 * Normalize Collection Attribute to Array
 *
 * @param {Object} attributes
 * @api private
 */

Normalize.prototype.collections = function(attributes) {
  for(var attribute in attributes) {

    // If attribute is not a collection, it doesn't need normalizing
    if(!attributes[attribute].collection) continue;

    // Sets the attribute as an array if it's not already
    if(this.proto[attribute] && !Array.isArray(this.proto[attribute])) {
      this.proto[attribute] = [this.proto[attribute]];
    }
  }
};

/**
 * Normalize Model Attribute to Object
 *
 * @param {Object} attributes
 * @api private
 */

Normalize.prototype.models = function(attributes) {
  for(var attribute in attributes) {

    // If attribute is not a model, it doesn't need normalizing
    if(!attributes[attribute].model) continue;

    // Sets the attribute to the first item in the array if it's an array
    if(this.proto[attribute] && Array.isArray(this.proto[attribute])) {
      this.proto[attribute] = this.proto[attribute][0];
    }
  }
};

},{}],38:[function(require,module,exports){

/**
 * Dependencies
 */

var extend = require('../../utils/extend');
var _ = require('lodash');
var util = require('util');

/**
 * A Basic Model Interface
 *
 * Initialize a new Model with given params
 *
 * @param {Object} attrs
 * @param {Object} options
 * @return {Object}
 * @api public
 *
 * var Person = Model.prototype;
 * var person = new Person({ name: 'Foo Bar' });
 * person.name # => 'Foo Bar'
 */

var Model = module.exports = function(attrs, options) {
  var self = this;

  attrs = attrs || {};
  options = options || {};

  // Store options as properties
  Object.defineProperty(this, '_properties', {
    enumerable: false,
    writable: false,
    value: options
  });

  // Cast things that need to be cast
  this._cast(attrs);

  // Build association getters and setters
  this._defineAssociations();

  // Attach attributes to the model instance
  for(var key in attrs) {
    this[key] = attrs[key];

    if(this.associationsCache.hasOwnProperty(key)) {
      this.associationsCache[key] = _.cloneDeep(attrs[key]);
    }
  }

  // Normalize associations
  this._normalizeAssociations();


  /**
   * Log output
   * @return {String} output when this model is util.inspect()ed
   * (usually with console.log())
   */
  this.inspect = function() {
    var output;
    try {
      output = self.toObject();
    }
    catch (e) {}

    return output ? util.inspect(output) : self;
  };


  return this;
};

// Make Extendable
Model.extend = extend;

},{"../../utils/extend":68,"lodash":"lodash","util":"util"}],39:[function(require,module,exports){
/**
 * Mixes Custom Non-CRUD Adapter Methods into the prototype.
 */

module.exports = function() {
  var self = this;

  Object.keys(this.connections).forEach(function(conn) {

    var adapter = self.connections[conn]._adapter || {};

    Object.keys(adapter).forEach(function(key) {

      // Ignore the Identity Property
      if(['identity', 'tableName'].indexOf(key) >= 0) return;

      // Don't override keys that already exists
      if(self[key]) return;

      // Don't override a property, only functions
      if(typeof adapter[key] != 'function')  {
				self[key] = adapter[key];
				return;
			}

      // Apply the Function with passed in args and set this.identity as
      // the first argument
      self[key] = function() {

        var tableName = self.tableName || self.identity;

        // Concat self.identity with args (must massage arguments into a proper array)
        // Use a normalized _tableName set in the core module.
        var args = [conn, tableName].concat(Array.prototype.slice.call(arguments));
        adapter[key].apply(self, args);
      };
    });
  });

};

},{}],40:[function(require,module,exports){
/**
 * Aggregate Queries
 */

var async = require('async'),
    _ = require('lodash'),
    usageError = require('../utils/usageError'),
    utils = require('../utils/helpers'),
    normalize = require('../utils/normalize'),
    callbacks = require('../utils/callbacksRunner'),
    Deferred = require('./deferred'),
    hasOwnProperty = utils.object.hasOwnProperty;

module.exports = {

  /**
   * Create an Array of records
   *
   * @param {Array} array of values to create
   * @param {Function} callback
   * @return Deferred object if no callback
   */

  createEach: function(valuesList, cb) {
    var self = this;

    // Handle Deferred where it passes criteria first
    if(arguments.length === 3) {
      var args = Array.prototype.slice.call(arguments);
      cb = args.pop();
      valuesList = args.pop();
    }

    // Return Deferred or pass to adapter
    if(typeof cb !== 'function') {
      return new Deferred(this, this.createEach, {}, valuesList);
    }

    // Validate Params
    var usage = utils.capitalize(this.identity) + '.createEach(valuesList, callback)';

    if(!valuesList) return usageError('No valuesList specified!', usage, cb);
    if(!Array.isArray(valuesList)) return usageError('Invalid valuesList specified (should be an array!)', usage, cb);
    if(typeof cb !== 'function') return usageError('Invalid callback specified!', usage, cb);

    // Remove all undefined values
    valuesList = _.remove(valuesList, undefined);

    var errStr = _validateValues(_.cloneDeep(valuesList));
    if(errStr) return usageError(errStr, usage, cb);

    var records = [];

    function create(value, next) {
      self.create(value, function(err, record) {
        if(err) return next(err);
        records.push(record);
        next();
      });
    }

    async.each(valuesList, create, function(err) {
      if(err) return cb(err);
      cb(null, records);
    });
  },

  /**
   * Iterate through a list of objects, trying to find each one
   * For any that don't exist, create them
   *
   * @param {Object} criteria
   * @param {Array} valuesList
   * @param {Function} callback
   * @return Deferred object if no callback
   */

  findOrCreateEach: function(criteria, valuesList, cb) {
    var self = this;

    if(typeof valuesList === 'function') {
      cb = valuesList;
      valuesList = null;
    }

    // Normalize criteria
    criteria = normalize.criteria(criteria);

    // Return Deferred or pass to adapter
    if(typeof cb !== 'function') {
      return new Deferred(this, this.findOrCreateEach, criteria, valuesList);
    }

    // Validate Params
    var usage = utils.capitalize(this.identity) + '.findOrCreateEach(criteria, valuesList, callback)';

    if(typeof cb !== 'function') return usageError('Invalid callback specified!', usage, cb);
    if(!criteria) return usageError('No criteria specified!', usage, cb);
    if(!Array.isArray(criteria)) return usageError('No criteria specified!', usage, cb);
    if(!valuesList) return usageError('No valuesList specified!', usage, cb);
    if(!Array.isArray(valuesList)) return usageError('Invalid valuesList specified (should be an array!)', usage, cb);

    var errStr = _validateValues(valuesList);
    if(errStr) return usageError(errStr, usage, cb);

    // Validate each record in the array and if all are valid
    // pass the array to the adapter's findOrCreateEach method
    var validateItem = function(item, next) {
      _validate.call(self, item, next);
    }


    async.each(valuesList, validateItem, function(err) {
      if(err) return cb(err);

      // Transform Values
      var transformedValues = [];

      valuesList.forEach(function(value) {

        // Transform values
        value = self._transformer.serialize(value);

        // Clean attributes
        value = self._schema.cleanValues(value);
        transformedValues.push(value);
      });

      // Set values array to the transformed array
      valuesList = transformedValues;

      // Transform Search Criteria
      var transformedCriteria = [];

      criteria.forEach(function(value) {
        value = self._transformer.serialize(value);
        transformedCriteria.push(value);
      });

      // Set criteria array to the transformed array
      criteria = transformedCriteria;

      // Pass criteria and attributes to adapter definition
      self.adapter.findOrCreateEach(criteria, valuesList, function(err, values) {
        if(err) return cb(err);

        // Unserialize Values
        var unserializedValues = [];

        values.forEach(function(value) {
          value = self._transformer.unserialize(value);
          unserializedValues.push(value);
        });

        // Set values array to the transformed array
        values = unserializedValues;

        // Run AfterCreate Callbacks
        async.each(values, function(item, next) {
          callbacks.afterCreate(self, item, next);
        }, function(err) {
          if(err) return cb(err);

          var models = [];

          // Make each result an instance of model
          values.forEach(function(value) {
            models.push(new self._model(value));
          });

          cb(null, models);
        });
      });
    });
  }
};


/**
 * Validate valuesList
 *
 * @param {Array} valuesList
 * @return {String}
 * @api private
 */

function _validateValues(valuesList) {
  var err;

  for(var i=0; i < valuesList.length; i++) {
    if(valuesList[i] !== Object(valuesList[i])) {
      err = 'Invalid valuesList specified (should be an array of valid values objects!)';
    }
  }

  return err;
}


/**
 * Validate values and add in default values
 *
 * @param {Object} record
 * @param {Function} cb
 * @api private
 */

function _validate(record, cb) {
  var self = this;

  // Set Default Values if available
  for(var key in self.attributes) {
    if(!record[key] && record[key] !== false && hasOwnProperty(self.attributes[key], 'defaultsTo')) {
      var defaultsTo = self.attributes[key].defaultsTo;
      record[key] = typeof defaultsTo === 'function' ? defaultsTo.call(record) : _.clone(defaultsTo);
    }
  }

  // Cast values to proper types (handle numbers as strings)
  record = self._cast.run(record);

  async.series([

    // Run Validation with Validation LifeCycle Callbacks
    function(next) {
      callbacks.validate(self, record, true, next);
    },

    // Before Create Lifecycle Callback
    function(next) {
      callbacks.beforeCreate(self, record, next);
    }

  ], function(err) {
    if(err) return cb(err);

    // Automatically add updatedAt and createdAt (if enabled)
    if (self.autoCreatedAt) record.createdAt = new Date();
    if (self.autoUpdatedAt) record.updatedAt = new Date();

    cb();
  });
}

},{"../utils/callbacksRunner":66,"../utils/helpers":70,"../utils/normalize":76,"../utils/usageError":82,"./deferred":43,"async":"async","lodash":"lodash"}],41:[function(require,module,exports){
/**
 * Composite Queries
 */

var async = require('async'),
    _ = require('lodash'),
    usageError = require('../utils/usageError'),
    utils = require('../utils/helpers'),
    normalize = require('../utils/normalize'),
    Deferred = require('./deferred'),
    hasOwnProperty = utils.object.hasOwnProperty;

module.exports = {

  /**
   * Find or Create a New Record
   *
   * @param {Object} search criteria
   * @param {Object} values to create if no record found
   * @param {Function} callback
   * @return Deferred object if no callback
   */

  findOrCreate: function(criteria, values, cb) {
    var self = this;

    if(typeof values === 'function') {
      cb = values;
      values = null;
    }

    // If no criteria is specified, bail out with a vengeance.
    var usage = utils.capitalize(this.identity) + '.findOrCreate([criteria], values, callback)';
    if(typeof cb == 'function' && !criteria) {
      return usageError('No criteria option specified!', usage, cb);
    }

    // Normalize criteria
    criteria = normalize.criteria(criteria);

    // Return Deferred or pass to adapter
    if(typeof cb !== 'function') {
      return new Deferred(this, this.findOrCreate, criteria, values);
    }

    // This is actually an implicit call to findOrCreateEach
    if(Array.isArray(criteria) && Array.isArray(values)) {
      return this.findOrCreateEach(criteria, values, cb);
    }

    if(typeof cb !== 'function') return usageError('Invalid callback specified!', usage, cb);

    // Try a find first.
    this.find(criteria).exec(function(err, results) {
      if (err) return cb(err);

      if (results && results.length !== 0) {

        // Unserialize values
        results = self._transformer.unserialize(results[0]);

        // Return an instance of Model
        var model = new self._model(results);
        return cb(null, model);
      }

      // Create a new record if nothing is found.
      self.create(values).exec(function(err, result) {
        if(err) return cb(err);
        return cb(null, result);
      });
    });
  }

};

},{"../utils/helpers":70,"../utils/normalize":76,"../utils/usageError":82,"./deferred":43,"async":"async","lodash":"lodash"}],42:[function(require,module,exports){
/**
 * DDL Queries
 */

module.exports = {

  /**
   * Describe a collection
   */

  describe: function(cb) {
    this.adapter.describe(cb);
  },

  /**
   * Alter a table/set/etc
   */

  alter: function(attributes, cb) {
    this.adapter.alter(attributes, cb);
  },

  /**
   * Drop a table/set/etc
   */

  drop: function(cb) {
    this.adapter.drop(cb);
  }

};

},{}],43:[function(require,module,exports){
/**
 * Deferred Object
 *
 * Used for building up a Query
 */

var util = require('util');
var Promise = require('bluebird'),
    _ = require('lodash'),
    normalize = require('../utils/normalize'),
    utils = require('../utils/helpers'),
    acyclicTraversal = require('../utils/acyclicTraversal'),
    hasOwnProperty = utils.object.hasOwnProperty;

// Alias "catch" as "fail", for backwards compatibility with projects
// that were created using Q
Promise.prototype.fail = Promise.prototype.catch;

var Deferred = module.exports = function(context, method, criteria, values) {

  if(!context) return new Error('Must supply a context to a new Deferred object. Usage: new Deferred(context, method, criteria)');
  if(!method) return new Error('Must supply a method to a new Deferred object. Usage: new Deferred(context, method, criteria)');

  this._context = context;
  this._method = method;
  this._criteria = criteria;
  this._values = values || null;

  this._deferred = null; // deferred object for promises

  return this;
};



/**
 * Add join clause(s) to the criteria object to populate
 * the specified alias all the way down (or at least until a
 * circular pattern is detected.)
 *
 * @param  {String} keyName  [the initial alias aka named relation]
 * @param  {Object} criteria [optional]
 * @return this
 * @chainable
 *
 * WARNING:
 * This method is not finished yet!!
 */
Deferred.prototype.populateDeep = function ( keyName, criteria ) {

  // The identity of the initial model
  var identity = this._context.identity;

  // The input schema
  var schema = this._context.waterline.schema;

  // Kick off recursive function to traverse the schema graph.
  var plan = acyclicTraversal(schema, identity, keyName);

  // TODO: convert populate plan into a join plan
  // this._criteria.joins = ....

  // TODO: also merge criteria object into query

  return this;
};

/**
 * Populate all associations of a collection.
 *
 * @return this
 * @chainable
 */
Deferred.prototype.populateAll = function(criteria) {
  var self = this;
  this._context.associations.forEach(function(association) {
    self.populate(association.alias, criteria);
  });
  return this;

};

/**
 * Add a `joins` clause to the criteria object.
 *
 * Used for populating associations.
 *
 * @param {String} key, the key to populate
 * @return this
 * @chainable
 */

Deferred.prototype.populate = function(keyName, criteria) {

  var self = this;
  var joins = [];
  var pk = 'id';
  var attr;
  var join;


  // Normalize sub-criteria
  try {
    criteria = normalize.criteria(criteria);

    ////////////////////////////////////////////////////////////////////////
    // TODO:
    // instead of doing this, target the relevant pieces of code
    // with weird expectations and teach them a lesson
    // e.g. `lib/waterline/query/finders/operations.js:665:12`
    // (delete userCriteria.sort)
    //
    // Except make sure `where` exists
    criteria.where = criteria.where===false?false:(criteria.where||{});
    ////////////////////////////////////////////////////////////////////////

  }
  catch (e) {
    throw new Error(
      'Could not parse sub-criteria passed to '+
      util.format('`.populate("%s")`', keyName)+
      '\nSub-criteria:\n'+ util.inspect(criteria, false, null)+
      '\nDetails:\n'+util.inspect(e,false, null)
    );
  }

  try {

    // Set the attr value to the generated schema attribute
    attr = this._context.waterline.schema[this._context.identity].attributes[keyName];

    // Get the current collection's primary key attribute
    Object.keys(this._context._attributes).forEach(function(key) {
      if(hasOwnProperty(self._context._attributes[key], 'primaryKey') && self._context._attributes[key].primaryKey) {
        pk = self._context._attributes[key].columnName || key;
      }
    });

    if(!attr) {
      throw new Error(
        'In '+util.format('`.populate("%s")`', keyName)+
        ', attempting to populate an attribute that doesn\'t exist'
      );
    }

    //////////////////////////////////////////////////////////////////////
    ///(there has been significant progress made towards both of these ///
    /// goals-- contact @mikermcneil if you want to help) ////////////////
    //////////////////////////////////////////////////////////////////////
    // TODO:
    // Create synonym for `.populate()` syntax using criteria object
    // syntax.  i.e. instead of using `joins` key in criteria object
    // at the app level.
    //////////////////////////////////////////////////////////////////////
    // TODO:
    // Support Mongoose-style `foo.bar.baz` syntax for nested `populate`s.
    // (or something comparable.)
    // One solution would be:
    // .populate({
    //   friends: {
    //     where: { name: 'mike' },
    //     populate: {
    //       dentist: {
    //         where: { name: 'rob' }
    //       }
    //     }
    //   }
    // }, optionalCriteria )
    ////////////////////////////////////////////////////////////////////


    // Grab the key being populated to check if it is a has many to belongs to
    // If it's a belongs_to the adapter needs to know that it should replace the foreign key
    // with the associated value.
    var parentKey = this._context.waterline.collections[this._context.identity].attributes[keyName];

    // Build the initial join object that will link this collection to either another collection
    // or to a junction table.
    join = {
      parent: this._context.identity,
      parentKey: attr.columnName || pk,
      child: attr.references,
      childKey: attr.on,
      select: Object.keys(this._context.waterline.schema[attr.references].attributes),
      alias: keyName,
      removeParentKey: parentKey.model ? true : false,
      model: hasOwnProperty(parentKey, 'model') ? true : false,
      collection: hasOwnProperty(parentKey, 'collection') ? true : false
    };

    // Build select object to use in the integrator
    var select = [];
    Object.keys(this._context.waterline.schema[attr.references].attributes).forEach(function(key) {
      var obj = self._context.waterline.schema[attr.references].attributes[key];
      if(!hasOwnProperty(obj, 'columnName')) {
        select.push(key);
        return;
      }

      select.push(obj.columnName);
    });

    join.select = select;

    // If linking to a junction table the attributes shouldn't be included in the return value
    if(this._context.waterline.schema[attr.references].junctionTable) join.select = false;

    joins.push(join);

    // If a junction table is used add an additional join to get the data
    if(this._context.waterline.schema[attr.references].junctionTable && hasOwnProperty(attr, 'on')) {

      // clone the reference attribute so we can mutate it
      var reference = _.clone(this._context.waterline.schema[attr.references].attributes);

      // Find the other key in the junction table
      Object.keys(reference).forEach(function(key) {
        var attribute = reference[key];

        if(!hasOwnProperty(attribute, 'references')) {
          delete reference[key];
          return;
        }

        if(hasOwnProperty(attribute, 'columnName') && attribute.columnName === attr.on) {
          delete reference[key];
          return;
        }

        if(hasOwnProperty(attribute, 'columnName') && attribute.columnName !== attr.on) {
          return;
        }

        if(key !== attr.on) delete reference[key];
      });

      // Get the only remaining key left
      var ref = Object.keys(reference)[0];

      if(ref) {

        // Build out the second join object that will link a junction table with the
        // values being populated
        var selects = _.map(_.keys(this._context.waterline.schema[reference[ref].references].attributes), function(attr) {
          var expandedAttr = self._context.waterline.schema[reference[ref].references].attributes[attr];
          return expandedAttr.columnName || attr;
        });

        join = {
          parent: attr.references,
          parentKey: reference[ref].columnName,
          child: reference[ref].references,
          childKey: reference[ref].on,
          select: selects,
          alias: keyName,
          junctionTable: true,
          removeParentKey: parentKey.model ? true : false,
          model: false,
          collection: true
        };

        joins.push(join);
      }
    }

    // Append the criteria to the correct join if available
    if(criteria && joins.length > 1) {
      joins[1].criteria = criteria;
    } else if(criteria) {
      joins[0].criteria = criteria;
    }

    // Set the criteria joins
    this._criteria.joins = Array.prototype.concat(this._criteria.joins || [], joins);

    return this;
  }
  catch (e) {
    throw new Error(
      'Encountered unexpected error while building join instructions for '+
      util.format('`.populate("%s")`', keyName)+
      '\nDetails:\n'+
      util.inspect(e,false, null)
    );
  }
};

/**
 * Add a Where clause to the criteria object
 *
 * @param {Object} criteria to append
 * @return this
 */

Deferred.prototype.where = function(criteria) {

  if(!criteria) return this;

  // If the criteria is an array of objects, wrap it in an "or"
  if (Array.isArray(criteria) && _.all(criteria, function(crit) {return _.isObject(crit);})) {
    criteria = {or: criteria};
  }

  // Normalize criteria
  criteria = normalize.criteria(criteria);

  // Wipe out the existing WHERE clause if the specified criteria ends up `false`
  // (since neither could match anything)
  if (criteria === false){
    this._criteria = false;
  }

  if(!criteria || !criteria.where) return this;

  if(!this._criteria) this._criteria = {};
  var where = this._criteria.where || {};

  // Merge with existing WHERE clause
  Object.keys(criteria.where).forEach(function(key) {
    where[key] = criteria.where[key];
  });

  this._criteria.where = where;

  return this;
};

/**
 * Add a Limit clause to the criteria object
 *
 * @param {Integer} number to limit
 * @return this
 */

Deferred.prototype.limit = function(limit) {
  this._criteria.limit = limit;

  return this;
};

/**
 * Add a Skip clause to the criteria object
 *
 * @param {Integer} number to skip
 * @return this
 */

Deferred.prototype.skip = function(skip) {
  this._criteria.skip = skip;

  return this;
};

/**
 * Add a Paginate clause to the criteria object
 *
 * This is syntatical sugar that calls skip and
 * limit from a single function.
 *
 * @param {Object} page and limit
 * @return this
 */
Deferred.prototype.paginate = function(options) {
  var defaultLimit = 10;

  if(options === undefined) options = { page: 0, limit: defaultLimit };

  var page  = options.page  || 0,
      limit = options.limit || defaultLimit,
      skip  = 0;

  if (page > 0 && limit === 0) skip = page - 1;
  if (page > 0 && limit > 0)  skip = (page * limit) - limit;

  this
  .skip(skip)
  .limit(limit);

  return this;
};

/**
 * Add a groupBy clause to the criteria object
 *
 * @param {Array|Arguments} Keys to group by
 * @return this
 */
Deferred.prototype.groupBy = function() {
  buildAggregate.call(this, 'groupBy', Array.prototype.slice.call(arguments));
  return this;
};


/**
 * Add a Sort clause to the criteria object
 *
 * @param {String|Object} key and order
 * @return this
 */

Deferred.prototype.sort = function(criteria) {

  if(!criteria) return this;

  // Normalize criteria
  criteria = normalize.criteria({ sort: criteria });

  var sort = this._criteria.sort || {};

  Object.keys(criteria.sort).forEach(function(key) {
    sort[key] = criteria.sort[key];
  });

  this._criteria.sort = sort;

  return this;
};

/**
 * Add a Sum clause to the criteria object
 *
 * @param {Array|Arguments} Keys to sum over
 * @return this
 */
Deferred.prototype.sum = function() {
  buildAggregate.call(this, 'sum', Array.prototype.slice.call(arguments));
  return this;
};

/**
 * Add an Average clause to the criteria object
 *
 * @param {Array|Arguments} Keys to average over
 * @return this
 */
Deferred.prototype.average = function() {
  buildAggregate.call(this, 'average', Array.prototype.slice.call(arguments));
  return this;
};

/**
 * Add a min clause to the criteria object
 *
 * @param {Array|Arguments} Keys to min over
 * @return this
 */
Deferred.prototype.min = function() {
  buildAggregate.call(this, 'min', Array.prototype.slice.call(arguments));
  return this;
};

/**
 * Add a min clause to the criteria object
 *
 * @param {Array|Arguments} Keys to min over
 * @return this
 */
Deferred.prototype.max = function() {
  buildAggregate.call(this, 'max', Array.prototype.slice.call(arguments));
  return this;
};



/**
 * Add values to be used in update or create query
 *
 * @param {Object, Array} values
 * @return this
 */

Deferred.prototype.set = function(values) {
  this._values = values;

  return this;
};

/**
 * Execute a Query using the method passed into the
 * constuctor.
 *
 * @param {Function} callback
 * @return callback with parameters (err, results)
 */

Deferred.prototype.exec = function(cb) {

  if(!cb) {
    console.log( new Error('Error: No Callback supplied, you must define a callback.').message );
    return;
  }

  // Normalize callback/switchback
  cb = normalize.callback(cb);

  // Set up arguments + callback
  var args = [this._criteria, cb];
  if(this._values) args.splice(1, 0, this._values);

  // Pass control to the adapter with the appropriate arguments.
  this._method.apply(this._context, args);
};

/**
 * Executes a Query, and returns a promise
 */

Deferred.prototype.toPromise = function() {
  if (!this._deferred) {
    this._deferred = Promise.promisify(this.exec).bind(this)();
  }
  return this._deferred;
};

/**
 * Executes a Query, and returns a promise that applies cb/ec to the
 * result/error.
 */

Deferred.prototype.then = function(cb, ec) {
  return this.toPromise().then(cb, ec);
};

/**
 * Applies results to function fn.apply, and returns a promise
 */

Deferred.prototype.spread = function(cb) {
  return this.toPromise().spread(cb);
};

/**
 * returns a promise and gets resolved with error
 */

Deferred.prototype.catch = function(cb) {
  return this.toPromise().catch(cb);
};


/**
 * Alias "catch" as "fail"
 */
Deferred.prototype.fail = Deferred.prototype.catch;

/**
 * Build An Aggregate Criteria Option
 *
 * @param {String} key
 * @api private
 */

function buildAggregate(key, args) {

  // If passed in a list, set that as the min criteria
  if (args[0] instanceof Array) {
    args = args[0];
  }

  this._criteria[key] = args || {};
}

},{"../utils/acyclicTraversal":64,"../utils/helpers":70,"../utils/normalize":76,"bluebird":"bluebird","lodash":"lodash","util":"util"}],44:[function(require,module,exports){
/**
 * Module Dependencies
 */

var _ = require('lodash');
var usageError = require('../../utils/usageError');
var utils = require('../../utils/helpers');
var normalize = require('../../utils/normalize');
var Deferred = require('../deferred');

/**
 * Count of Records
 *
 * @param {Object} criteria
 * @param {Object} options
 * @param {Function} callback
 * @return Deferred object if no callback
 */

module.exports = function(criteria, options, cb) {
  var usage = utils.capitalize(this.identity) + '.count([criteria],[options],callback)';

  if(typeof criteria === 'function') {
    cb = criteria;
    criteria = null;
    options = null;
  }

  if(typeof options === 'function') {
    cb = options;
    options = null;
  }

  // Return Deferred or pass to adapter
  if(typeof cb !== 'function') {
    return new Deferred(this, this.count, criteria);
  }

  // Normalize criteria and fold in options
  criteria = normalize.criteria(criteria);

  if(_.isObject(options) && _.isObject(criteria)) {
    criteria = _.extend({}, criteria, options);
  }

  if(_.isFunction(criteria) || _.isFunction(options)) {
    return usageError('Invalid options specified!', usage, cb);
  }

  // Transform Search Criteria
  criteria = this._transformer.serialize(criteria);

  this.adapter.count(criteria, cb);
};

},{"../../utils/helpers":70,"../../utils/normalize":76,"../../utils/usageError":82,"../deferred":43,"lodash":"lodash"}],45:[function(require,module,exports){
/**
 * Module Dependencies
 */

var async = require('async');
var _ = require('lodash');
var utils = require('../../utils/helpers');
var Deferred = require('../deferred');
var callbacks = require('../../utils/callbacksRunner');
var nestedOperations = require('../../utils/nestedOperations');
var hop = utils.object.hasOwnProperty;


/**
 * Create a new record
 *
 * @param {Object || Array} values for single model or array of multiple values
 * @param {Function} callback
 * @return Deferred object if no callback
 */

module.exports = function(values, cb) {

  var self = this;

  // Handle Deferred where it passes criteria first
  if(arguments.length === 3) {
    var args = Array.prototype.slice.call(arguments);
    cb = args.pop();
    values = args.pop();
  }

  values = values || {};

  // Remove all undefined values
  if(_.isArray(values)) {
    values = _.remove(values, undefined);
  }

  // Return Deferred or pass to adapter
  if(typeof cb !== 'function') {
    return new Deferred(this, this.create, {}, values);
  }


  // Handle Array of values
  if(Array.isArray(values)) {
    return this.createEach(values, cb);
  }

  // Process Values
  var valuesObject = processValues.call(this, values);

  // Create any of the belongsTo associations and set the foreign key values
  createBelongsTo.call(this, valuesObject, function(err) {
    if(err) return cb(err);

    beforeCallbacks.call(self, valuesObject, function(err) {
      if(err) return cb(err);
      createValues.call(self, valuesObject, cb);
    });
  });
};


/**
 * Process Values
 *
 * @param {Object} values
 * @return {Object}
 */

function processValues(values) {

  // Set Default Values if available
  for(var key in this.attributes) {
    if(!hop(values, key) && hop(this.attributes[key], 'defaultsTo')) {
      var defaultsTo = this.attributes[key].defaultsTo;
      values[key] = typeof defaultsTo === 'function' ? defaultsTo.call(values) : _.clone(defaultsTo);
    }
  }

  // Pull out any associations in the values
  var _values = _.cloneDeep(values);
  var associations = nestedOperations.valuesParser.call(this, this.identity, this.waterline.schema, values);

  // Replace associated models with their foreign key values if available
  values = nestedOperations.reduceAssociations.call(this, this.identity, this.waterline.schema, values);

  // Cast values to proper types (handle numbers as strings)
  values = this._cast.run(values);

  return { values: values, originalValues: _values, associations: associations };
}

/**
 * Create BelongsTo Records
 *
 */

function createBelongsTo(valuesObject, cb) {
  var self = this;

  async.each(valuesObject.associations.models, function(item, next) {

    // Check if value is an object. If not don't try and create it.
    if(!_.isPlainObject(valuesObject.values[item])) return next();

    // Check for any transformations
    var attrName = hop(self._transformer._transformations, item) ? self._transformer._transformations[item] : item;

    var attribute = self._schema.schema[attrName];
    var modelName;

    if(hop(attribute, 'collection')) modelName = attribute.collection;
    if(hop(attribute, 'model')) modelName = attribute.model;
    if(!modelName) return next();

    var model = self.waterline.collections[modelName];
    var pkValue = valuesObject.originalValues[item][model.primaryKey];

    var criteria = {};
    criteria[model.primaryKey] = pkValue;

    // If a pkValue if found, do a findOrCreate and look for a record matching the pk.
    var query;
    if(pkValue) {
      query = model.findOrCreate(criteria, valuesObject.values[item]);
    } else {
      query = model.create(valuesObject.values[item]);
    }

    query.exec(function(err, val) {
      if(err) return next(err);

      // attach the new model's pk value to the original value's key
      var pk = val[model.primaryKey];

      valuesObject.values[item] = pk;
      next();
    });

  }, cb);
}

/**
 * Run Before* Lifecycle Callbacks
 *
 * @param {Object} valuesObject
 * @param {Function} cb
 */

function beforeCallbacks(valuesObject, cb) {
  var self = this;

  async.series([

    // Run Validation with Validation LifeCycle Callbacks
    function(cb) {
      callbacks.validate(self, valuesObject.values, false, cb);
    },

    // Before Create Lifecycle Callback
    function(cb) {
      callbacks.beforeCreate(self, valuesObject.values, cb);
    }

  ], cb);

}

/**
 * Create Parent Record and any associated values
 *
 * @param {Object} valuesObject
 * @param {Function} cb
 */

function createValues(valuesObject, cb) {

  var self = this;

  // Automatically add updatedAt and createdAt (if enabled)
  if(self.autoCreatedAt && !valuesObject.values.createdAt) {
    valuesObject.values.createdAt = new Date();
  }

  if(self.autoUpdatedAt && !valuesObject.values.updatedAt) {
    valuesObject.values.updatedAt = new Date();
  }

  // Transform Values
  valuesObject.values = self._transformer.serialize(valuesObject.values);

  // Clean attributes
  valuesObject.values = self._schema.cleanValues(valuesObject.values);

  // Pass to adapter here
  self.adapter.create(valuesObject.values, function(err, values) {
    if (err) {
      if (typeof err === 'object') { err.model = self._model.globalId; }
      return cb(err);
    }

    // Unserialize values
    values = self._transformer.unserialize(values);

    // If no associations were used, run after
    if(valuesObject.associations.collections.length === 0) return after(values);

    var parentModel = new self._model(values);
    nestedOperations.create.call(self, parentModel, valuesObject.originalValues, valuesObject.associations.collections, function(err) {
      if(err) return cb(err);

      return after(parentModel.toObject());
    });


    function after(values) {

      // Run After Create Callbacks
      callbacks.afterCreate(self, values, function(err) {
        if(err) return cb(err);

        // Return an instance of Model
        var model = new self._model(values);
        cb(null, model);
      });
    }

  });
}

},{"../../utils/callbacksRunner":66,"../../utils/helpers":70,"../../utils/nestedOperations":72,"../deferred":43,"async":"async","lodash":"lodash"}],46:[function(require,module,exports){
/**
 * Module Dependencies
 */

var async = require('async');
var _ = require('lodash');
var usageError = require('../../utils/usageError');
var utils = require('../../utils/helpers');
var normalize = require('../../utils/normalize');
var Deferred = require('../deferred');
var getRelations = require('../../utils/getRelations');
var callbacks = require('../../utils/callbacksRunner');
var hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Destroy a Record
 *
 * @param {Object} criteria to destroy
 * @param {Function} callback
 * @return Deferred object if no callback
 */

module.exports = function(criteria, cb) {
  var self = this,
      pk;

  if(typeof criteria === 'function') {
    cb = criteria;
    criteria = {};
  }

  // Check if criteria is an integer or string and normalize criteria
  // to object, using the specified primary key field.
  criteria = normalize.expandPK(self, criteria);

  // Normalize criteria
  criteria = normalize.criteria(criteria);

  // Return Deferred or pass to adapter
  if(typeof cb !== 'function') {
    return new Deferred(this, this.destroy, criteria);
  }

  var usage = utils.capitalize(this.identity) + '.destroy([options], callback)';

  if(typeof cb !== 'function') return usageError('Invalid callback specified!', usage, cb);

  callbacks.beforeDestroy(self, criteria, function(err) {
    if(err) return cb(err);

    // Transform Search Criteria
    criteria = self._transformer.serialize(criteria);

    // Pass to adapter
    self.adapter.destroy(criteria, function(err, result) {
      if (err) return cb(err);

      // Look for any m:m associations and destroy the value in the join table
      var relations = getRelations({
        schema: self.waterline.schema,
        parentCollection: self.identity
      });

      if(relations.length === 0) return after();

      // Find the collection's primary key
      for(var key in self.attributes) {
        if(!self.attributes[key].hasOwnProperty('primaryKey')) continue;

        // Check if custom primaryKey value is falsy
        if(!self.attributes[key].primaryKey) continue;

        pk = key;
        break;
      }

      function destroyJoinTableRecords(item, next) {
        var collection = self.waterline.collections[item];
        var refKey;

        Object.keys(collection._attributes).forEach(function(key) {
          var attr = collection._attributes[key];
          if(attr.references !== self.identity) return;
          refKey = key;
        });

        // If no refKey return, this could leave orphaned join table values but it's better
        // than crashing.
        if(!refKey) return next();

        var mappedValues = result.map(function(vals) { return vals[pk]; });
        var criteria = {};

        if(mappedValues.length > 0) {
          criteria[refKey] = mappedValues;
        }

        collection.destroy(criteria).exec(next);
      }

      async.each(relations, destroyJoinTableRecords, function(err) {
        if(err) return cb(err);
        after();
      });

      function after() {
        callbacks.afterDestroy(self, result, function(err) {
          if(err) return cb(err);
          cb(null, result);
        });
      }

    });
  });
};

},{"../../utils/callbacksRunner":66,"../../utils/getRelations":69,"../../utils/helpers":70,"../../utils/normalize":76,"../../utils/usageError":82,"../deferred":43,"async":"async","lodash":"lodash"}],47:[function(require,module,exports){

/**
 * Export DQL Methods
 */

module.exports = {
  create: require('./create'),
  update: require('./update'),
  destroy: require('./destroy'),
  count: require('./count'),
  join: require('./join')
};

},{"./count":44,"./create":45,"./destroy":46,"./join":48,"./update":49}],48:[function(require,module,exports){
/**
 * Join
 *
 * Join with another collection
 * (use optimized join in adapter if one was provided)
 */

module.exports = function(collection, fk, pk, cb) {
  this._adapter.join(collection, fk, pk, cb);
};

},{}],49:[function(require,module,exports){
/**
 * Module Dependencies
 */

var async = require('async');
var _ = require('lodash');
var usageError = require('../../utils/usageError');
var utils = require('../../utils/helpers');
var normalize = require('../../utils/normalize');
var Deferred = require('../deferred');
var callbacks = require('../../utils/callbacksRunner');
var nestedOperations = require('../../utils/nestedOperations');
var hop = utils.object.hasOwnProperty;


/**
 * Update all records matching criteria
 *
 * @param {Object} criteria
 * @param {Object} values
 * @param {Function} cb
 * @return Deferred object if no callback
 */

module.exports = function(criteria, values, cb) {

  var self = this;

  if(typeof criteria === 'function') {
    cb = criteria;
    criteria = null;
  }

  // Return Deferred or pass to adapter
  if(typeof cb !== 'function') {
    return new Deferred(this, this.update, criteria, values);
  }

  // Ensure proper function signature
  var usage = utils.capitalize(this.identity) + '.update(criteria, values, callback)';
  if(!values) return usageError('No updated values specified!', usage, cb);

  // Format Criteria and Values
  var valuesObject = prepareArguments.call(this, criteria, values);

  // Create any of the belongsTo associations and set the foreign key values
  createBelongsTo.call(this, valuesObject, function(err) {
    if(err) return cb(err);

    beforeCallbacks.call(self, valuesObject.values, function(err) {
      if(err) return cb(err);
      updateRecords.call(self, valuesObject, cb);
    });
  });
};


/**
 * Prepare Arguments
 *
 * @param {Object} criteria
 * @param {Object} values
 * @return {Object}
 */

function prepareArguments(criteria, values) {

  // Check if options is an integer or string and normalize criteria
  // to object, using the specified primary key field.
  criteria = normalize.expandPK(this, criteria);

  // Normalize criteria
  criteria = normalize.criteria(criteria);

  // Pull out any associations in the values
  var _values = _.cloneDeep(values);
  var associations = nestedOperations.valuesParser.call(this, this.identity, this.waterline.schema, values);

  // Replace associated models with their foreign key values if available
  values = nestedOperations.reduceAssociations.call(this, this.identity, this.waterline.schema, values);

  // Cast values to proper types (handle numbers as strings)
  values = this._cast.run(values);

  return {
    criteria: criteria,
    values: values,
    originalValues: _values,
    associations: associations
  };
}

/**
 * Create BelongsTo Records
 *
 */

function createBelongsTo(valuesObject, cb) {
  var self = this;

  async.each(valuesObject.associations.models, function(item, next) {

    // Check if value is an object. If not don't try and create it.
    if(!_.isPlainObject(valuesObject.values[item])) return next();

    // Check for any transformations
    var attrName = hop(self._transformer._transformations, item) ? self._transformer._transformations[item] : item;

    var attribute = self._schema.schema[attrName];
    var modelName;

    if(hop(attribute, 'collection')) modelName = attribute.collection;
    if(hop(attribute, 'model')) modelName = attribute.model;
    if(!modelName) return next();

    var model = self.waterline.collections[modelName];
    var pkValue = valuesObject.originalValues[item][model.primaryKey];

    var criteria = {};

    var pkField = hop(model._transformer._transformations, model.primaryKey) ? model._transformer._transformations[model.primaryKey] : model.primaryKey;

    criteria[pkField] = pkValue;

    // If a pkValue if found, do a findOrCreate and look for a record matching the pk.
    var query;
    if(pkValue) {
      query = model.findOrCreate(criteria, valuesObject.values[item]);
    } else {
      query = model.create(valuesObject.values[item]);
    }

    query.exec(function(err, val) {
      if(err) return next(err);

      // attach the new model's pk value to the original value's key
      var pk = val[model.primaryKey];

      valuesObject.values[item] = pk;
      next();
    });

  }, cb);
}

/**
 * Run Before* Lifecycle Callbacks
 *
 * @param {Object} values
 * @param {Function} cb
 */

function beforeCallbacks(values, cb) {
  var self = this;

  async.series([

    // Run Validation with Validation LifeCycle Callbacks
    function(cb) {
      callbacks.validate(self, values, true, cb);
    },

    // Before Update Lifecycle Callback
    function(cb) {
      callbacks.beforeUpdate(self, values, cb);
    }

  ], cb);
}

/**
 * Update Records
 *
 * @param {Object} valuesObjecy
 * @param {Function} cb
 */

function updateRecords(valuesObject, cb) {
  var self = this;

  // Automatically change updatedAt (if enabled)
  if(this.autoUpdatedAt) {
    valuesObject.values.updatedAt = new Date();
  }

  // Transform Values
  valuesObject.values = this._transformer.serialize(valuesObject.values);

  // Clean attributes
  valuesObject.values = this._schema.cleanValues(valuesObject.values);

  // Transform Search Criteria
  valuesObject.criteria = self._transformer.serialize(valuesObject.criteria);


  // Pass to adapter
  self.adapter.update(valuesObject.criteria, valuesObject.values, function(err, values) {
    if (err) {
      if (typeof err === 'object') { err.model = self._model.globalId; }
      return cb(err);
    }

    // If values is not an array, return an array
    if(!Array.isArray(values)) values = [values];

    // Unserialize each value
    var transformedValues = values.map(function(value) {
      return self._transformer.unserialize(value);
    });

    // Update any nested associations and run afterUpdate lifecycle callbacks for each parent
    updatedNestedAssociations.call(self, valuesObject, transformedValues, function(err) {
      if (err) return cb(err);

      async.each(transformedValues, function(record, callback) {
        callbacks.afterUpdate(self, record, callback);
      }, function(err) {
        if(err) return cb(err);

        var models = transformedValues.map(function(value) {
          return new self._model(value);
        });

        cb(null, models);
      });
    });

  });
}

/**
 * Update Nested Associations
 *
 * @param {Object} valuesObject
 * @param {Object} values
 * @param {Function} cb
 */

function updatedNestedAssociations(valuesObject, values, cb) {

  var self = this;
  var associations = valuesObject.associations || {};

  // Only attempt nested updates if values are an object or an array
  associations.models = _.filter(associations.models, function(model) {
    var vals = valuesObject.originalValues[model];
    return _.isPlainObject(vals) || Array.isArray(vals) ? true : false;
  });

  // If no associations were used, return callback
  if(associations.collections.length === 0 && associations.models.length === 0) {
    return cb();
  }

  // Create an array of model instances for each parent
  var parents = values.map(function(val) {
    return new self._model(val);
  });

  // Update any nested associations found in the values object
  var args = [parents, valuesObject.originalValues, valuesObject.associations, cb];
  nestedOperations.update.apply(self, args);

}

},{"../../utils/callbacksRunner":66,"../../utils/helpers":70,"../../utils/nestedOperations":72,"../../utils/normalize":76,"../../utils/usageError":82,"../deferred":43,"async":"async","lodash":"lodash"}],50:[function(require,module,exports){
/**
 * Basic Finder Queries
 */

var usageError = require('../../utils/usageError'),
    utils = require('../../utils/helpers'),
    normalize = require('../../utils/normalize'),
    sorter = require('../../utils/sorter'),
    Deferred = require('../deferred'),
    Joins = require('./joins'),
    Operations = require('./operations'),
    Integrator = require('../integrator'),
    waterlineCriteria = require('waterline-criteria'),
    _ = require('lodash'),
    async = require('async'),
    hasOwnProperty = utils.object.hasOwnProperty;

module.exports = {

  /**
   * Find a single record that meets criteria
   *
   * @param {Object} criteria to search
   * @param {Function} callback
   * @return Deferred object if no callback
   */

  findOne: function(criteria, cb) {
    var self = this;

    if(typeof criteria === 'function') {
      cb = criteria;
      criteria = null;
    }

    // If the criteria is an array of objects, wrap it in an "or"
    if (Array.isArray(criteria) && _.all(criteria, function(crit) {return _.isObject(crit);})) {
      criteria = {or: criteria};
    }

    // Check if criteria is an integer or string and normalize criteria
    // to object, using the specified primary key field.
    criteria = normalize.expandPK(self, criteria);

    // Normalize criteria
    criteria = normalize.criteria(criteria);

    // Return Deferred or pass to adapter
    if(typeof cb !== 'function') {
      return new Deferred(this, this.findOne, criteria);
    }

    // Transform Search Criteria
    criteria = self._transformer.serialize(criteria);

    // If there was something defined in the criteria that would return no results, don't even
    // run the query and just return an empty result set.
    if(criteria === false) {
      return cb(null, null);
    }

    // Build up an operations set
    var operations = new Operations(self, criteria, 'findOne');

    // Run the operations
    operations.run(function(err, values) {
      if(err) return cb(err);
      if(!values.cache) return cb();

      // If no joins are used grab the only item from the cache and pass to the returnResults
      // function.
      if(!criteria.joins) {
        values = values.cache[self.identity];
        return returnResults(values);
      }

      // If the values are already combined, return the results
      if(values.combined) {
        return returnResults(values.cache[self.identity]);
      }

      // Find the primaryKey of the current model so it can be passed down to the integrator.
      // Use 'id' as a good general default;
      var primaryKey = 'id';

      Object.keys(self._schema.schema).forEach(function(key) {
        if(self._schema.schema[key].hasOwnProperty('primaryKey') && self._schema.schema[key].primaryKey) {
          primaryKey = key;
        }
      });


      // Perform in-memory joins
      Integrator(values.cache, criteria.joins, primaryKey, function(err, results) {
        if(err) return cb(err);
        if(!results) return cb();

        // We need to run one last check on the results using the criteria. This allows a self
        // association where we end up with two records in the cache both having each other as
        // embedded objects and we only want one result. However we need to filter any join criteria
        // out of the top level where query so that searchs by primary key still work.
        var tmpCriteria = _.cloneDeep(criteria.where);
        if(!tmpCriteria) tmpCriteria = {};

        criteria.joins.forEach(function(join) {
          if(!hasOwnProperty(join, 'alias')) return;

          // Check for `OR` criteria
          if(hasOwnProperty(tmpCriteria, 'or')) {
            tmpCriteria.or.forEach(function(search) {
              if(!hasOwnProperty(search, join.alias)) return;
              delete search[join.alias];
            });
            return;
          }

          if(!hasOwnProperty(tmpCriteria, join.alias)) return;
          delete tmpCriteria[join.alias];
        });

        // Pass results into Waterline-Criteria
        var _criteria = { where: tmpCriteria };
        results = waterlineCriteria('parent', { parent: results }, _criteria).results;

        results.forEach(function(res) {

          // Go Ahead and perform any sorts on the associated data
          criteria.joins.forEach(function(join) {
            if(!join.criteria) return;
            var c = normalize.criteria(join.criteria);
            if(!c.sort) return;

            var alias = join.alias;
            res[alias] = sorter(res[alias], c.sort);
          });
        });

        returnResults(results);
      });

      function returnResults(results) {

        if(!results) return cb();

        // Normalize results to an array
        if(!Array.isArray(results) && results) results = [results];

        // Unserialize each of the results before attempting any join logic on them
        var unserializedModels = [];
        results.forEach(function(result) {
          unserializedModels.push(self._transformer.unserialize(result));
        });

        var models = [];
        var joins = criteria.joins ? criteria.joins : [];
        var data = new Joins(joins, unserializedModels, self.identity, self._schema.schema, self.waterline.collections);

        // If `data.models` is invalid (not an array) return early to avoid getting into trouble.
        if (!data || !data.models || !data.models.forEach) {
          return cb(new Error('Values returned from operations set are not an array...'));
        }

        // Create a model for the top level values
        data.models.forEach(function(model) {
          models.push(new self._model(model, data.options));
        });

        cb(null, models[0]);
      }
    });
  },

  /**
   * Find All Records that meet criteria
   *
   * @param {Object} search criteria
   * @param {Object} options
   * @param {Function} callback
   * @return Deferred object if no callback
   */

  find: function(criteria, options, cb) {
    var self = this;

    var usage = utils.capitalize(this.identity) + '.find([criteria],[options]).exec(callback|switchback)';

    if(typeof criteria === 'function') {
      cb = criteria;
      criteria = null;
      options = null;
    }

    if(typeof options === 'function') {
      cb = options;
      options = null;
    }

    // If the criteria is an array of objects, wrap it in an "or"
    if (Array.isArray(criteria) && _.all(criteria, function(crit) {return _.isObject(crit);})) {
      criteria = {or: criteria};
    }

    // Check if criteria is an integer or string and normalize criteria
    // to object, using the specified primary key field.
    criteria = normalize.expandPK(self, criteria);

    // Normalize criteria
    criteria = normalize.criteria(criteria);

    // Validate Arguments
    if(typeof criteria === 'function' || typeof options === 'criteria') {
      return usageError('Invalid options specified!', usage, cb);
    }

    // Return Deferred or pass to adapter
    if(typeof cb !== 'function') {
      return new Deferred(this, this.find, criteria, options);
    }

    // If there was something defined in the criteria that would return no results, don't even
    // run the query and just return an empty result set.
    if(criteria === false) {
      return cb(null, []);
    }

    // Fold in options
    if(options === Object(options) && criteria === Object(criteria)) {
      criteria = _.extend({}, criteria, options);
    }

    // Transform Search Criteria
    if (!self._transformer) {
      throw new Error('Waterline can not access transformer-- maybe the context of the method is being overridden?');
    }

    criteria = self._transformer.serialize(criteria);


    // Build up an operations set
    var operations = new Operations(self, criteria, 'find');

    // Run the operations
    operations.run(function(err, values) {
      if(err) return cb(err);
      if(!values.cache) return cb();

      // If no joins are used grab current collection's item from the cache and pass to the returnResults
      // function.
      if(!criteria.joins) {
        values = values.cache[self.identity];
        return returnResults(values);
      }

      // If the values are already combined, return the results
      if(values.combined) {
        return returnResults(values.cache[self.identity]);
      }

      // Find the primaryKey of the current model so it can be passed down to the integrator.
      // Use 'id' as a good general default;
      var primaryKey = 'id';

      Object.keys(self._schema.schema).forEach(function(key) {
        if(self._schema.schema[key].hasOwnProperty('primaryKey') && self._schema.schema[key].primaryKey) {
          primaryKey = key;
        }
      });

      // Perform in-memory joins
      Integrator(values.cache, criteria.joins, primaryKey, function(err, results) {
        if(err) return cb(err);
        if(!results) return cb();

        // We need to run one last check on the results using the criteria. This allows a self
        // association where we end up with two records in the cache both having each other as
        // embedded objects and we only want one result. However we need to filter any join criteria
        // out of the top level where query so that searchs by primary key still work.
        var tmpCriteria = _.cloneDeep(criteria.where);
        if(!tmpCriteria) tmpCriteria = {};

        criteria.joins.forEach(function(join) {
          if(!hasOwnProperty(join, 'alias')) return;

          // Check for `OR` criteria
          if(hasOwnProperty(tmpCriteria, 'or')) {
            tmpCriteria.or.forEach(function(search) {
              if(!hasOwnProperty(search, join.alias)) return;
              delete search[join.alias];
            });
            return;
          }

          if(!hasOwnProperty(tmpCriteria, join.alias)) return;
          delete tmpCriteria[join.alias];
        });

        // Pass results into Waterline-Criteria
        var _criteria = { where: tmpCriteria };
        results = waterlineCriteria('parent', { parent: results }, _criteria).results;

        // Serialize values coming from an in-memory join before modelizing
        var _results = [];
        results.forEach(function(res) {

          // Go Ahead and perform any sorts on the associated data
          criteria.joins.forEach(function(join) {
            if(!join.criteria) return;
            var c = normalize.criteria(join.criteria);
            if(!c.sort) return;

            var alias = join.alias;
            res[alias] = sorter(res[alias], c.sort);
          });
        });

        returnResults(results);
      });

      function returnResults(results) {

        if(!results) return cb(null, []);

        // Normalize results to an array
        if(!Array.isArray(results) && results) results = [results];

        // Unserialize each of the results before attempting any join logic on them
        var unserializedModels = [];

        if(results) {
          results.forEach(function(result) {
            unserializedModels.push(self._transformer.unserialize(result));
          });
        }

        var models = [];
        var joins = criteria.joins ? criteria.joins : [];
        var data = new Joins(joins, unserializedModels, self.identity, self._schema.schema, self.waterline.collections);

        // NOTE:
        // If a "belongsTo" (i.e. HAS_FK) association is null, should it be transformed into
        // an empty array here?  That is not what is happening currently, and it can cause
        // unexpected problems when implementing the native join method as an adapter implementor.
        // ~Mike June 22, 2014

        // If `data.models` is invalid (not an array) return early to avoid getting into trouble.
        if (!data || !data.models || !data.models.forEach) {
          return cb(new Error('Values returned from operations set are not an array...'));
        }

        // Create a model for the top level values
        data.models.forEach(function(model) {
          models.push(new self._model(model, data.options));
        });


        cb(null, models);
      }

    });
  },

  where: function() {
    this.find.apply(this, Array.prototype.slice.call(arguments));
  },

  select: function() {
    this.find.apply(this, Array.prototype.slice.call(arguments));
  },


  /**
   * findAll
   * [[ Deprecated! ]]
   *
   * @param  {Object}   criteria
   * @param  {Object}   options
   * @param  {Function} cb
   */
  findAll: function(criteria, options, cb) {
    if(typeof criteria === 'function') {
      cb = criteria;
      criteria = null;
      options = null;
    }

    if(typeof options === 'function') {
      cb = options;
      options = null;
    }

    // Return Deferred or pass to adapter
    if(typeof cb !== 'function') {
      return new Deferred(this, this.findAll, criteria);
    }

    cb(new Error('In Waterline >= 0.9, findAll() has been deprecated in favor of find().' +
                '\nPlease visit the migration guide at http://sailsjs.org for help upgrading.'));
  }

};

},{"../../utils/helpers":70,"../../utils/normalize":76,"../../utils/sorter":78,"../../utils/usageError":82,"../deferred":43,"../integrator":58,"./joins":53,"./operations":54,"async":"async","lodash":"lodash","waterline-criteria":97}],51:[function(require,module,exports){
/**
 * Dynamic Queries
 *
 * Query the collection using the name of the attribute directly
 */

var _ = require('lodash'),
    usageError = require('../../utils/usageError'),
    utils = require('../../utils/helpers'),
    normalize = require('../../utils/normalize'),
    hasOwnProperty = utils.object.hasOwnProperty;

var finder = module.exports = {};

/**
 * buildDynamicFinders
 *
 * Attaches shorthand dynamic methods to the prototype for each attribute
 * in the schema.
 */

finder.buildDynamicFinders = function() {
  var self = this;

  // For each defined attribute, create a dynamic finder function
  Object.keys(this._schema.schema).forEach(function(attrName) {

    // Check if attribute is an association, if so generate limited dynamic finders
    if (hasOwnProperty(self._schema.schema[attrName], 'foreignKey')) {
      if (self.associationFinders !== false) {
        self.generateAssociationFinders(attrName);
      }
      return;
    }

    var capitalizedMethods = ['findOneBy*', 'findOneBy*In', 'findOneBy*Like', 'findBy*', 'findBy*In',
      'findBy*Like', 'countBy*', 'countBy*In', 'countBy*Like'];

    var lowercasedMethods = ['*StartsWith', '*Contains', '*EndsWith'];


    if (self.dynamicFinders !== false) {
      capitalizedMethods.forEach(function(method) {
        self.generateDynamicFinder(attrName, method);
      });
      lowercasedMethods.forEach(function(method) {
        self.generateDynamicFinder(attrName, method, true);
      });
    }
  });
};


/**
 * generateDynamicFinder
 *
 * Creates a dynamic method based off the schema. Used for shortcuts for various
 * methods where a criteria object can automatically be built.
 *
 * @param {String} attrName
 * @param {String} method
 * @param {Boolean} dont capitalize the attrName or do, defaults to false
 */

finder.generateDynamicFinder = function(attrName, method, dontCapitalize) {
  var self = this,
      criteria;

  // Capitalize Attribute Name for camelCase
  var preparedAttrName = dontCapitalize ? attrName : utils.capitalize(attrName);

  // Figure out actual dynamic method name by injecting attribute name
  var actualMethodName = method.replace(/\*/g, preparedAttrName);

  // Assign this finder to the collection
  this[actualMethodName] = function dynamicMethod(value, options, cb) {

    if(typeof options === 'function') {
      cb = options;
      options = null;
    }

    options = options || {};

    var usage = utils.capitalize(self.identity) + '.' + actualMethodName + '(someValue,[options],callback)';

    if(typeof value === 'undefined') return usageError('No value specified!', usage, cb);
    if(options.where) return usageError('Cannot specify `where` option in a dynamic ' + method + '*() query!', usage, cb);

    // Build criteria query and submit it
    options.where = {};
    options.where[attrName] = value;

    switch(method) {


      ///////////////////////////////////////
      // Finders
      ///////////////////////////////////////


      case 'findOneBy*':
      case 'findOneBy*In':
        return self.findOne(options, cb);

      case 'findOneBy*Like':
        criteria = _.extend(options, {
          where: {
            like: options.where
          }
        });

        return self.findOne(criteria, cb);


      ///////////////////////////////////////
      // Aggregate Finders
      ///////////////////////////////////////


      case 'findBy*':
      case 'findBy*In':
        return self.find(options, cb);

      case 'findBy*Like':
        criteria = _.extend(options, {
          where: {
            like: options.where
          }
        });

        return self.find(criteria, cb);


      ///////////////////////////////////////
      // Count Finders
      ///////////////////////////////////////


      case 'countBy*':
      case 'countBy*In':
        return self.count(options, cb);

      case 'countBy*Like':
        criteria = _.extend(options, {
          where: {
            like: options.where
          }
        });

        return self.count(criteria, cb);


      ///////////////////////////////////////
      // Searchers
      ///////////////////////////////////////

      case '*StartsWith':
        return self.startsWith(options, cb);

      case '*Contains':
        return self.contains(options, cb);

      case '*EndsWith':
        return self.endsWith(options, cb);
    }
  };
};


/**
 * generateAssociationFinders
 *
 * Generate Dynamic Finders for an association.
 * Adds a .findBy<name>() method for has_one and belongs_to associations.
 *
 * @param {String} attrName, the column name of the attribute
 */

finder.generateAssociationFinders = function(attrName) {
  var self = this,
      name, model;

  // Find the user defined key for this attrName, look in self defined columnName
  // properties and if that's not set see if the generated columnName matches the attrName
  for(var key in this._attributes) {

    // Cache the value
    var cache = this._attributes[key];

    if(!hasOwnProperty(cache, 'model')) continue;

    if(cache.model.toLowerCase() + '_id' === attrName) {
      name = key;
      model = cache.model;
    }
  }

  if(!name || !model) return;

  // Build a findOneBy<attrName> dynamic finder that forces a join on the association
  this['findOneBy' + utils.capitalize(name)] = function dynamicAssociationMethod(value, cb) {

    // Check proper usage
    var usage = utils.capitalize(self.identity) + '.' + 'findBy' + utils.capitalize(name) +
      '(someValue, callback)';

    if(typeof value === 'undefined') return usageError('No value specified!', usage, cb);
    if(typeof value === 'function') return usageError('No value specified!', usage, cb);

    var criteria = associationQueryCriteria(self, value, attrName);
    return this.findOne(criteria, cb);
  };

  // Build a findBy<attrName> dynamic finder that forces a join on the association
  this['findBy' + utils.capitalize(name)] = function dynamicAssociationMethod(value, cb) {

    // Check proper usage
    var usage = utils.capitalize(self.identity) + '.' + 'findBy' + utils.capitalize(name) +
      '(someValue, callback)';

    if(typeof value === 'undefined') return usageError('No value specified!', usage, cb);
    if(typeof value === 'function') return usageError('No value specified!', usage, cb);

    var criteria = associationQueryCriteria(self, value, attrName);
    return this.find(criteria, cb);
  };
};


/**
 * Build Join Array
 */

function buildJoin() {
  var self = this,
      pk, attr;

  // Set the attr value to the generated schema attribute
  attr = self.waterline.schema[self.identity].attributes[name];

  // Get the current collection's primary key attribute
  Object.keys(self._attributes).forEach(function(key) {
    if(hasOwnProperty(self._attributes[key], 'primaryKey') && self._attributes[key].primaryKey) {
      pk = key;
    }
  });

  if(!attr) throw new Error('Attempting to populate an attribute that doesn\'t exist');

  // Grab the key being populated to check if it is a has many to belongs to
  // If it's a belongs_to the adapter needs to know that it should replace the foreign key
  // with the associated value.
  var parentKey = self.waterline.collections[self.identity].attributes[name];


  // Build the initial join object that will link this collection to either another collection
  // or to a junction table.
  var join = {
    parent: self._tableName,
    parentKey: attr.columnName || pk,
    child: attr.references,
    childKey: attr.on,
    select: true,
    removeParentKey: parentKey.model ? true : false
  };

  return join;
}

/**
 * Query Criteria Builder for associations
 */

function associationQueryCriteria(context, value, attrName) {

  // Build a criteria object
  var criteria = {
    where: {},
    joins: []
  };

  // Build a join condition
  var join = buildJoin.call(context);
  criteria.joins.push(join);

  // Add where values
  criteria.where[attrName] = value;
  return criteria;
}

},{"../../utils/helpers":70,"../../utils/normalize":76,"../../utils/usageError":82,"lodash":"lodash"}],52:[function(require,module,exports){
/**
 * Finder Helper Queries
 *
 * (these call other collection-level methods)
 */

var usageError = require('../../utils/usageError'),
    utils = require('../../utils/helpers'),
    normalize = require('../../utils/normalize');

module.exports = {

  // Return models where ALL of the specified attributes match queryString

  findOneLike: function(criteria, options, cb) {
    var usage = utils.capitalize(this.identity) + '.findOneLike([criteria],[options],callback)';

    // Normalize criteria
    criteria = normalize.likeCriteria(criteria, this._schema.schema);
    if(!criteria) return usageError('Criteria must be an object!', usage, cb);

    this.findOne(criteria, options, cb);
  },

  findLike: function(criteria, options, cb) {
    var usage = utils.capitalize(this.identity) + '.findLike([criteria],[options],callback)';

    // Normalize criteria
    criteria = normalize.likeCriteria(criteria, this._schema.schema);
    if(!criteria) return usageError('Criteria must be an object!', usage, cb);

    this.find(criteria, options, cb);
  },

  // Return models where >= 1 of the specified attributes start with queryString
  startsWith: function(criteria, options, cb) {
    var usage = utils.capitalize(this.identity) + '.startsWith([criteria],[options],callback)';

    criteria = normalize.likeCriteria(criteria, this._schema.schema, function applyStartsWith(criteria) {
      return criteria + '%';
    });

    if(!criteria) return usageError('Criteria must be an object!', usage, cb);

    this.find(criteria, options, cb);
  },

  // Return models where >= 1 of the specified attributes end with queryString
  endsWith: function(criteria, options, cb) {
    var usage = utils.capitalize(this.identity) + '.startsWith([criteria],[options],callback)';

    criteria = normalize.likeCriteria(criteria, this._schema.schema, function applyEndsWith(criteria) {
      return '%' + criteria;
    });

    if(!criteria) return usageError('Criteria must be an object!', usage, cb);

    this.find(criteria, options, cb);
  },

  // Return models where >= 1 of the specified attributes contain queryString
  contains: function(criteria, options, cb) {
    var usage = utils.capitalize(this.identity) + '.startsWith([criteria],[options],callback)';

    criteria = normalize.likeCriteria(criteria, this._schema.schema, function applyContains(criteria) {
      return '%' + criteria + '%';
    });

    if(!criteria) return usageError('Criteria must be an object!', usage, cb);

    this.find(criteria, options, cb);
  }

};

},{"../../utils/helpers":70,"../../utils/normalize":76,"../../utils/usageError":82}],53:[function(require,module,exports){
/**
 * Module Dependencies
 */

var _ = require('lodash');
var utils = require('../../utils/helpers');
var hop = utils.object.hasOwnProperty;

/**
 * Logic For Handling Joins inside a Query Results Object
 */

var Joins = module.exports = function(joins, values, identity, schema, collections) {

  this.identity = identity;

  // Hold Joins specified in the criteria
  this.joins = joins || [];

  // Hold the result values
  this.values = values || [];

  // Hold the overall schema
  this.schema = schema || {};

  // Hold all the Waterline collections so we can make models
  this.collections = collections || {};

  // Build up modelOptions
  this.modelOptions();

  // Modelize values
  this.models = this.makeModels();

  return this;
};

/**
 * Build up Join Options that will be passed down to a Model instance.
 *
 * @api private
 */

Joins.prototype.modelOptions = function modelOptions() {

  var self = this,
      joins;

  // Build Model Options, determines what associations to render in toObject
  this.options = {
    showJoins: this.joins ? true : false
  };

  // If no joins were used, just return
  if(!this.joins) return;

  // Map out join names to pass down to the model instance
  joins = this.joins.filter(function(join) {

    // If the value is not being selected, don't add it to the array
    if(!join.select) return false;

    return join;
  });

  // Map out join key names and attach to the options object.
  // For normal assoiciations, use the child table name that is being joined. For many-to-many
  // associations the child table name won't work so grab the alias used and use that for the
  // join name. It will be the one that is transformed.
  this.options.joins = joins.map(function(join) {
    var child = [];
    // If a junctionTable was not used, return the child table
    if(!join.junctionTable) return join.child;

    // Find the original alias for the join
    self.joins.forEach(function(j) {
      if(j.child !== join.parent) return;
      child.push(j.alias);
    });

    // If a child was found, return it otherwise just return the original child join
    if(child) return child;
    return join.child;
  });

  // Flatten joins
  this.options.joins = _.uniq(_.flatten(this.options.joins));
};

/**
 * Transform Values into instantiated Models.
 *
 * @return {Array}
 * @api private
 */

Joins.prototype.makeModels = function makeModels() {

  var self = this,
      models = [],
      model;

  // If values are invalid (not an array), return them early.
  if (!this.values || !this.values.forEach) return this.values;

  // Make each result an instance of model
  this.values.forEach(function(value) {
    model = self.modelize(value);
    models.push(model);
  });

  return models;
};

/**
 * Handle a single Result and inspect it's values for anything
 * that needs to become a Model instance.
 *
 * @param {Object} value
 * @return {Object}
 * @api private
 */

Joins.prototype.modelize = function modelize(value) {
  var self = this;

  // Look at each key in the object and see if it was used in a join
  Object.keys(value).forEach(function(key) {

    var joinKey = false,
        attr,
        usedInJoin;

    // If showJoins wasn't set or no joins were found there is nothing to modelize
    if(!self.options.showJoins || !self.options.joins) return;

    // Look at the schema for an attribute and check if it's a foreign key
    // or a virtual hasMany collection attribute

    // Check if there is a transformation on this attribute
    var transformer = self.collections[self.identity]._transformer._transformations;
    if(hop(transformer, key)) {
      attr = self.schema[transformer[key]];
    }
    else {
      attr = self.schema[key];
    }

    // If an attribute was found but it's not a model, this means it's a normal
    // key/value attribute and not an association so there is no need to modelize it.
    if(attr && !attr.hasOwnProperty('model')) return;

    // If the attribute has a `model` property, the joinKey is the collection of the model
    if(attr && attr.hasOwnProperty('model')) joinKey = attr.model;

    // If the attribute is a foreign key but it was not populated, just leave the foreign key
    // as it is and don't try and modelize it.
    if(joinKey && self.options.joins.indexOf(joinKey) < 0) return;

    // Check if the key was used in a join
    usedInJoin = self.checkForJoin(key);

    // If the attribute wasn't used in the join, don't turn it into a model instance.
    // NOTE: Not sure if this is correct or not?
    if(!usedInJoin.used) return;

    // If the attribute is an array of child values, for each one make a model out of it.
    if(Array.isArray(value[key])) {

      var records = [];

      value[key].forEach(function(val) {
        var collection,
            model;

        // If there is a joinKey this means it's a belongsTo association so the collection
        // containing the proper model will be the name of the joinKey model.
        if(joinKey) {
          collection = self.collections[joinKey];
          val = collection._transformer.unserialize(val);
          model = new collection._model(val, { showJoins: false });
          return records.push(model);
        }

        // Otherwise look at the join used and determine which key should be used to get
        // the proper model from the collections.
        collection = self.collections[usedInJoin.join.child];
        val = collection._transformer.unserialize(val);
        model = new collection._model(val, { showJoins: false });
        return records.push(model);
      });

      // Set the value to the array of model values
      value[key] = records;
      return;
    }

    // If the value isn't an array it's a populated foreign key so modelize it and attach
    // it directly on the attribute
    collection = self.collections[joinKey];
    value[key] = collection._transformer.unserialize(value[key]);
    value[key] = new collection._model(value[key], { showJoins: false });
  });

  return value;
};

/**
 * Test if an attribute was used in a join.
 * Requires generating a key to test against an attribute because the model process
 * will be run before any transformations have taken place.
 *
 * @param {String} key
 * @return {Object}
 * @api private
 */

Joins.prototype.checkForJoin = function checkForJoin(key) {

  var generatedKey,
      usedInJoin = false,
      relatedJoin;

  // Loop through each join and see if the given key matches a join used
  this.joins.forEach(function(join) {
    if(join.alias !== key) return;
    usedInJoin = true;
    relatedJoin = join;
  });

  return { used: usedInJoin, join: relatedJoin };
};

},{"../../utils/helpers":70,"lodash":"lodash"}],54:[function(require,module,exports){

/**
 * Module Dependencies
 */

var _ = require('lodash'),
    async = require('async'),
    utils = require('../../utils/helpers'),
    normalize = require('../../utils/normalize'),
    hasOwnProperty = utils.object.hasOwnProperty;

/**
 * Builds up a set of operations to perform based on search criteria.
 *
 * This allows the ability to do cross-adapter joins as well as fake joins
 * on adapters that haven't implemented the join interface yet.
 */

var Operations = module.exports = function(context, criteria, parent) {

  // Build up a cache
  this.cache = {};

  // Set context
  this.context = context;

  // Set criteria
  this.criteria = criteria;

  // Set parent
  this.parent = parent;

  // Hold a default value for pre-combined results (native joins)
  this.preCombined = false;

  // Seed the Cache
  this._seedCache();

  // Build Up Operations
  this.operations = this._buildOperations();

  return this;
};


/***********************************************************************************
 * PUBLIC METHODS
 ***********************************************************************************/


/**
 * Run Operations
 *
 * Execute a set of generated operations returning an array of results that can
 * joined in-memory to build out a valid results set.
 *
 * @param {Function} cb
 * @api public
 */

Operations.prototype.run = function run(cb) {

  var self = this;

  // Grab the parent operation, it will always be the very first operation
  var parentOp = this.operations.shift();

  // Run The Parent Operation
  this._runOperation(parentOp.collection, parentOp.method, parentOp.criteria, function(err, results) {

    if(err) return cb(err);

    // Set the cache values
    self.cache[parentOp.collection] = results;

    // If results are empty, or we're already combined, nothing else to so do return
    if(!results || self.preCombined) return cb(null, { combined: true, cache: self.cache });

    // Run child operations and populate the cache
    self._execChildOpts(results, function(err) {
      if(err) return cb(err);
      cb(null, { combined: self.preCombined, cache: self.cache });
    });

  });

};


/***********************************************************************************
 * PRIVATE METHODS
 ***********************************************************************************/


/**
 * Seed Cache with empty values.
 *
 * For each Waterline Collection set an empty array of values into the cache.
 *
 * @api private
 */

Operations.prototype._seedCache = function _seedCache() {
  var self = this;

  // Fill the cache with empty values for each collection
  Object.keys(this.context.waterline.schema).forEach(function(key) {
    self.cache[key] = [];
  });
};

/**
 * Build up the operations needed to perform the query based on criteria.
 *
 * @return {Array}
 * @api private
 */

Operations.prototype._buildOperations = function _buildOperations() {

  var self = this,
      operations = [];

  // Check if joins were used, if not only a single operation is needed on a single connection
  if(!hasOwnProperty(this.criteria, 'joins')) {

    // Grab the collection
    var collection = this.context.waterline.collections[this.context.identity];

    // Find the name of the connection to run the query on using the dictionary
    var connectionName = collection.adapterDictionary[this.parent];
    if(!connectionName) connectionName = collection.adapterDictionary.find;

    operations.push({
      connection: connectionName,
      collection: this.context.identity,
      method: this.parent,
      criteria: this.criteria
    });

    return operations;
  }

  // Joins were used in this operation. Lets grab the connections needed for these queries. It may
  // only be a single connection in a simple case or it could be multiple connections in some cases.
  var connections = this._getConnections();

  // Now that all the connections are created, build up operations needed to accomplish the end
  // goal of getting all the results no matter which connection they are on. To do this,
  // figure out if a connection supports joins and if so pass down a criteria object containing
  // join instructions. If joins are not supported by a connection, build a series of operations
  // to achieve the end result.
  operations = this._stageOperations(connections);

  return operations;
};

/**
 * Stage Operation Sets
 *
 * @param {Object} connections
 * @api private
 */

Operations.prototype._stageOperations = function _stageOperations(connections) {

  var self = this,
      operations = [];

  // Build the parent operation and set it as the first operation in the array
  operations = operations.concat(this._createParentOperation(connections));

  // Parent Connection Name
  var parentConnection = this.context.adapterDictionary[this.parent];

  // Parent Operation
  var parentOperation = operations[0];

  // For each additional connection build operations
  Object.keys(connections).forEach(function(connection) {

    // Ignore the connection used for the parent operation if a join can be used on it.
    // This means all of the operations for the query can take place on a single connection
    // using a single query.
    if(connection === parentConnection && parentOperation.method === 'join') return;

    // Operations are needed that will be run after the parent operation has been completed.
    // If there are more than a single join, set the parent join and build up children operations.
    // This occurs in a many-to-many relationship when a join table is needed.

    // Criteria is omitted until after the parent operation has been run so that an IN query can
    // be formed on child operations.

    var localOpts = [];

    connections[connection].joins.forEach(function(join, idx) {

      var operation = {
        connection: connection,
        collection: join.child,
        method: 'find',
        join: join
      };

      // If this is the first join, it can't have any parents
      if(idx === 0) {
        localOpts.push(operation);
        return;
      }

      // Look into the previous operations and see if this is a child of any of them
      var child = false;
      localOpts.forEach(function(localOpt) {
        if(localOpt.join.child !== join.parent) return;
        localOpt.child = operation;
        child = true;
      });

      if(child) return;
      localOpts.push(operation);
    });

    operations = operations.concat(localOpts);
  });

  return operations;
};

/**
 * Create The Parent Operation
 *
 * @param {Object} connections
 * @return {Object}
 * @api private
 */

Operations.prototype._createParentOperation = function _createParentOperation(connections) {

  var nativeJoin = this.context.adapter.hasJoin(),
      operation,
      connectionName,
      connection;

  // If the parent supports native joins, check if all the joins on the connection can be
  // run on the same connection and if so just send the entire criteria down to the connection.
  if(nativeJoin) {

    connectionName = this.context.adapterDictionary.join;
    connection = connections[connectionName];

    // Hold any joins that can't be run natively on this connection
    var unsupportedJoins = false;

    // Pull out any unsupported joins
    connection.joins.forEach(function(join) {
      if(connection.collections.indexOf(join.child) > -1) return;
      unsupportedJoins = true;
    });

    // If all the joins were supported then go ahead and build an operation.
    if(!unsupportedJoins) {
      operation = [{
        connection: connectionName,
        collection: this.context.identity,
        method: 'join',
        criteria: this.criteria
      }];

      // Set the preCombined flag
      this.preCombined = true;

      return operation;
    }
  }

  // Remove the joins from the criteria object, this will be an in-memory join
  var tmpCriteria = _.cloneDeep(this.criteria);
  delete tmpCriteria.joins;

  connectionName = this.context.adapterDictionary[this.parent];

  // If findOne was used, use the same connection `find` is on.
  if(this.parent === 'findOne' && !connectionName) {
    connectionName = this.context.adapterDictionary.find;
  }

  connection = connections[connectionName];

  operation = [{
    connection: connectionName,
    collection: this.context.identity,
    method: this.parent,
    criteria: tmpCriteria
  }];

  return operation;
};


/**
 * Get the connections used in this query and the join logic for each piece.
 *
 * @return {Object}
 * @api private
 */

Operations.prototype._getConnections = function _getConnections() {

  var self = this;
  var connections = {};

  // Default structure for connection objects
  var defaultConnection = {
    collections: [],
    children: [],
    joins: []
  };

  // For each join build a connection item to build up an entire collection/connection registry
  // for this query. Using this, queries should be able to be seperated into discrete queries
  // which can be run on connections in parallel.
  this.criteria.joins.forEach(function(join) {

    var connection;

    // Grab the parent collection
    var collection = self.context.waterline.collections[join.parent];

    // Find the connection object in the registry
    var connectionName = collection.adapterDictionary['find'];

    // If this join is a junctionTable, find the parent operation and add it to that connections
    // children instead of creating a new operation on another connection. This allows cross-connection
    // many-to-many joins to be used where the join relies on the results of the parent operation
    // being run first.

    if(join.junctionTable) {

      // Grab the parent collection
      collection = self.context.waterline.collections[join.parent];

      // Find the connection object in the registry
      connectionName = collection.adapterDictionary['find'];
      connections[connectionName] = connections[connectionName] || _.clone(DefaultConnection);

      // Update the registry with the join values
      connections[connectionName].collections.push(join.child);
      connections[connectionName].children.push(join.parent);

      // Add the join to the joins array for this connection
      connections[connectionName].joins = connections[connectionName].joins.concat(join);

      return;
    }

    function updateRegistry(collName) {
      var collection = self.context.waterline.collections[collName];
      var connectionName = collection.adapterDictionary['find'];
      connections[connectionName] = connections[connectionName] || _.cloneDeep(defaultConnection);

      // Update the registry with the join values
      connections[connectionName].collections.push(collection.identity);
    }

    updateRegistry(join.parent);
    updateRegistry(join.child);

    // Add the join to the joins array for this connection
    connections[connectionName].joins = connections[connectionName].joins.concat(join);
  });

  return connections;
};


/**
 * Run An Operation
 *
 * Performs an operation and runs a supplied callback.
 *
 * @param {Object} collectionName
 * @param {String} method
 * @param {Object} criteria
 * @param {Function} cb
 *
 * @api private
 */

Operations.prototype._runOperation = function _runOperation(collectionName, method, criteria, cb) {

  // Ensure the collection exist
  if(!hasOwnProperty(this.context.waterline.collections, collectionName)) {
    return cb(new Error('Invalid Collection specfied in operation.'));
  }

  // Find the connection object to run the operation
  var collection = this.context.waterline.collections[collectionName];

  // Run the operation
  collection.adapter[method](criteria, cb);

};

/**
 * Execute Child Operations
 *
 * If joins are used and an adapter doesn't support them, there will be child operations that will
 * need to be run. Parse each child operation and run them along with any tree joins and return
 * an array of children results that can be combined with the parent results.
 *
 * @param {Array} parentResults
 * @param {Function} cb
 */

Operations.prototype._execChildOpts = function _execChildOpts(parentResults, cb) {

  var self = this;

  // Build up a set of child operations that will need to be run
  // based on the results returned from the parent operation.
  this._buildChildOpts(parentResults, function(err, opts) {
    if(err) return cb(err);

    // Run the generated operations in parallel
    async.each(opts, function(item, next) {
      self._collectChildResults(item, next);
    }, cb);
  });

};

/**
 * Build Child Operations
 *
 * Using the results of a parent operation, build up a set of operations that contain criteria
 * based on what is returned from a parent operation. These can be arrays containing more than
 * one operation for each child, which will happen when "join tables" would be used.
 *
 * Each set should be able to be run in parallel.
 *
 * @param {Array} parentResults
 * @param {Function} cb
 * @return {Array}
 * @api private
 */

Operations.prototype._buildChildOpts = function _buildChildOpts(parentResults, cb) {

  var self = this;
  var opts = [];

  // Build up operations that can be run in parallel using the results of the parent operation
  async.each(this.operations, function(item, next) {

    var localOpts = [],
        parents = [],
        idx = 0;

    // Go through all the parent records and build up an array of keys to look in. This
    // will be used in an IN query to grab all the records needed for the "join".
    parentResults.forEach(function(result) {

      if(!hasOwnProperty(result, item.join.parentKey)) return;
      if(result[item.join.parentKey] === null || typeof result[item.join.parentKey] === undefined) return;
      parents.push(result[item.join.parentKey]);

    });

    // If no parents match the join criteria, don't build up an operation
    if(parents.length === 0) return next();

    // Build up criteria that will be used inside an IN query
    var criteria = {};
    criteria[item.join.childKey] = parents;

    var _tmpCriteria = {};

    // Check if the join contains any criteria
    if(item.join.criteria) {
      var userCriteria = _.cloneDeep(item.join.criteria);
      _tmpCriteria = _.cloneDeep(userCriteria);
      _tmpCriteria = normalize.criteria(_tmpCriteria);

      // Ensure `where` criteria is properly formatted
      if(hasOwnProperty(userCriteria, 'where')) {
        if(userCriteria.where === undefined) {
          delete userCriteria.where;
        }
        else {

          // If an array of primary keys was passed in, normalize the criteria
          if(Array.isArray(userCriteria.where)) {
            var pk = self.context.waterline.collections[item.join.child].primaryKey;
            var obj = {};
            obj[pk] = _.clone(userCriteria.where);
            userCriteria.where = obj;
          }

          userCriteria = userCriteria.where;
        }
      }


      criteria = _.merge(userCriteria, criteria);
    }

    // Normalize criteria
    criteria = normalize.criteria(criteria);

    // If criteria contains a skip or limit option, an operation will be needed for each parent.
    if(hasOwnProperty(_tmpCriteria, 'skip') || hasOwnProperty(_tmpCriteria, 'limit')) {
      parents.forEach(function(parent) {

        var tmpCriteria = _.cloneDeep(criteria);
        tmpCriteria.where[item.join.childKey] = parent;

        // Mixin the user defined skip and limit
        if(hasOwnProperty(_tmpCriteria, 'skip')) tmpCriteria.skip = _tmpCriteria.skip;
        if(hasOwnProperty(_tmpCriteria, 'limit')) tmpCriteria.limit = _tmpCriteria.limit;

        // Build a simple operation to run with criteria from the parent results.
        // Give it an ID so that children operations can reference it if needed.
        localOpts.push({
          id: idx,
          collection: item.collection,
          method: item.method,
          criteria: tmpCriteria,
          join: item.join
        });

      });
    } else {

      // Build a simple operation to run with criteria from the parent results.
      // Give it an ID so that children operations can reference it if needed.
      localOpts.push({
        id: idx,
        collection: item.collection,
        method: item.method,
        criteria: criteria,
        join: item.join
      });

    }

    // If there are child records, add the opt but don't add the criteria
    if(!item.child) {
      opts.push(localOpts);
      return next();
    }

    localOpts.push({
      collection: item.child.collection,
      method: item.child.method,
      parent: idx,
      join: item.child.join
    });

    // Add the local opt to the opts array
    opts.push(localOpts);

    next();
  }, function(err) {
    cb(err, opts);
  });
};

/**
 * Collect Child Operation Results
 *
 * Run a set of child operations and return the results in a namespaced array
 * that can later be used to do an in-memory join.
 *
 * @param {Array} opts
 * @param {Function} cb
 * @api private
 */

Operations.prototype._collectChildResults = function _collectChildResults(opts, cb) {

  var self = this,
      intermediateResults = [],
      i = 0;

  if(!opts || opts.length === 0) return cb(null, {});

  // Run the operations and any child operations in series so that each can access the
  // results of the previous operation.
  async.eachSeries(opts, function(opt, next) {
    self._runChildOperations(intermediateResults, opt, function(err, values) {
      if(err) return next(err);

      // If there are multiple operations and we are on the first one lets put the results
      // into an intermediate results array
      if(opts.length > 1 && i === 0) {
        intermediateResults = intermediateResults.concat(values);
      }

      // Add values to the cache key
      self.cache[opt.collection] = self.cache[opt.collection] || [];
      self.cache[opt.collection] = self.cache[opt.collection].concat(values);

      // Ensure the values are unique
      var pk = self._findCollectionPK(opt.collection);
      self.cache[opt.collection] = _.uniq(self.cache[opt.collection], pk);

      i++;
      next();
    });
  }, cb);

};

/**
 * Run A Child Operation
 *
 * Executes a child operation and appends the results as a namespaced object to the
 * main operation results object.
 *
 * @param {Object} optResults
 * @param {Object} opt
 * @param {Function} callback
 * @api private
 */

Operations.prototype._runChildOperations = function _runChildOperations(intermediateResults, opt, cb) {
  var self = this;

  // Check if value has a parent, if so a join table was used and we need to build up dictionary
  // values that can be used to join the parent and the children together.

  // If the operation doesn't have a parent operation run it
  if(!hasOwnProperty(opt, 'parent')) {
    return self._runOperation(opt.collection, opt.method, opt.criteria, function(err, values) {
      if(err) return cb(err);
      cb(null, values);
    });
  }

  // If the operation has a parent, look into the optResults and build up a criteria
  // object using the results of a previous operation
  var parents = [];

  // Normalize to array
  var res = _.cloneDeep(intermediateResults);

  // Build criteria that can be used with an `in` query
  res.forEach(function(result) {
    parents.push(result[opt.join.parentKey]);
  });

  var criteria = {};
  criteria[opt.join.childKey] = parents;

  // Check if the join contains any criteria
  if(opt.join.criteria) {
    var userCriteria = _.cloneDeep(opt.join.criteria);

    // Ensure `where` criteria is properly formatted
    if(hasOwnProperty(userCriteria, 'where')) {
      if(userCriteria.where === undefined) {
        delete userCriteria.where;
      }
      else {
        userCriteria = userCriteria.where;
      }
    }

    delete userCriteria.sort;
    criteria = _.extend(criteria, userCriteria);
  }

  criteria = normalize.criteria({ where: criteria });

  // Empty the cache for the join table so we can only add values used
  var cacheCopy = _.cloneDeep(self.cache[opt.join.parent]);
  self.cache[opt.join.parent] = [];

  self._runOperation(opt.collection, opt.method, criteria, function(err, values) {
    if(err) return cb(err);

    // Build up the new join table result
    values.forEach(function(val) {
      cacheCopy.forEach(function(copy) {
        if(copy[opt.join.parentKey] === val[opt.join.childKey]) self.cache[opt.join.parent].push(copy);
      });
    });

    // Ensure the values are unique
    var pk = self._findCollectionPK(opt.join.parent);
    self.cache[opt.join.parent] = _.uniq(self.cache[opt.join.parent], pk);

    cb(null, values);
  });
};

/**
 * Find A Collection's Primary Key
 *
 * @param {String} collectionName
 * @api private
 * @return {String}
 */

Operations.prototype._findCollectionPK = function _findCollectionPK(collectionName) {
  var pk;

  for(var attribute in this.context.waterline.collections[collectionName]._attributes) {
    var attr = this.context.waterline.collections[collectionName]._attributes[attribute];
    if(hasOwnProperty(attr, 'primaryKey') && attr.primaryKey) {
      pk = attr.columnName || attribute;
      break;
    }
  }

  return pk || null;
};

},{"../../utils/helpers":70,"../../utils/normalize":76,"async":"async","lodash":"lodash"}],55:[function(require,module,exports){
/**
 * Dependencies
 */

var _ = require('lodash'),
    extend = require('../utils/extend'),
    AdapterBase = require('../adapter'),
    utils = require('../utils/helpers'),
    AdapterMixin = require('./adapters'),
    hop = utils.object.hasOwnProperty;

/**
 * Query
 */

var Query = module.exports = function() {

  // Create a reference to an internal Adapter Base
  this.adapter = new AdapterBase({
    connections: this.connections,
    query: this,
    collection: this.tableName || this.identity,
    identity: this.identity,
    dictionary: this.adapterDictionary
  });

  // Mixin Custom Adapter Functions.
  AdapterMixin.call(this);

  // Generate Dynamic Finders
  this.buildDynamicFinders();
};



/**
 * Automigrate
 *
 * @param  {Function} cb
 */
Query.prototype.sync = function(cb) {
  var self = this;

  // If any adapters used in this collection have syncable turned off set migrate to safe.
  //
  // I don't think a collection would ever need two adapters where one needs migrations and
  // the other doesn't but it may be a possibility. The way the auto-migrations work now doesn't
  // allow for this either way so this should be good. We will probably need to revist this soonish
  // however and take a pass at getting something working for better migration systems.
  // - particlebanana

  _.keys(this.connections).forEach(function(connectionName) {
    var adapter = self.connections[connectionName]._adapter;

    // If not syncable, don't sync
    if (hop(adapter, 'syncable') && !adapter.syncable) {
      self.migrate = 'safe';
    }
  });

  // Assign synchronization behavior depending on migrate option in collection
  if(this.migrate && ['drop', 'alter', 'safe'].indexOf(this.migrate) > -1) {

    // Determine which sync strategy to use
    var strategyMethodName = 'migrate' + utils.capitalize(this.migrate);

    // Run automigration strategy
    this.adapter[strategyMethodName](function(err) {
      if(err) return cb(err);
      cb();
    });
  }

  // Throw Error
  else cb(new Error('Invalid `migrate` strategy defined for collection. Must be one of the following: drop, alter, safe'));
};


_.extend(
  Query.prototype,
  require('./validate'),
  require('./ddl'),
  require('./dql'),
  require('./aggregate'),
  require('./composite'),
  require('./finders/basic'),
  require('./finders/helpers'),
  require('./finders/dynamicFinders'),
  require('./stream')
);

// Make Extendable
Query.extend = extend;

},{"../adapter":5,"../utils/extend":68,"../utils/helpers":70,"./adapters":39,"./aggregate":40,"./composite":41,"./ddl":42,"./dql":47,"./finders/basic":50,"./finders/dynamicFinders":51,"./finders/helpers":52,"./stream":62,"./validate":63,"lodash":"lodash"}],56:[function(require,module,exports){
/**
 * Module dependencies
 */
var anchor = require('anchor'),
  _ = require('lodash'),
  partialJoin = require('./_partialJoin');


/**
 * _join
 *
 * @api private
 *
 * Helper method- can perform and inner -OR- outer join.
 *
 * @option {String|Boolean} outer    [whether to do an outer join, and if so the direction ("left"|"right")]
 * @option {Array} parent            [rows from the "lefthand table"]
 * @option {Array} child             [rows from the "righthand table"]
 * @option {String} parentKey        [primary key of the "lefthand table"]
 * @option {String} childKey         [foreign key from the "righthand table" to the "lefthand table"]
 * @option {String} childNamespace   [string prepended to child attribute keys (default='.')]
 *
 * @return {Array} new joined row data
 *
 * @throws {Error} on invalid input
 *
 * @synchronous
 */
module.exports = function _join(options) {


  // Usage
  var invalid = false;
  invalid = invalid || anchor(options).to({
    type: 'object'
  });

  // Tolerate `right` and `left` usage
  _.defaults(options, {
    parent: options.left,
    child: options.right,
    parentKey: options.leftKey,
    childKey: options.rightKey,
    childNamespace: options.childNamespace || '.',
  });

  invalid = invalid || anchor(options.parent).to({
    type: 'array'
  });
  invalid = invalid || anchor(options.child).to({
    type: 'array'
  });
  invalid = invalid || anchor(options.parentKey).to({
    type: 'string'
  });
  invalid = invalid || anchor(options.childKey).to({
    type: 'string'
  });

  invalid = invalid || (options.outer === 'right' ?
    new Error('Right joins not supported yet.') : false);

  if (invalid) throw invalid;




  var resultSet = _.reduce(options.parent, function eachParentRow (memo, parentRow) {

    // For each childRow whose childKey matches
    // this parentRow's parentKey...
    var foundMatch = _.reduce(options.child, function eachChildRow (hasFoundMatchYet, childRow) {

      var newRow = partialJoin({
        parentRow: parentRow,
        childRow: childRow,
        parentKey: options.parentKey,
        childKey: options.childKey,
        childNamespace: options.childNamespace
      });

      // console.log('PARENT ROW: ', parentRow);
      // console.log('CHILD ROW: ', childRow);
      // console.log('JOIN ROW: ', newRow);

      // Save the new row for the join result if it exists
      // and mark the match as found
      if (newRow) {
        memo.push(newRow);
        return true;
      }
      return hasFoundMatchYet;
    }, false);

    // If this is a left outer join and we didn't find a match
    // for this parentRow, add it to the result set anyways
    if ( !foundMatch && options.outer === 'left') {
        memo.push(_.cloneDeep(parentRow));
    }

    return memo;
  }, []);

  // console.log('JOIN RESULT SET::', resultSet);
  return resultSet;

};

},{"./_partialJoin":57,"anchor":83,"lodash":"lodash"}],57:[function(require,module,exports){
/**
 * Module dependencies
 */
var assert = require('assert'),
  _ = require('lodash');



/**
 * _partialJoin
 *
 * @api private
 *
 * Check whether two rows match on the specified keys,
 * and if they do, merge `parentRow` into a copy of `childRow`
 * and return it (omit `childRow`'s key, since it === `parentRow`'s).
 *
 * Hypothetically, this function could be operated by a stream,
 * but in the case of a left outer join, at least, the final
 * result set cannot be accurately known until both the complete
 * contents of both the `left` and `right` data set have been checked.
 *
 * An optimization from polynomial to logarithmic computational
 * complexity could potentially be achieved by taking advantage
 * of the known L[k..l] and R[m..n] values as each new L[i] or R[j]
 * arrives from a stream, but a comparably-sized cache would have to
 * be maintained, so we'd still be stuck with polynomial memory usage.
 * i.e. O( |R|*|L| )  This could be resolved by batching-- e.g. grab the
 * first 3000 parent and child rows, join matches together, discard
 * the unneeded data, and repeat.
 *
 * Anyways, worth investigating, since this is a hot code path for
 * cross-adapter joins.
 *
 *
 * Usage:
 *
 * partialJoin({
 *   parentRow: { id: 5, name: 'Lucy', email: 'lucy@fakemail.org' }
 *   childRow:  { owner_id: 5, name: 'Rover', breed: 'Australian Shepherd' }
 *   parentKey: 'id'
 *   childKey:  'owner_id',
 *   childNamespace:  '.'
 * })
 *
 * @param  {Object} options
 * @return {Object|False}   If false, don't save the join row.
 * @synchronous
 */
module.exports = function partialJoin (options) {

  // Usage
  var invalid = false;
  invalid = invalid || !_.isObject(options);
  invalid = invalid || !_.isString(options.parentKey);
  invalid = invalid || !_.isString(options.childKey);
  invalid = invalid || !_.isObject(options.parentRow);
  invalid = invalid || !_.isObject(options.childRow);
  assert(!invalid);

  var CHILD_ATTR_PREFIX = (options.childNamespace || '.');

  // If the rows aren't a match, bail out
  if (
    options.childRow[options.childKey] !==
    options.parentRow[options.parentKey]
    ) {
    return false;
  }

  // deep clone the childRow, then delete `childKey` in the copy.
  var newJoinRow = _.cloneDeep(options.childRow);
  // console.log('deleting childKEy :: ',options.childKey);
  // var _childKeyValue = newJoinRow[options.childKey];
  // delete newJoinRow[options.childKey];

  // namespace the remaining attributes in childRow
  var namespacedJoinRow = {};
  _.each(newJoinRow, function (value, key) {
    var namespacedKey = CHILD_ATTR_PREFIX + key;
    namespacedJoinRow[namespacedKey] = value;
  });


  // Merge namespaced values from current parentRow into the copy.
  _.merge(namespacedJoinRow, options.parentRow);


  // Return the newly joined row.
  return namespacedJoinRow;
};


},{"assert":"assert","lodash":"lodash"}],58:[function(require,module,exports){
/**
 * Module dependencies
 */
var anchor = require('anchor');
var _ = require('lodash');
var leftOuterJoin = require('./leftOuterJoin');
var innerJoin = require('./innerJoin');
var populate = require('./populate');



/**
 * Query Integrator
 *
 * Combines the results from multiple child queries into
 * the final return format using an in-memory join.
 * Final step in fulfilling a `.find()` with one or more
 * `populate(alias[n])` modifiers.
 *
 *    > Why is this asynchronous?
 *    >
 *    > While this function isn't doing anything strictly
 *    > asynchronous, it still expects a callback to enable
 *    > future use of `process[setImmediate|nextTick]()` as
 *    > an optimization.
 *
 * @param  {Object}   cache
 * @param  {Array}    joinInstructions      - see JOIN_INSTRUCTIONS.md
 * @callback  {Function} cb(err, results)
 *           @param {Error}
 *           @param {Array}  [results, complete w/ populations]
 *
 * @throws {Error} on invalid input
 * @asynchronous
 */
module.exports = function integrate(cache, joinInstructions, primaryKey, cb) {

  // Ensure valid usage
  var invalid = false;
  invalid = invalid || anchor(cache).to({ type: 'object' });
  invalid = invalid || anchor(joinInstructions).to({ type: 'array' });
  invalid = invalid || anchor(joinInstructions[0]).to({ type: 'object' });
  invalid = invalid || anchor(joinInstructions[0].parent).to({ type: 'string' });
  invalid = invalid || anchor(cache[joinInstructions[0].parent]).to({ type: 'object' });
  invalid = invalid || typeof primaryKey !== 'string';
  invalid = invalid || typeof cb !== 'function';
  if (invalid) return cb(invalid);


  // Constant: String prepended to child attribute keys for use in namespacing.
  var CHILD_ATTR_PREFIX = '.';
  var GRANDCHILD_ATTR_PREFIX = '..';


  // We'll reuse the cached data from the `parent` table modifying it in-place
  // and returning it as our result set. (`results`)
  var results = cache[ joinInstructions[0].parent ];

  // Group the joinInstructions array by alias, then interate over each one
  // s.t. `instructions` in our lambda function contains a list of join instructions
  // for the particular `populate` on the specified key (i.e. alias).
  //
  // Below, `results` are mutated inline.
  _.each( _.groupBy(joinInstructions, 'alias'),
    function eachAssociation( instructions, alias ) {

      var parentPK, fkToParent, fkToChild, childPK;

      var childSelect;

      // N..N Association
      if ( instructions.length === 2 ) {

        // Name keys explicitly
        // (makes it easier to see what's going on)
        parentPK = instructions[0].parentKey;
        fkToParent = instructions[0].childKey;
        fkToChild = instructions[1].parentKey;
        childPK = instructions[1].childKey;

        // Modifiers
        childSelect = instructions[1].select;

        // Prefix target child attributes
        childSelect = _.map(childSelect, function (attr) {
          return GRANDCHILD_ATTR_PREFIX + attr;
        });

        // console.log('\n\n------------:: n..m leftOuterJoin ::--------\n',
        //   leftOuterJoin({
        //     left: cache[instructions[0].parent],
        //     right: cache[instructions[0].child],
        //     leftKey: parentPK,
        //     rightKey: fkToParent
        //   })
        // );
        // console.log('------------:: / ::--------\n');

        // console.log('\n\n------------:: n..m childRows ::--------\n',innerJoin({
        //   left: leftOuterJoin({
        //     left: cache[instructions[0].parent],
        //     right: cache[instructions[0].child],
        //     leftKey: parentPK,
        //     rightKey: fkToParent
        //   }),
        //   right: cache[instructions[1].child],
        //   leftKey: CHILD_ATTR_PREFIX+fkToChild,
        //   rightKey: childPK,
        //   childNamespace: GRANDCHILD_ATTR_PREFIX
        // }));
        // console.log('------------:: / ::--------\n');

        // Calculate and sanitize join data,
        // then shove it into the parent results under `alias`
        populate({
          parentRows: results,
          alias: alias,

          childRows: innerJoin({
            left: leftOuterJoin({
              left: cache[instructions[0].parent],
              right: cache[instructions[0].child],
              leftKey: parentPK,
              rightKey: fkToParent
            }),
            right: cache[instructions[1].child],
            leftKey: CHILD_ATTR_PREFIX+fkToChild,
            rightKey: childPK,
            childNamespace: GRANDCHILD_ATTR_PREFIX
          }),

          parentPK: parentPK,   // e.g. `id` (of message)
          fkToChild: CHILD_ATTR_PREFIX+fkToChild, // e.g. `user_id` (of join table)
          childPK: GRANDCHILD_ATTR_PREFIX+childPK,      // e.g. `id` (of user)

          select: childSelect,
          childNamespace: GRANDCHILD_ATTR_PREFIX
        });
      }

      // 1..N Association
      else if ( instructions.length === 1 ) {

        // Name keys explicitly
        // (makes it easier to see what's going on)
        parentPK = primaryKey;
        fkToParent = parentPK;
        fkToChild = instructions[0].parentKey;
        childPK = instructions[0].childKey;

        // Determine if this is a "hasOne" or a "belongsToMany"
        // if the parent's primary key is the same as the fkToChild, it must be belongsToMany
        if (parentPK === fkToChild) {
          // In belongsToMany case, fkToChild needs prefix because it's actually the
          // console.log('belongsToMany');
          fkToChild = CHILD_ATTR_PREFIX + fkToChild;
        }
        // "hasOne" case
        else {
          // console.log('hasOne');
        }

        // Modifiers
        childSelect = instructions[0].select;

        // Prefix target child attributes
        childSelect = _.map(childSelect, function (attr) {
          return CHILD_ATTR_PREFIX + attr;
        });
        // console.log('childSelect', childSelect);

        // var childRows = innerJoin({
        //   left: cache[instructions[0].parent],
        //   right: cache[instructions[0].child],
        //   leftKey: instructions[0].parentKey,
        //   rightKey: instructions[0].childKey
        // });

        // console.log('1..N JOIN--------------\n',instructions,'\n^^^^^^^^^^^^^^^^^^^^^^');
        // console.log('1..N KEYS--------------\n',{
        //   parentPK: parentPK,
        //   fkToParent: fkToParent,
        //   fkToChild: fkToChild,
        //   childPK: childPK,
        // },'\n^^^^^^^^^^^^^^^^^^^^^^');
        // console.log('1..N CHILD ROWS--------\n',childRows);

        // Calculate and sanitize join data,
        // then shove it into the parent results under `alias`
        populate({
          parentRows: results,
          alias: alias,

          childRows: innerJoin({
            left: cache[instructions[0].parent],
            right: cache[instructions[0].child],
            leftKey: instructions[0].parentKey,
            rightKey: instructions[0].childKey
          }),

          parentPK: fkToParent,  // e.g. `id` (of message)
          fkToChild: fkToChild,  // e.g. `from`
          childPK: childPK,      // e.g. `id` (of user)

          select: childSelect,
          childNamespace: CHILD_ATTR_PREFIX
        });
        // console.log('1..N Results--------\n',results);
      }

    }
  );


  // And call the callback
  // (the final joined data is in the cache -- also referenced by `results`)
  return cb(null, results);

};




},{"./innerJoin":59,"./leftOuterJoin":60,"./populate":61,"anchor":83,"lodash":"lodash"}],59:[function(require,module,exports){
/**
 * Module dependencies
 */
var join = require('./_join');


/**
 * Inner join
 *
 * Return a result set with data from child and parent
 * merged on childKey===parentKey, where t.e. exactly one
 * entry for each match.
 *
 * @option {Array} parent    [rows from the "lefthand table"]
 * @option {Array} child   [rows from the "righthand table"]
 * @option {String} parentKey     [primary key of the "lefthand table"]
 * @option {String} childKey     [foreign key from the "righthand table" to the "lefthand table"]
 * @return {Array}          [a new array of joined row data]
 *
 * @throws {Error} on invalid input
 * @synchronous
 */
module.exports = function leftOuterJoin(options) {
  options.outer = false;
  return join(options);
};

},{"./_join":56}],60:[function(require,module,exports){
/**
 * Module dependencies
 */
var join = require('./_join');


/**
 * Left outer join
 *
 * Return a result set with data from child and parent
 * merged on childKey===parentKey, where t.e. at least one
 * entry for each row of parent (unmatched columns in child are null).
 *
 * @option {Array} parent       [rows from the "lefthand table"]
 * @option {Array} child        [rows from the "righthand table"]
 * @option {String} parentKey   [primary key of the "lefthand table"]
 * @option {String} childKey    [foreign key from the "righthand table" to the "lefthand table"]
 * @return {Array}              [a new array of joined row data]
 *
 * @throws {Error} on invalid input
 * @synchronous
 */
module.exports = function leftOuterJoin(options) {
  options.outer = 'left';
  return join(options);
};

},{"./_join":56}],61:[function(require,module,exports){
/**
 * Module dependencies
 */
var _ = require('lodash');



/**
 * populate()
 *
 * Destructive mapping of `parentRows` to include a new key, `alias`,
 * which is an ordered array of child rows.
 *
 * @option [{Object}] parentRows    - the parent rows the joined rows will be folded into
 * @option {String} alias           - the alias of the association
 * @option [{Object}] childRows     - the unfolded result set from the joins
 *
 * @option {String} parentPK        - the primary key of the parent table (optional- only needed for M..N associations)
 * @option {String} fkToChild       - the foreign key associating a row with the child table
 * @option {String} childPK         - the primary key of the child table
 *
 * @option [{String}] select        - attributes to keep
 * @option [{String}] childNamespace- attributes to keep
 *
 * @return {*Object} reference to `parentRows`
 */
module.exports = function populate (options) {

  var parentRows = options.parentRows;
  var alias = options.alias;
  var childRows = options.childRows;

  var parentPK = options.parentPK;
  var childPK = options.childPK;
  var fkToChild = options.fkToChild;
  var fkToParent = parentPK;// At least for all use cases currently, `fkToParent` <=> `parentPK`

  var select = options.select;
  var childNamespace = options.childNamespace || '';

  return _.map(parentRows, function _insertJoinedResults (parentRow) {

    // Gather the subset of child rows associated with the current parent row
    var associatedChildRows = _.where(childRows,
      //{ (parentPK): (parentRow[(parentPK)]) }, e.g. { id: 3 }
      _cons(fkToParent, parentRow[parentPK])
    );

    // Clone the `associatedChildRows` to avoid mutating the original
    // `childRows` in the cache.
    associatedChildRows = _.cloneDeep(associatedChildRows);

    // Stuff the sanitized associated child rows into the parent row.
    parentRow[alias] =
    _.reduce(associatedChildRows, function (memo, childRow) {

      // Ignore child rows without an appropriate foreign key
      // to an instance in the REAL child collection.
      if (!childRow[childNamespace + childPK] && !childRow[childPK]) return memo;

      // Rename childRow's [fkToChild] key to [childPK]
      // (so that it will have the proper primary key attribute for its collection)
      var childPKValue = childRow[fkToChild];
      childRow[childPK] = childPKValue;

      // If specified, pick a subset of attributes from child row
      if (select) {
        childRow = _.pick(childRow, select);
        var _origChildRow = childRow;

        // Strip off childNamespace prefix
        childRow = {};
        var PREFIX_REGEXP = new RegExp('^' + childNamespace + '');
        _.each(_origChildRow, function (attrValue, attrName) {
          var unprefixedKey = attrName.replace(PREFIX_REGEXP, '');
          // console.log('unprefixedKey',unprefixedKey,attrName);
          childRow[unprefixedKey] = attrValue;
        });
      }

      // Build the set of rows to stuff into our parent row.
      memo.push(childRow);
      return memo;
    }, []);

    return parentRow;
  });
};




/**
 * Dumb little helper because I hate naming anonymous objects just to use them once.
 *
 * @return {Object} [a tuple]
 * @api private
 */
function _cons(key, value) {
  var obj = {};
  obj[key] = value;
  return obj;
}





},{"lodash":"lodash"}],62:[function(require,module,exports){
(function (process){
/**
 * Streaming Queries
 */

var usageError = require('../utils/usageError'),
    utils = require('../utils/helpers'),
    normalize = require('../utils/normalize'),
    ModelStream = require('../utils/stream');

module.exports = {

  /**
   * Stream a Result Set
   *
   * @param {Object} criteria
   * @param {Object} transformation, defaults to JSON
   */

  stream: function (criteria, transformation) {
    var self = this;

    var usage = utils.capitalize(this.identity) + '.stream([criteria],[options])';

    // Normalize criteria and fold in options
    criteria = normalize.criteria(criteria);

    // Transform Search Criteria
    criteria = self._transformer.serialize(criteria);

    // Configure stream to adapter, kick off fetch, and return stream object
    // so that user code can use it as it fires data events
    var stream = new ModelStream(transformation);

    // very important to wait until next tick before triggering adapter
    // otherwise write() and end() won't fire properly
    process.nextTick(function (){

      // Write once immediately to force prefix in case no models are returned
      stream.write();

      // Trigger Adapter Method
      self.adapter.stream(criteria, stream);
    });

    return stream;
  }

};

}).call(this,require('_process'))
},{"../utils/helpers":70,"../utils/normalize":76,"../utils/stream":79,"../utils/usageError":82,"_process":117}],63:[function(require,module,exports){
/**
 * Validation
 *
 * Used in create and update methods validate a model
 * Can also be used independently
 */

var _ = require('lodash'),
    WLValidationError = require('../error/WLValidationError'),
    async = require('async');

module.exports = {

  validate: function(values, presentOnly, cb) {
    var self = this;

    //Handle optional second arg
    if (typeof presentOnly === 'function') {
      cb = presentOnly;
    }

    async.series([

      // Run Before Validate Lifecycle Callbacks
      function(cb) {
        var runner = function(item, callback) {
          item(values, function(err) {
            if(err) return callback(err);
            callback();
          });
        };

        async.eachSeries(self._callbacks.beforeValidate, runner, function(err) {
          if(err) return cb(err);
          cb();
        });
      },

      // Run Validation
      function(cb) {
        self._validator.validate(values, presentOnly === true, function(invalidAttributes) {

          // Create validation error here
          // (pass in the invalid attributes as well as the collection's globalId)
          if(invalidAttributes) return cb(new WLValidationError({
            invalidAttributes: invalidAttributes,
            model: self.globalId
          }));

          cb();
        });
      },

      // Run After Validate Lifecycle Callbacks
      function(cb) {
        var runner = function(item, callback) {
          item(values, function(err) {
            if(err) return callback(err);
            callback();
          });
        };

        async.eachSeries(self._callbacks.afterValidate, runner, function(err) {
          if(err) return cb(err);
          cb();
        });
      }

    ], function(err) {
      if(err) return cb(err);
      cb();
    });
  }

}

},{"../error/WLValidationError":24,"async":"async","lodash":"lodash"}],64:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');



/**
 * Traverse the shema to build a populate plan object
 * that will populate every relation, sub-relation, and so on
 * reachable from the initial model and relation at least once
 * (perhaps most notable is that this provides access to most
 * related data without getting caught in loops.)
 *
 * @param  {[type]} schema          [description]
 * @param  {[type]} initialModel    [description]
 * @param  {[type]} initialRelation [description]
 * @return {[type]}                 [description]
 */
module.exports = function acyclicTraversal(schema, initialModel, initialRelation) {

	// Track the edges which have already been traversed
	var alreadyTraversed = [
		// {
		//   relation: initialRelation,
		//   model: initialModel
		// }
	];

	return traverseSchemaGraph(initialModel, initialRelation);

	/**
	 * Recursive function
	 * @param  {[type]} modelIdentity  [description]
	 * @param  {[type]} nameOfRelation [description]
	 * @return {[type]}                [description]
	 */
	function traverseSchemaGraph(modelIdentity, nameOfRelation) {

		var currentModel = schema[modelIdentity];
		var currentAttributes = currentModel.attributes;

		var isRedundant;

		// If this relation has already been traversed, return.
		// (i.e. `schema.attributes.modelIdentity.nameOfRelation`)
		isRedundant = _.findWhere(alreadyTraversed, {
			alias: nameOfRelation,
			model: modelIdentity
		});
				
		if (isRedundant) return;

		// Push this relation onto the `alreadyTraversed` stack.
		alreadyTraversed.push({
			alias: nameOfRelation,
			model: modelIdentity
		});


		var relation = currentAttributes[nameOfRelation];
		if (!relation) throw new Error('Unknown relation in schema: ' + modelIdentity + '.' + nameOfRelation);
		var identityOfRelatedModel = relation.model || relation.collection;

		// Get the related model
		var relatedModel = schema[identityOfRelatedModel];

		// If this relation is a collection with a `via` back-reference,
		// push it on to the `alreadyTraversed` stack.
		// (because the information therein is probably redundant)
		// TODO: evaluate this-- it may or may not be a good idea
		// (but I think it's a nice touch)
		if (relation.via) {
			alreadyTraversed.push({
				alias: relation.via,
				model: identityOfRelatedModel
			});
		}

		// Lookup ALL the relations OF THE RELATED model.
		var relations =
			_(relatedModel.attributes).reduce(function buildSubsetOfAssociations(relations, attrDef, attrName) {
				if (_.isObject(attrDef) && (attrDef.model || attrDef.collection)) {
					relations.push(_.merge({
						alias: attrName,
						identity: attrDef.model || attrDef.collection,
						cardinality: attrDef.model ? 'model' : 'collection'
					}, attrDef));
					return relations;
				}
				return relations;
			}, []);

		// Return a piece of the result plan by calling `traverseSchemaGraph`
		// on each of the RELATED model's relations.
		return _.reduce(relations, function (resultPlanPart, relation) {

			// Recursive step
			resultPlanPart[relation.alias] = traverseSchemaGraph(identityOfRelatedModel, relation.alias);

			// Trim undefined result plan parts
			if (resultPlanPart[relation.alias] === undefined) {
				delete resultPlanPart[relation.alias];
			}

			return resultPlanPart;
		}, {});
	}

};
},{"lodash":"lodash"}],65:[function(require,module,exports){
/**
 * Lifecycle Callbacks Allowed
 */

module.exports = [
  'beforeValidate',
  'afterValidate',
  'beforeUpdate',
  'afterUpdate',
  'beforeCreate',
  'afterCreate',
  'beforeDestroy',
  'afterDestroy'
];

},{}],66:[function(require,module,exports){
/**
 * Module Dependencies
 */

var async = require('async');

/**
 * Run Lifecycle Callbacks
 */

var runner = module.exports = {};


/**
 * Run Validation Callbacks
 *
 * @param {Object} context
 * @param {Object} values
 * @param {Boolean} presentOnly
 * @param {Function} cb
 * @api public
 */

runner.validate = function(context, values, presentOnly, cb) {
  context.validate(values, presentOnly, cb);
};


/**
 * Run Before Create Callbacks
 *
 * @param {Object} context
 * @param {Object} values
 * @param {Function} cb
 * @api public
 */

runner.beforeCreate = function(context, values, cb) {

  var fn = function(item, next) {
    item.call(Object.getPrototypeOf(context), values, next);
  };

  async.eachSeries(context._callbacks.beforeCreate, fn, cb);
};


/**
 * Run After Create Callbacks
 *
 * @param {Object} context
 * @param {Object} values
 * @param {Function} cb
 * @api public
 */

runner.afterCreate = function(context, values, cb) {

  var fn = function(item, next) {
    item.call(Object.getPrototypeOf(context), values, next);
  };

  async.eachSeries(context._callbacks.afterCreate, fn, cb);
};


/**
 * Run Before Update Callbacks
 *
 * @param {Object} context
 * @param {Object} values
 * @param {Function} cb
 * @api public
 */

runner.beforeUpdate = function(context, values, cb) {

  var fn = function(item, next) {
    item.call(Object.getPrototypeOf(context), values, next);
  };

  async.eachSeries(context._callbacks.beforeUpdate, fn, cb);
};


/**
 * Run After Update Callbacks
 *
 * @param {Object} context
 * @param {Object} values
 * @param {Function} cb
 * @api public
 */

runner.afterUpdate = function(context, values, cb) {

  var fn = function(item, next) {
    item.call(Object.getPrototypeOf(context), values, next);
  };

  async.eachSeries(context._callbacks.afterUpdate, fn, cb);
};


/**
 * Run Before Destroy Callbacks
 *
 * @param {Object} context
 * @param {Object} criteria
 * @param {Function} cb
 * @api public
 */

runner.beforeDestroy = function(context, criteria, cb) {

  var fn = function(item, next) {
    item.call(Object.getPrototypeOf(context), criteria, next);
  };

  async.eachSeries(context._callbacks.beforeDestroy, fn, cb);
};


/**
 * Run After Destroy Callbacks
 *
 * @param {Object} context
 * @param {Object} values
 * @param {Function} cb
 * @api public
 */

runner.afterDestroy = function(context, values, cb) {

  var fn = function(item, next) {
    item.call(Object.getPrototypeOf(context), values, next);
  };

  async.eachSeries(context._callbacks.afterDestroy, fn, cb);
};

},{"async":"async"}],67:[function(require,module,exports){
var Promise = require('bluebird');

module.exports = function defer() {
  var resolve, reject;

  var promise = new Promise(function() {
    resolve = arguments[0];
    reject = arguments[1];
  });

  return {
    resolve: resolve,
    reject: reject,
    promise: promise
  };
};

},{"bluebird":"bluebird"}],68:[function(require,module,exports){
/**
 * Extend Method
 *
 * Taken from Backbone Source:
 * http://backbonejs.org/docs/backbone.html#section-189
 */

var _ = require('lodash');

module.exports = function(protoProps, staticProps) {
  var parent = this;
  var child;

  if (protoProps && _.has(protoProps, 'constructor')) {
    child = protoProps.constructor;
  } else {
    child = function(){ return parent.apply(this, arguments); };
  }

  _.extend(child, parent, staticProps);

  var Surrogate = function(){ this.constructor = child; };
  Surrogate.prototype = parent.prototype;
  child.prototype = new Surrogate();

  if (protoProps) _.extend(child.prototype, protoProps);

  child.__super__ = parent.prototype;

  return child;
};

},{"lodash":"lodash"}],69:[function(require,module,exports){
/**
 * getRelations
 *
 * Find any `junctionTables` that reference the parent collection.
 * 
 * @param  {[type]} options [description]
 *    @option parentCollection
 *    @option schema
 * @return {[type]}         [relations]
 */

module.exports = function getRelations(options) {

  var schema = options.schema;
  var relations = [];

  Object.keys(schema).forEach(function(collection) {
    var collectionSchema = schema[collection];
    if (!collectionSchema.hasOwnProperty('junctionTable')) return;

    Object.keys(collectionSchema.attributes).forEach(function(key) {
      if (!collectionSchema.attributes[key].hasOwnProperty('foreignKey')) return;
      if (collectionSchema.attributes[key].references !== options.parentCollection) return;
      relations.push(collection);
    });
  });

  return relations;
};

},{}],70:[function(require,module,exports){

/**
 * Module Dependencies
 */

var _ = require('lodash');

/**
 * Equivalent to _.objMap, _.map for objects, keeps key/value associations
 *
 * Should be deprecated.
 *
 * @api public
 */
exports.objMap = function objMap(input, mapper, context) {
  return _.reduce(input, function(obj, v, k) {
    obj[k] = mapper.call(context, v, k, input);
    return obj;
  }, {}, context);
};

/**
 * Run a method meant for a single object on a object OR array
 * For an object, run the method and return the result.
 * For a list, run the method on each item return the resulting array.
 * For anything else, return it silently.
 *
 * Should be deprecated.
 *
 * @api public
 */

exports.pluralize = function pluralize(collection, application) {
  if(Array.isArray(collection)) return _.map(collection, application);
  if(_.isObject(collection)) return application(collection);
  return collection;
};

/**
 * _.str.capitalize
 *
 * @param {String} str
 * @return {String}
 * @api public
 */

exports.capitalize = function capitalize(str) {
  str = str === null ? '' : String(str);
  return str.charAt(0).toUpperCase() + str.slice(1);
};

/**
 * ignore
 */

exports.object = {};

/**
 * Safer helper for hasOwnProperty checks
 *
 * @param {Object} obj
 * @param {String} prop
 * @return {Boolean}
 * @api public
 */

var hop = Object.prototype.hasOwnProperty;
exports.object.hasOwnProperty = function(obj, prop) {
  if (obj === null) return false;
  return hop.call(obj, prop);
};

/**
 * Check if an ID resembles a Mongo BSON ID.
 * Can't use the `hop` helper above because BSON ID's will have their own hasOwnProperty value.
 *
 * @param {String} id
 * @return {Boolean}
 * @api public
 */

exports.matchMongoId = function matchMongoId(id) {
  // id must be truthy- and either BE a string, or be an object
  // with a toString method.
  if( !id ||
   ! (_.isString(id) || (_.isObject(id) || _.isFunction(id.toString)))
  ) return false;
  else return id.toString().match(/^[a-fA-F0-9]{24}$/) ? true : false;
};

},{"lodash":"lodash"}],71:[function(require,module,exports){
/**
 * Module Dependencies
 */

var _ = require('lodash');
var hasOwnProperty = require('../helpers').object.hasOwnProperty;

/**
 * Queue up .add() operations on a model instance for any nested association
 * values in a .create() query.
 *
 * @param {Object} parentModel
 * @param {Object} values
 * @param {Object} associations
 * @param {Function} cb
 * @api private
 */

module.exports = function(parentModel, values, associations, cb) {
  var self = this;

  // For each association, grab the primary key value and normalize into model.add methods
  associations.forEach(function(association) {
    var attribute = self.waterline.schema[self.identity].attributes[association];
    var modelName;

    if(hasOwnProperty(attribute, 'collection')) modelName = attribute.collection;

    if(!modelName) return;

    var pk = self.waterline.collections[modelName].primaryKey;

    var optValues = values[association];
    if(!optValues) return;
    if(!_.isArray(optValues)){
    	optValues = _.isString(optValues) ? optValues.split(',') : [optValues];
    }
    optValues.forEach(function(val) {

      // If value is not an object, queue up an add
      if(!_.isPlainObject(val)) return parentModel[association].add(val);

      // If value is an object, check if a primary key is defined
      if(hasOwnProperty(val, pk)) return parentModel[association].add(val[pk]);

      parentModel[association].add(val);
    });
  });

  // Save the parent model
  parentModel.save(cb);
};

},{"../helpers":70,"lodash":"lodash"}],72:[function(require,module,exports){
/**
 * Handlers for parsing nested associations within create/update values.
 */

module.exports = {
  reduceAssociations: require('./reduceAssociations'),
  valuesParser: require('./valuesParser'),
  create: require('./create'),
  update: require('./update')
};

},{"./create":71,"./reduceAssociations":73,"./update":74,"./valuesParser":75}],73:[function(require,module,exports){
/**
 * Module Dependencies
 */

var hop = require('../helpers').object.hasOwnProperty;
var _ = require('lodash');
var assert = require('assert');
var util = require('util');

/**
 * Traverse an object representing values replace associated objects with their
 * foreign keys.
 *
 * @param {String} model
 * @param {Object} schema
 * @param {Object} values
 * @return {Object}
 * @api private
 */


module.exports = function(model, schema, values) {

  Object.keys(values).forEach(function(key) {

    // Check to see if this key is a foreign key
    var attribute = schema[model].attributes[key];

    // If not a plainObject, check if this is a model instance and has a toObject method
    if(!_.isPlainObject(values[key])) {
      if(_.isObject(values[key]) && !Array.isArray(values[key]) && values[key].toObject && typeof values[key].toObject === 'function') {
        values[key] = values[key].toObject();
      } else {
        return;
      }
    }

    // Check that this user-specified value is not NULL
    if(values[key] === null) return;

    // Check that this user-specified value actually exists
    // as an attribute in `model`'s schema.
    // If it doesn't- just ignore it
    if (typeof attribute !== 'object') return;

    if(!hop(values[key], attribute.on)) return;
    var fk = values[key][attribute.on];
    values[key] = fk;
  });

  return values;
};

},{"../helpers":70,"assert":"assert","lodash":"lodash","util":"util"}],74:[function(require,module,exports){
/**
 * Module Dependencies
 */

var _ = require('lodash');
var async = require('async');
var hop = require('../helpers').object.hasOwnProperty;


/**
 * Update nested associations. Will take a values object and perform updating and
 * creating of all the nested associations. It's the same as syncing so it will first
 * remove any associations related to the parent and then "sync" the new associations.
 *
 * @param {Array} parents
 * @param {Object} values
 * @param {Object} associations
 * @param {Function} cb
 */

module.exports = function(parents, values, associations, cb) {

  var self = this;

  // Cache parents
  this.parents = parents;

  // Combine model and collection associations
  associations = associations.collections.concat(associations.models);

  // Build up .add and .update operations for each association
  var operations = buildOperations.call(self, associations, values);

  // Now that our operations are built, lets go through and run any updates.
  // Then for each parent, find all the current associations and remove them then add
  // all the new associations in using .add()
  sync.call(self, operations, cb);

};


/**
 * Build Up Operations (add and update)
 *
 * @param {Array} associations
 * @param {Object} values
 * @return {Object}
 */

function buildOperations(associations, values) {

  var self = this;
  var operations = {};

  // For each association, grab the primary key value and normalize into model.add methods
  associations.forEach(function(association) {

    var optValues = values[association];

    // If values are being nulled out just return. This is used when removing foreign
    // keys on the parent model.
    if(optValues === null) return;

    // Pull out any association values that have primary keys, these will need to be updated. All
    // values can be added for each parent however.
    operations[association] = {
      add: [],
      update: []
    };

    // Normalize optValues to an array
    if(!Array.isArray(optValues)) optValues = [optValues];
    queueOperations.call(self, association, operations[association], optValues);
  });

  return operations;
}

/**
 * Queue Up Operations.
 *
 * Takes the array normalized association values and queues up
 * operations for the specific association.
 *
 * @param {String} association
 * @param {Object} operation
 * @param {Array} values
 */

function queueOperations(association, operation, values) {

  var self = this;
  var attribute = self.waterline.schema[self.identity].attributes[association];
  var modelName;

  if(hop(attribute, 'collection')) modelName = attribute.collection;
  if(hop(attribute, 'foreignKey')) modelName = attribute.references;
  if(!modelName) return;

  var collection = self.waterline.collections[modelName];
  var modelPk = collection.primaryKey;

  // If this is a join table, we can just queue up operations on the parent
  // for this association.
  if(collection.junctionTable) {

    // For each parent, queue up any .add() operations
    self.parents.forEach(function(parent) {
      values.forEach(function(val) {
        if(!hop(parent, association)) return;
        if(typeof parent[association].add !== 'function') return;
        parent[association].add(val);
      });
    });

    return;
  }

  values.forEach(function(val) {

    // Check the values and see if the model's primary key is given. If so look into
    // the schema attribute and check if this is a collection or model attribute. If it's
    // a collection attribute lets update the child record and if it's a model attribute,
    // update the child and set the parent's foreign key value to the new primary key.
    if(!hop(val, modelPk)) {
      operation.add.push(val);
      return;
    }

    // Build up the criteria that will be used to update the child record
    var criteria = {};
    criteria[modelPk] = val[modelPk];

    // Queue up the update operation
    operation.update.push({ model: modelName, criteria: criteria, values: val });

    // Check if the parents foreign key needs to be updated
    if(!hop(attribute, 'foreignKey')) {
      operation.add.push(val[modelPk]);
      return;
    }

    // Set the new foreign key value for each parent
    self.parents.forEach(function(parent) {
      parent[association] = val[modelPk];
    });

  });
}

/**
 * Sync Associated Data
 *
 * Using the operations, lets go through and run any updates on any nested object with
 * primary keys. This ensures that all the data passed up is persisted. Then for each parent,
 * find all the current associations and unlink them and then add all the new associations
 * in using .add(). This ensures that whatever is passed in to an update is what the value will
 * be when queried again.
 *
 * @param {Object} operations
 * @param {Function} cb
 */

function sync(operations, cb) {
  var self = this;

  async.auto({

    // Update any nested associations
    update: function(next) {
      updateRunner.call(self, operations, next);
    },

    // For each parent, unlink all the associations currently set
    unlink: ['update', function(next) {
      unlinkRunner.call(self, operations, next);
    }],

    // For each parent found, link any associations passed in by either creating
    // the new record or linking an existing record
    link: ['unlink', function(next) {
      linkRunner.call(self, operations, next);
    }]

  }, cb);
}


////////////////////////////////////////////////////////////////////////////////////////
// .sync() - Async Auto Runners
////////////////////////////////////////////////////////////////////////////////////////


/**
 * Run Update Operations.
 *
 * Uses the information stored in an operation to perform a .update() on the
 * associated model using the new values.
 *
 * @param {Object} operation
 * @param {Function} cb
 */

function updateRunner(operations, cb) {

  var self = this;

  // There will be an array of update operations inside of a namespace. Use this to run
  // an update on the model instance of the association.
  function associationLoop(association, next) {
    async.each(operations[association].update, update, next);
  }

  function update(operation, next) {
    var model = self.waterline.collections[operation.model];
    model.update(operation.criteria, operation.values).exec(next);
  }

  // Operations are namespaced under an association key. So run each association's updates
  // in parallel for now. May need to be limited in the future but all adapters should
  // support connection pooling.
  async.each(Object.keys(operations), associationLoop, cb);

}


/**
 * Unlink Associated Records.
 *
 * For each association passed in to the update we are essentially replacing the
 * association's value. In order to do this we first need to clear out any associations
 * that currently exist.
 *
 * @param {Object} operations
 * @param {Function} cb
 */

function unlinkRunner(operations, cb) {

  var self = this;

  // Given a parent, build up remove operations and run them.
  function unlinkParentAssociations(parent, next) {
    var opts = buildParentRemoveOperations.call(self, parent, operations);
    removeOperationRunner.call(self, opts, next);
  }

  async.each(this.parents, unlinkParentAssociations, cb);
}


/**
 * Link Associated Records
 *
 * Given a set of operations, associate the records with the parent records. This
 * can be done by either creating join table records or by setting foreign keys.
 * It defaults to a parent.add() method for most situations.
 *
 * @param {Object} operations
 * @param {Function} cb
 */

function linkRunner(operations, cb) {

  var self = this;

  function linkChildRecords(parent, next) {

    // Queue up `.add()` operations on the parent model and figure out
    // which records need to be created.
    //
    // If an .add() method is available always use it. If this is a nested model an .add()
    // method won't be available so queue up a create operation.
    var recordsToCreate = buildParentLinkOperations.call(self, parent, operations);

    // Create the new records and update the parent with the new foreign key
    // values that may have been set when creating child records.
    createNewRecords.call(self, parent, recordsToCreate, function(err) {
      if(err) return next(err);
      updateParentRecord(parent, cb);
    });
  }

  // Update the parent record one last time. This ensures a model attribute (single object)
  // on the parent can create a new record and then set the parent's foreign key value to
  // the newly created child record's primary key.
  //
  // Example:
  // Parent.update({
  //   name: 'foo',
  //   nestedModel: {
  //     name: 'bar'
  //   }
  // })
  //
  // The above query would create the new nested model and then set the parent's nestedModel
  // value to the newly created model's primary key.
  //
  // We then run a .save() to persist any .add() records that may have been used. The update and
  // .save() are used instead of a find and then save because it's the same amount of queries
  // and it's easier to take advantage of all that the .add() method gives us.
  //
  //
  // TO-DO:
  // Make this much smarter to reduce the amount of queries that need to be run. We should probably
  // be able to at least cut this in half!
  //
  function updateParentRecord(parent, next) {

    var criteria = {};
    var model = self.waterline.collections[self.identity];

    criteria[self.primaryKey] = parent[self.primaryKey];
    var pValues = parent.toObject();

    model.update(criteria, pValues).exec(function(err) {
      if(err) return next(err);

      // Call .save() to persist any .add() functions that may have been used.
      parent.save(next);
    });
  }

  async.each(this.parents, linkChildRecords, cb);
}


////////////////////////////////////////////////////////////////////////////////////////
// .sync() - Helper Functions
////////////////////////////////////////////////////////////////////////////////////////


/**
 * Build up operations for performing unlinks.
 *
 * Given a parent and a set of operations, queue up operations to either
 * remove join table records or null out any foreign keys on an child model.
 *
 * @param {Object} parent
 * @param {Object} operations
 * @return {Array}
 */

function buildParentRemoveOperations(parent, operations) {

  var self = this;
  var opts = [];

  // Inspect the association and see if this relationship has a joinTable.
  // If so create an operation criteria that clears all matching records from the
  // table. If it doesn't have a join table, build an operation criteria that
  // nulls out the foreign key on matching records.
  Object.keys(operations).forEach(function(association) {

    var criteria = {};
    var searchCriteria = {};
    var attribute = self.waterline.schema[self.identity].attributes[association];

    /////////////////////////////////////////////////////////////////////////
    // Parent Record:
    // If the foreign key is stored on the parent side, null it out
    /////////////////////////////////////////////////////////////////////////

    if(hop(attribute, 'foreignKey')) {

      // Set search criteria where primary key is equal to the parents primary key
      searchCriteria[self.primaryKey] = parent[self.primaryKey];

      // Store any information we may need to build up an operation.
      // Use the `nullify` key to show we want to perform an update and not a destroy.
      criteria = {
        model: self.identity,
        criteria: searchCriteria,
        keyName: association,
        nullify: true
      };

      opts.push(criteria);
      return;
    }

    /////////////////////////////////////////////////////////////////////////
    // Child Record:
    // Lookup the attribute on the other side of the association on in the
    // case of a m:m association the child table will be the join table.
    /////////////////////////////////////////////////////////////////////////

    var child = self.waterline.schema[attribute.collection];
    var childAttribute = child.attributes[attribute.onKey];

    // Set the search criteria to use the collection's `via` key and the parent's primary key.
    searchCriteria[attribute.on] = parent[self.primaryKey];

    // If the childAttribute stores the foreign key, find all children with the
    // foreignKey equal to the parent's primary key and null them out or in the case of
    // a `junctionTable` flag destroy them.
    if(hop(childAttribute, 'foreignKey')) {

      // Store any information needed to perform the query. Set nullify to false if
      // a `junctionTable` property is found.
      criteria = {
        model: child.identity,
        criteria: searchCriteria,
        keyName: attribute.on,
        nullify: hop(child, 'junctionTable') ? false : true
      };

      opts.push(criteria);
      return;
    }
  });

  return opts;
}


/**
 * Remove Operation Runner
 *
 * Given a criteria object matching a remove operation, perform the
 * operation using waterline collection instances.
 *
 * @param {Array} operations
 * @param {Function} callback
 */

function removeOperationRunner(operations, cb) {

  var self = this;

  function runner(operation, next) {
    var values = {};

    // If nullify is false, run a destroy method using the criteria to destroy
    // the join table records.
    if(!operation.nullify) {
      self.waterline.collections[operation.model].destroy(operation.criteria).exec(next);
      return;
    }

    // Run an update operation to set the foreign key to null on all the
    // associated child records.
    values[operation.keyName] = null;

    self.waterline.collections[operation.model].update(operation.criteria, values).exec(next);
  }


  // Run the operations
  async.each(operations, runner, cb);
}


/**
 * Build up operations for performing links.
 *
 * Given a parent and a set of operations, queue up operations to associate two
 * records together. This could be using the parent's `.add()` method which handles
 * the logic for us or building up a `create` operation that we can run to create the
 * associated record with the correct foreign key set.
 *
 * @param {Object} parent
 * @param {Object} operations
 * @return {Object}
 */

function buildParentLinkOperations(parent, operations) {

  var recordsToCreate = {};

  // Determine whether to use the parent association's `.add()` function
  // or whether to queue up a create operation.
  function determineOperation(association, opt) {

    // Check if the association has an `add` method, if so use it.
    if(hop(parent[association], 'add')) {
      parent[association].add(opt);
      return;
    }

    recordsToCreate[association] = recordsToCreate[association] || [];
    recordsToCreate[association].push(opt);
  }

  // For each operation look at all the .add operations and determine
  // what to do with them.
  Object.keys(operations).forEach(function(association) {
    operations[association].add.forEach(function(opt) {
      determineOperation(association, opt);
    });
  });

  return recordsToCreate;
}


/**
 * Create New Records.
 *
 * Given an object of association records to create, perform a create
 * on the child model and set the parent's foreign key to the newly
 * created record's primary key.
 *
 * @param {Object} parent
 * @param {Object} recordsToCreate
 * @param {Function} cb
 */

function createNewRecords(parent, recordsToCreate, cb) {

  var self = this;

  // For each association, run the createRecords function
  // in the model context.
  function mapAssociations(association, next) {
    var model = self.waterline.collections[association];
    var records = recordsToCreate[association];

    function createRunner(record, nextRecord) {
      var args = [parent, association, record, nextRecord];
      createRecord.apply(model, args);
    }

    async.each(records, createRunner, next);
  }

  // Create a record and set the parent's foreign key to the
  // newly created record's primary key.
  function createRecord(parent, association, record, next) {
    var self = this;

    this.create(record).exec(function(err, val) {
      if(err) return next(err);
      parent[association] = val[self.primaryKey];
      next();
    });
  }


  async.each(Object.keys(recordsToCreate), mapAssociations, cb);
}

},{"../helpers":70,"async":"async","lodash":"lodash"}],75:[function(require,module,exports){
/**
 * Module Dependencies
 */

var hasOwnProperty = require('../helpers').object.hasOwnProperty;

/**
 * Traverse an object representing values and map out any associations.
 *
 * @param {String} model
 * @param {Object} schema
 * @param {Object} values
 * @return {Object}
 * @api private
 */


module.exports = function(model, schema, values) {
  var self = this;

  // Pick out the top level associations
  var associations = {
    collections: [],
    models: []
  };

  Object.keys(values).forEach(function(key) {

    // Ignore values equal to null
    if(values[key] === null) return;

    // Ignore joinTables
    if(hasOwnProperty(schema[model], 'junctionTable')) return;
    if(!hasOwnProperty(schema[model].attributes, key)) return;

    var attribute = schema[model].attributes[key];
    if(!hasOwnProperty(attribute, 'collection') && !hasOwnProperty(attribute, 'foreignKey')) return;

    if(hasOwnProperty(attribute, 'collection')) associations.collections.push(key);
    if(hasOwnProperty(attribute, 'foreignKey')) associations.models.push(key);

  });

  return associations;
};

},{"../helpers":70}],76:[function(require,module,exports){
var _ = require('lodash');
var util = require('./helpers');
var hop = util.object.hasOwnProperty;
var switchback = require('node-switchback');
var errorify = require('../error');
var WLUsageError = require('../error/WLUsageError');

var normalize = module.exports = {

  // Expand Primary Key criteria into objects
  expandPK: function(context, options) {

    // Default to id as primary key
    var pk = 'id';

    // If autoPK is not used, attempt to find a primary key
    if (!context.autoPK) {
      // Check which attribute is used as primary key
      for(var key in context.attributes) {
        if(!util.object.hasOwnProperty(context.attributes[key], 'primaryKey')) continue;

        // Check if custom primaryKey value is falsy
        if(!context.attributes[key].primaryKey) continue;

        // If a custom primary key is defined, use it
        pk = key;
        break;
      }
    }

    // Check if options is an integer or string and normalize criteria
    // to object, using the specified primary key field.
    if(_.isNumber(options) || _.isString(options) || Array.isArray(options)) {
      // Temporary store the given criteria
      var pkCriteria = _.clone(options);

      // Make the criteria object, with the primary key
      options = {};
      options[pk] = pkCriteria;
    }

    // If we're querying by primary key, create a coercion function for it
    // depending on the data type of the key
    if (options && options[pk]) {

      var coercePK;
      if (context.attributes[pk].type == 'integer') {
        coercePK = function(pk) {return +pk;};
      }
      else if (context.attributes[pk].type == 'string') {
        coercePK = function(pk) {return String(pk).toString();};
      }
      // If the data type is unspecified, return the key as-is
      else {
        coercePK = function(pk) {return pk;};
      }

      // If the criteria is an array of PKs, coerce them all
      if (Array.isArray(options[pk])) {
        options[pk] = options[pk].map(coercePK);
      }
      // Otherwise just coerce the one
      else {
        if(!_.isObject(options[pk])) {
          options[pk] = coercePK(options[pk]);
        }
      }

    }

    return options;

  },

  // Normalize the different ways of specifying criteria into a uniform object
  criteria: function(origCriteria) {
    var criteria = _.cloneDeep(origCriteria);

    // If original criteria is already false, keep it that way.
    if (criteria === false) return criteria;

    if(!criteria) return {
      where: null
    };

    // Let the calling method normalize array criteria. It could be an IN query
    // where we need the PK of the collection or a .findOrCreateEach
    if(Array.isArray(criteria)) return criteria;

    // Empty undefined values from criteria object
    _.each(criteria, function(val, key) {
      if(_.isUndefined(val)) criteria[key] = null;
    });

    // Convert non-objects (ids) into a criteria
    // TODO: use customizable primary key attribute
    if(!_.isObject(criteria)) {
      criteria = {
        id: +criteria || criteria
      };
    }

    if(_.isObject(criteria) && !criteria.where && criteria.where !== null) {
      criteria = { where: criteria };
    }

    // Return string to indicate an error
    if(!_.isObject(criteria)) throw new WLUsageError('Invalid options/criteria :: ' + criteria);

    // If criteria doesn't seem to contain operational keys, assume all the keys are criteria
    if(!criteria.where && !criteria.joins && !criteria.join && !criteria.limit && !criteria.skip &&
      !criteria.sort && !criteria.sum && !criteria.average &&
      !criteria.groupBy && !criteria.min && !criteria.max && !criteria.select) {

      // Delete any residuals and then use the remaining keys as attributes in a criteria query
      delete criteria.where;
      delete criteria.joins;
      delete criteria.join;
      delete criteria.limit;
      delete criteria.skip;
      delete criteria.sort;
      criteria = {
        where: criteria
      };
    }
    // If where is null, turn it into an object
    else if(_.isNull(criteria.where)) criteria.where = {};

    // Move Limit, Skip, sort outside the where criteria
    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'limit')) {
      criteria.limit = parseInt(_.clone(criteria.where.limit), 10);
      if(criteria.limit < 0) criteria.limit = 0;
      delete criteria.where.limit;
    }
    else if(hop(criteria, 'limit')) {
      criteria.limit = parseInt(criteria.limit, 10);
      if(criteria.limit < 0) criteria.limit = 0;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'skip')) {
      criteria.skip = parseInt(_.clone(criteria.where.skip), 10);
      if(criteria.skip < 0) criteria.skip = 0;
      delete criteria.where.skip;
    }
    else if(hop(criteria, 'skip')) {
      criteria.skip = parseInt(criteria.skip, 10);
      if(criteria.skip < 0) criteria.skip = 0;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'sort')) {
      criteria.sort = _.clone(criteria.where.sort);
      delete criteria.where.sort;
    }

    // Pull out aggregation keys from where key
    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'sum')) {
      criteria.sum = _.clone(criteria.where.sum);
      delete criteria.where.sum;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'average')) {
      criteria.average = _.clone(criteria.where.average);
      delete criteria.where.average;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'groupBy')) {
      criteria.groupBy = _.clone(criteria.where.groupBy);
      delete criteria.where.groupBy;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'min')) {
      criteria.min = _.clone(criteria.where.min);
      delete criteria.where.min;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'max')) {
      criteria.max = _.clone(criteria.where.max);
      delete criteria.where.max;
    }

    if(hop(criteria, 'where') && criteria.where !== null && hop(criteria.where, 'select')) {
      criteria.select = _.clone(criteria.where.select);
      delete criteria.where.select;
    }

    // If WHERE is {}, always change it back to null
    if(criteria.where && _.keys(criteria.where).length === 0) {
      criteria.where = null;
    }

    // If an IN was specified in the top level query and is an empty array, we can return an
    // empty object without running the query because nothing will match anyway. Let's return
    // false from here so the query knows to exit out.
    if(criteria.where) {
      var falsy = false;
      Object.keys(criteria.where).forEach(function(key) {
        if(Array.isArray(criteria.where[key]) && criteria.where[key].length === 0) {
          falsy = true;
        }
      });

      if(falsy) return false;
    }

    // If an IN was specified inside an OR clause and is an empty array, remove it because nothing will
    // match it anyway and it can prevent errors in the adapters
    if(criteria.where && hop(criteria.where, 'or')) {

      // Ensure `or` is an array
      if (!_.isArray(criteria.where.or)) {
        throw new WLUsageError('An `or` clause in a query should be specified as an array of subcriteria');
      }

      var _clone = _.cloneDeep(criteria.where.or);
      criteria.where.or.forEach(function(clause, i) {
        Object.keys(clause).forEach(function(key) {
          if(Array.isArray(clause[key]) && clause[key].length === 0) {
            _clone.splice(i, 1);
          }
        });
      });

      criteria.where.or = _clone;
    }

    // Normalize sort criteria
    if(hop(criteria, 'sort') && criteria.sort !== null) {

      // Split string into attr and sortDirection parts (default to 'asc')
      if(_.isString(criteria.sort)) {
        var parts = criteria.sort.split(' ');

        // Set default sort to asc
        parts[1] = parts[1] ? parts[1].toLowerCase() : 'asc';

        // Throw error on invalid sort order
        if(parts[1] !== 'asc' && parts[1] !== 'desc') {
          throw new WLUsageError('Invalid sort criteria :: ' + criteria.sort);
        }

        // Expand criteria.sort into object
        criteria.sort = {};
        criteria.sort[parts[0]] = parts[1];
      }

      // normalize ASC/DESC notation
      Object.keys(criteria.sort).forEach(function(attr) {
        if(criteria.sort[attr] === 'asc') criteria.sort[attr] = 1;
        if(criteria.sort[attr] === 'desc') criteria.sort[attr] = -1;
      });

      // normalize binary sorting criteria
      Object.keys(criteria.sort).forEach(function(attr) {
        if(criteria.sort[attr] === 0) criteria.sort[attr] = -1;
      });

      // Verify that user either specified a proper object
      // or provided explicit comparator function
      if(!_.isObject(criteria.sort) && !_.isFunction(criteria.sort)) {
        throw new WLUsageError('Invalid sort criteria for ' + attrName + ' :: ' + direction);
      }
    }

    return criteria;
  },

  // Normalize the capitalization and % wildcards in a like query
  // Returns false if criteria is invalid,
  // otherwise returns normalized criteria obj.
  // Enhancer is an optional function to run on each criterion to preprocess the string
  likeCriteria: function(criteria, attributes, enhancer) {

    // Only accept criteria as an object
    if(criteria !== Object(criteria)) return false;

    criteria = _.clone(criteria);

    if(!criteria.where) criteria = { where: criteria };

    // Apply enhancer to each
    if (enhancer) criteria.where = util.objMap(criteria.where, enhancer);

    criteria.where = { like: criteria.where };

    return criteria;
  },


  // Normalize a result set from an adapter
  resultSet: function (resultSet) {

    // Ensure that any numbers that can be parsed have been
    return util.pluralize(resultSet, numberizeModel);
  },


  /**
   * Normalize the different ways of specifying callbacks in built-in Waterline methods.
   * Switchbacks vs. Callbacks (but not deferred objects/promises)
   *
   * @param  {Function|Handlers} cb
   * @return {Handlers}
   */
  callback: function (cb) {

    // Build modified callback:
    // (only works for functions currently)
    var wrappedCallback;
    if (_.isFunction(cb)) {
      wrappedCallback = function (err) {

        // If no error occurred, immediately trigger the original callback
        // without messing up the context or arguments:
        if (!err) {
          return applyInOriginalCtx(cb, arguments);
        }

        // If an error argument is present, upgrade it to a WLError
        // (if it isn't one already)
        err = errorify(err);

        var modifiedArgs = Array.prototype.slice.call(arguments,1);
        modifiedArgs.unshift(err);

        // Trigger callback without messing up the context or arguments:
        return applyInOriginalCtx(cb, modifiedArgs);
      };
    }





    //
    // TODO: Make it clear that switchback support it experimental.
    //
    // Push switchback support off until >= v0.11
    // or at least add a warning about it being a `stage 1: experimental`
    // feature.
    //

    if (!_.isFunction(cb)) wrappedCallback = cb;
    return switchback(wrappedCallback, {
      invalid: 'error', // Redirect 'invalid' handler to 'error' handler
      error: function _defaultErrorHandler () {
        console.error.apply(console, Array.prototype.slice.call(arguments));
      }
    });


    // ????
    // TODO: determine support target for 2-way switchback usage
    // ????

    // Allow callback to be -HANDLED- in different ways
    // at the app-level.
    // `cb` may be passed in (at app-level) as either:
    //    => an object of handlers
    //    => or a callback function
    //
    // If a callback function was provided, it will be
    // automatically upgraded to a simplerhandler object.
    // var cb_fromApp = switchback(cb);

    // Allow callback to be -INVOKED- in different ways.
    // (adapter def)
    // var cb_fromAdapter = cb_fromApp;

  }
};

// If any attribute looks like a number, but it's a string
// cast it to a number
function numberizeModel (model) {
  return util.objMap(model, numberize);
}


// If specified attr looks like a number, but it's a string, cast it to a number
function numberize (attr) {
  if (_.isString(attr) && isNumbery(attr) && parseInt(attr,10) < Math.pow(2, 53)) return +attr;
  else return attr;
}

// Returns whether this value can be successfully parsed as a finite number
function isNumbery (value) {
  return Math.pow(+value, 2) > 0;
}

// Replace % with %%%
function escapeLikeQuery(likeCriterion) {
  return likeCriterion.replace(/[^%]%[^%]/g, '%%%');
}

// Replace %%% with %
function unescapeLikeQuery(likeCriterion) {
  return likeCriterion.replace(/%%%/g, '%');
}



/**
 * Like _.partial, but accepts an array of arguments instead of
 * comma-seperated args (if _.partial is `call`, this is `apply`.)
 * The biggest difference from `_.partial`, other than the usage,
 * is that this helper actually CALLS the partially applied function.
 *
 * This helper is mainly useful for callbacks.
 *
 * @param  {Function} fn   [description]
 * @param  {[type]}   args [description]
 * @return {[type]}        [description]
 */

function applyInOriginalCtx (fn, args) {
  return (_.partial.apply(null, [fn].concat(Array.prototype.slice.call(args))))();
}

},{"../error":25,"../error/WLUsageError":23,"./helpers":70,"lodash":"lodash","node-switchback":93}],77:[function(require,module,exports){
/**
 * Dependencies
 */

var _ = require('lodash'),
    types = require('./types'),
    callbacks = require('./callbacks'),
    hasOwnProperty = require('./helpers').object.hasOwnProperty;

/**
 * Expose schema
 */

var schema = module.exports = exports;

/**
 * Iterate over `attrs` normalizing string values to the proper
 * attribute object.
 *
 * Example:
 * {
 *   name: 'STRING',
 *   age: {
 *     type: 'INTEGER'
 *   }
 * }
 *
 * Returns:
 * {
 *   name: {
 *     type: 'string'
 *   },
 *   age: {
 *     type: 'integer'
 *   }
 * }
 *
 * @param {Object} attrs
 * @return {Object}
 */

schema.normalizeAttributes = function(attrs) {
  var attributes = {};

  Object.keys(attrs).forEach(function(key) {

    // Not concerned with functions
    if(typeof attrs[key] === 'function') return;

    // Expand shorthand type
    if(typeof attrs[key] === 'string') {
      attributes[key] = { type: attrs[key] };
    } else {
      attributes[key] = attrs[key];
    }

    // Ensure type is lower case
    if(attributes[key].type && typeof attributes[key].type !== 'undefined') {
      attributes[key].type = attributes[key].type.toLowerCase();
    }

    // Ensure Collection property is lowercased
    if(hasOwnProperty(attrs[key], 'collection')) {
      attrs[key].collection = attrs[key].collection.toLowerCase();
    }

    // Ensure Model property is lowercased
    if(hasOwnProperty(attrs[key], 'model')) {
      attrs[key].model = attrs[key].model.toLowerCase();
    }
  });

  return attributes;
};


/**
 * Return all methods in `attrs` that should be provided
 * on the model.
 *
 * Example:
 * {
 *   name: 'string',
 *   email: 'string',
 *   doSomething: function() {
 *     return true;
 *   }
 * }
 *
 * Returns:
 * {
 *   doSomething: function() {
 *     return true;
 *   }
 * }
 *
 * @param {Object} attrs
 * @return {Object}
 */

schema.instanceMethods = function(attrs) {
  var methods = {};

  if(!attrs) return methods;

  Object.keys(attrs).forEach(function(key) {
    if(typeof attrs[key] === 'function') {
      methods[key] = attrs[key];
    }
  });

  return methods;
};


/**
 * Normalize callbacks
 *
 * Return all callback functions in `context`, allows for string mapping to
 * functions located in `context.attributes`.
 *
 * Example:
 * {
 *   attributes: {
 *     name: 'string',
 *     email: 'string',
 *     increment: function increment() { i++; }
 *   },
 *   afterCreate: 'increment',
 *   beforeCreate: function() { return true; }
 * }
 *
 * Returns:
 * {
 *   afterCreate: [
 *     function increment() { i++; }
 *   ],
 *   beforeCreate: [
 *     function() { return true; }
 *   ]
 * }
 *
 * @param {Object} context
 * @return {Object}
 */

schema.normalizeCallbacks = function(context) {
  var i, _i, len, _len, fn, fns = {};

  function defaultFn(fn) {
    return function(values, next) { return next(); };
  }

  for(i = 0, len = callbacks.length; i < len; i = i + 1) {
    fn = callbacks[i];

    // Skip if the model hasn't defined this callback
    if(typeof context[fn] === 'undefined') {
      fns[fn] = [ defaultFn(fn) ];
      continue;
    }

    if(Array.isArray(context[fn])) {
      fns[fn] = [];

      // Iterate over all functions
      for(_i = 0, _len = context[fn].length; _i < _len; _i = _i + 1) {
        if(typeof context[fn][_i] === 'string') {
          // Attempt to map string to function
          if(typeof context.attributes[context[fn][_i]] === 'function') {
            fns[fn][_i] = context.attributes[context[fn][_i]];
            delete context.attributes[context[fn][_i]];
          } else {
            throw new Error('Unable to locate callback `' + context[fn][_i] + '`');
          }
        } else {
          fns[fn][_i] = context[fn][_i];
        }
      }
    } else if(typeof context[fn] === 'string') {
      // Attempt to map string to function
      if(typeof context.attributes[context[fn]] === 'function') {
        fns[fn] = [ context.attributes[context[fn]] ];
        delete context.attributes[context[fn]];
      } else {
        throw new Error('Unable to locate callback `' + context[fn] + '`');
      }
    } else {
      // Just add a single function
      fns[fn] = [ context[fn] ];
    }
  }

  return fns;
};


/**
 * Replace any Join Criteria references with the defined tableName for a collection.
 *
 * @param {Object} criteria
 * @param {Object} collections
 * @return {Object}
 * @api public
 */

schema.serializeJoins = function(criteria, collections) {

  if(!criteria.joins) return criteria;

  var joins = _.cloneDeep(criteria.joins);

  joins.forEach(function(join) {

    if(!hasOwnProperty(collections[join.parent], 'tableName')) return;
    if(!hasOwnProperty(collections[join.child], 'tableName')) return;

    join.parent = collections[join.parent].tableName;
    join.child = collections[join.child].tableName;

  });

  criteria.joins = joins;
  return criteria;
};

},{"./callbacks":65,"./helpers":70,"./types":81,"lodash":"lodash"}],78:[function(require,module,exports){
/**
 * Module Dependencies
 */

var _ = require('lodash');

/**
 * Sort `data` (tuples) using `sortCriteria` (comparator)
 *
 * Based on method described here:
 * http://stackoverflow.com/a/4760279/909625
 *
 * @param  { Object[] } data         [tuples]
 * @param  { Object }   sortCriteria [mongo-style comparator object]
 * @return { Object[] }
 */

module.exports = function sortData(data, sortCriteria) {

  function dynamicSort(property) {
    var sortOrder = 1;
    if(property[0] === '-') {
      sortOrder = -1;
      property = property.substr(1);
    }

    return function (a,b) {
      var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
      return result * sortOrder;
    };
  }

  function dynamicSortMultiple() {
    var props = arguments;
    return function (obj1, obj2) {
      var i = 0, result = 0, numberOfProperties = props.length;

      while(result === 0 && i < numberOfProperties) {
        result = dynamicSort(props[i])(obj1, obj2);
        i++;
      }
      return result;
    };
  }

  // build sort criteria in the format ['firstName', '-lastName']
  var sortArray = [];
  _.each(_.keys(sortCriteria), function(key) {
    if(sortCriteria[key] === -1) sortArray.push('-' + key);
    else sortArray.push(key);
  });

  data.sort(dynamicSortMultiple.apply(null, sortArray));
  return data;
};

},{"lodash":"lodash"}],79:[function(require,module,exports){
/**
 * Streams
 *
 * A Streaming API with support for Transformations
 */

var util = require('util'),
    Stream = require('stream'),
    Transformations = require('./transformations'),
    _ = require('lodash');

var ModelStream = module.exports = function(transformation) {

  // Use specified, or otherwise default, JSON transformation
  this.transformation = transformation || Transformations.json;

  // Reset write index
  this.index = 0;

  // Make stream writable
  this.writable = true;
};

util.inherits(ModelStream, Stream);

/**
 * Write to stream
 *
 * Extracts args to write and emits them as data events
 *
 * @param {Object} model
 * @param {Function} cb
 */

ModelStream.prototype.write = function(model, cb) {
  var self = this;

  // Run transformation on this item
  this.transformation.write(model, this.index, function writeToStream(err, transformedModel) {

    // Increment index for next time
    self.index++;

    // Write transformed model to stream
    self.emit('data', _.clone(transformedModel));

    // Inform that we're finished
    if(cb) return cb(err);
  });

};

/**
 * End Stream
 */

ModelStream.prototype.end = function(err, cb) {
  var self = this;

  if(err) {
    this.emit('error', err.message);
    if(cb) return cb(err);
    return;
  }

  this.transformation.end(function(err, suffix) {

    if(err) {
      self.emit('error', err);
      if(cb) return cb(err);
      return;
    }

    // Emit suffix if specified
    if(suffix) self.emit('data', suffix);
    self.emit('end');
    if(cb) return cb();
  });
};

},{"./transformations":80,"lodash":"lodash","stream":"stream","util":"util"}],80:[function(require,module,exports){
/**
 * Transformations
 */

var Transformations = module.exports = {};

// Add JSON Transformation methods
Transformations.json = {};

/**
 * Write Method Transformations
 *
 * Used to stream back valid JSON from Waterline
 */

Transformations.json.write = function(model, index, cb) {
  var transformedModel;

  if(!model) transformedModel = '';

  // Transform to JSON
  if(model) {
    try {
      transformedModel = JSON.stringify(model);
    } catch (e) {
      return cb(e);
    }
  }

  // Prefix with opening [
  if (index === 0) { transformedModel = '['; }

  // Prefix with comma after first model
  if (index > 1) transformedModel = ',' + transformedModel;

  cb(null, transformedModel);
};

/**
 * Close off JSON Array
 */
Transformations.json.end = function(cb) {
  var suffix = ']';
  cb(null, suffix);
};

},{}],81:[function(require,module,exports){
/**
 * Types Supported By Schemas
 */

module.exports = [
  'string',
  'text',
  'integer',
  'float',
  'date',
  'time',
  'datetime',
  'boolean',
  'binary',
  'array',
  'json',
  'mediumtext',
  'longtext',
  'objectid'
];

},{}],82:[function(require,module,exports){
/**
 * Create a nicely formatted usage error
 */

module.exports = function(err, usage, cb) {
  var message = err + '\n==============================================\nProper usage :: \n' + usage + '\n==============================================\n';
  if(cb) return cb(message);
  throw new Error(message);
};
},{}],83:[function(require,module,exports){
/**
 * Module dependencies
 */

var util = require('lodash');
var sanitize = require('validator').sanitize;




/**
 * Public access
 */

module.exports = function (entity) {
	return new Anchor(entity);
};





/**
 * Constructor of individual instance of Anchor
 * Specify the function, object, or list to be anchored
 */

function Anchor (entity) {
	if (util.isFunction(entity)) {
		this.fn = entity;
		throw new Error ('Anchor does not support functions yet!');
	}
	else this.data = entity;

	return this;
}





/**
 * Built-in data type rules
 */

Anchor.prototype.rules = require('./lib/match/rules');





/**
 * Enforce that the data matches the specified ruleset
 */

Anchor.prototype.to = function (ruleset, context) {

	var errors = [];

	// If ruleset doesn't contain any explicit rule keys,
	// assume that this is a type


	// Look for explicit rules
	for (var rule in ruleset) {

		if (rule === 'type') {

			// Use deep match to descend into the collection and verify each item and/or key
			// Stop at default maxDepth (50) to prevent infinite loops in self-associations
			errors = errors.concat(Anchor.match.type.call(context, this.data, ruleset['type']));
		}

		// Validate a non-type rule
		else {
			errors = errors.concat(Anchor.match.rule.call(context, this.data, rule, ruleset[rule]));
		}
	}

	// If errors exist, return the list of them
	if (errors.length) {
		return errors;
	}

	// No errors, so return false
	else return false;

};
Anchor.prototype.hasErrors = Anchor.prototype.to;





/**
 * Coerce the data to the specified ruleset if possible
 * otherwise throw an error
 * Priority: this should probably provide the default
 * implementation in Waterline core.  Currently it's completely
 * up to the adapter to define type coercion.
 *
 * Which is fine!.. but complicates custom CRUD adapter development.
 * Much handier would be an evented architecture, that allows
 * for adapter developers to write:
 *
	{
		// Called before find() receives criteria
		// Here, criteria refers to just attributes (the `where`)
		// limit, skip, and sort are not included
		coerceCriteria: function (criteria) {
			return criteria;
		},

		// Called before create() or update() receive values
		coerceValues: function () {}

	}
 *
 * Adapter developers would be able to use Anchor.prototype.cast()
 * to declaritively define these type coercions.

 * Down the line, we could take this further for an even nicer API,
 * but for now, this alone would be a nice improvement.
 *
 */

Anchor.prototype.cast = function (ruleset) {
	todo();
};




/**
 * Coerce the data to the specified ruleset no matter what
 */

Anchor.prototype.hurl = function (ruleset) {

	// Iterate trough given data attributes
	// to check if they exist in the ruleset
	for (var attr in this.data) {
		if (this.data.hasOwnProperty(attr)) {

			// If it doesnt...
			if (!ruleset[attr]) {

				// Declaring err here as error helpers live in match.js
				var err = new Error('Validation error: Attribute \"' + attr + '\" is not in the ruleset.');

				// just throw it
				throw err;
			}
		}
	}

	// Once we make sure that attributes match
	// we can just proceed to deepMatch
	Anchor.match(this.data, ruleset, this);
};





/**
 * Specify default values to automatically populated when undefined
 */

Anchor.prototype.defaults = function (ruleset) {
	todo();
};





/**
 * Declare a custom data type
 * If function definition is specified, `name` is required.
 * Otherwise, if dictionary-type `definition` is specified,
 * `name` must not be present.
 *
 * @param {String} name				[optional]
 * @param {Object|Function}	definition
 */

Anchor.prototype.define = function (name, definition) {

	// check to see if we have an dictionary
	if ( util.isObject(name) ) {

		// if so all the attributes should be validation functions
		for (var attr in name){
			if(!util.isFunction(name[attr])){
				throw new Error('Definition error: \"' + attr + '\" does not have a definition');
			}
		}

		// add the new custom data types
		util.extend(Anchor.prototype.rules, name);

		return this;

	}

	if ( util.isFunction(definition) && util.isString(name) ) {

		// Add a single data type
		Anchor.prototype.rules[name] = definition;

		return this;

	}

	throw new Error('Definition error: \"' + name + '\" is not a valid definition.');
};





/**
 * Specify custom ruleset
 */

Anchor.prototype.as = function (ruleset) {
	todo();
};




/**
 * Specify named arguments and their rulesets as an object
 */

Anchor.prototype.args = function (args) {
	todo();
};




/**
 * Specify each of the permitted usages for this function
 */

Anchor.prototype.usage = function () {
	var usages = util.toArray(arguments);
	todo();
};




/**
 * Deep-match a complex collection or model against a schema
 */

Anchor.match = require('./lib/match');





/**
 * Expose `define` so it can be used globally
 */

module.exports.define = Anchor.prototype.define;





function todo() {
	throw new Error('Not implemented yet! If you\'d like to contribute, tweet @mikermcneil.');
}

},{"./lib/match":85,"./lib/match/rules":88,"lodash":"lodash","validator":89}],84:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');
var util = require('util');


/**
 * `errorFactory()`
 * 
 * @param  {?} value
 * @param  {String} ruleName
 * @param  {String} keyName
 * @param  {String|Function} customMessage    (optional)
 * 
 * @return {Object}
 * 
 * @api private
 */

module.exports = function errorFactory(value, ruleName, keyName, customMessage) {

  // Construct error message
  var errMsg;
  if (_.isString(customMessage)) {
    errMsg = customMessage;
  }
  else if (_.isFunction(customMessage)) {
    errMsg = customMessage(value, ruleName, keyName);
  }
  else {
    // errMsg = 'Validation error: "' + value + '" ';
    // errMsg += keyName ? '(' + keyName + ') ' : '';
    // errMsg += 'is not of type "' + ruleName + '"';

    errMsg = util.format(
      '`%s` should be a %s (instead of "%s", which is a %s)',
      keyName, ruleName, value, typeof value
    );
  }


  // Construct error object
  return [{
    property: keyName,
    data: value,
    message: errMsg,
    rule: ruleName,
    actualType: typeof value,
    expectedType: ruleName
  }];
};

},{"lodash":"lodash","util":"util"}],85:[function(require,module,exports){
module.exports = {
  type: require('./matchType'),
  rule: require('./matchRule')
};

},{"./matchRule":86,"./matchType":87}],86:[function(require,module,exports){
/**
 * Module dependencies
 */

var util = require('util');
var _ = require('lodash');
var rules = require('./rules');


/**
 * Match a miscellaneous rule
 * Returns an empty list on success,
 * or a list of errors if things go wrong
 */

module.exports = function matchRule (data, ruleName, args) {
  var self = this,
    errors = [];

  // if args is an array we need to make it a nested array
  if (Array.isArray(args)) {
    args = [args];
  }

  // Ensure args is a list, then prepend it with data
  if (!_.isArray(args)) {
    args = [args];
  }

  // push data on to front
  args.unshift(data);

  // Lookup rule and determine outcome
  var outcome;
  var rule = rules[ruleName];
  if (!rule) {
    throw new Error('Unknown rule: ' + ruleName);
  }
  try {
    outcome = rule.apply(self, args);
  } catch (e) {
    outcome = false;
  }

  // If outcome is false, an error occurred
  if (!outcome) {
    return [{
      rule: ruleName,
      data: data,
      message: util.format('"%s" validation rule failed for input: %s', ruleName, util.inspect(data))
    }];
  }
  else {
    return [];
  }

};

},{"./rules":88,"lodash":"lodash","util":"util"}],87:[function(require,module,exports){
/**
 * Module dependencies
 */

var util = require('util');
var _ = require('lodash');
var rules = require('./rules');
var errorFactory = require('./errorFactory');

// var JSValidationError

// Exposes `matchType` as `deepMatchType`.
module.exports = deepMatchType;


var RESERVED_KEYS = {
  $validate: '$validate',
  $message: '$message'
};

// Max depth value
var MAX_DEPTH = 50;



/**
 * Match a complex collection or model against a schema
 *
 * @param {?} data
 * @param {?} ruleset
 * @param {Numeric} depth
 * @param {String} keyName
 * @param {String} customMessage
 *                   (optional)
 * 
 * @returns a list of errors (or an empty list if no errors were found)
 */

function deepMatchType(data, ruleset, depth, keyName, customMessage) {

  var self = this;

  // Prevent infinite recursion
  depth = depth || 0;
  if (depth > MAX_DEPTH) {
    return [
      new Error({ message: 'Exceeded MAX_DEPTH when validating object.  Maybe it\'s recursively referencing itself?'})
    ];
  }

  // (1) Base case - primitive
  // ----------------------------------------------------
  // If ruleset is not an object or array, use the provided function to validate
  if (!_.isObject(ruleset)) {
    return matchType.call(self, data, ruleset, keyName, customMessage);
  }


  // (2) Recursive case - Array
  // ----------------------------------------------------
  // If this is a schema rule, check each item in the data collection
  else if (_.isArray(ruleset)) {
    if (ruleset.length !== 0) {
      if (ruleset.length > 1) {
        return [
          new Error({ message: '[] (or schema) rules must contain exactly one item.'})
        ];
      }

      // Handle plurals (arrays with a schema rule)
      // Match each object in data array against ruleset until error is detected
      return _.reduce(data, function getErrors(errors, datum) {
        errors = errors.concat(deepMatchType.call(self, datum, ruleset[0], depth + 1, keyName, customMessage));
        return errors;
      }, []);
    }
    // Leaf rules land here and execute the iterator fn
    else return matchType.call(self, data, ruleset, keyName, customMessage);
  }

  // (3) Recursive case - POJO
  // ----------------------------------------------------
  // If the current rule is an object, check each key
  else {

    // Note:
    // 
    // We take advantage of a couple of preconditions at this point:
    // (a) ruleset must be an Object
    // (b) ruleset must NOT be an Array


    //  *** Check for special reserved keys ***

    // { $message: '...' } specified as data type
    // uses supplied message instead of the default
    var _customMessage = ruleset[RESERVED_KEYS.$message];

    // { $validate: {...} } specified as data type
    // runs a sub-validation (recursive)
    var subValidation = ruleset[RESERVED_KEYS.$validate];

    // Don't allow a `$message` without a `$validate`
    if (_customMessage) {
      if (!subValidation) {
        return [{
          code: 'E_USAGE',
          status: 500,
          $message: _customMessage,
          property: keyName,
          message: 'Custom messages ($message) require a subvalidation - please specify a `$validate` option on `'+keyName+'`'
        }];
      }
      else {
        // Use the specified message as the `customMessage`
        customMessage = _customMessage;
      }
    }

    // Execute subvalidation rules
    if (subValidation) {
      if (!subValidation.type) {
        return [
          new Error({message: 'Sub-validation rules (i.e. using $validate) other than `type` are not currently supported'})
        ];
      }

      return deepMatchType.call(self, data, subValidation.type, depth+1, keyName, customMessage);
    }
    


    

    // Don't treat empty object as a ruleset
    // Instead, treat it as 'object'
    if (_.keys(ruleset).length === 0) {
      return matchType.call(self, data, ruleset, keyName, customMessage);
    } else {
      // Iterate through rules in dictionary until error is detected
      return _.reduce(ruleset, function(errors, subRule, key) {

        // Prevent throwing when encountering unexpectedly "shallow" data
        // (instead- this should be pushed as an error where "undefined" is
        // not of the expected type: "object")
        if (!_.isObject(data)) {
          return errors.concat(errorFactory(data, 'object', key, customMessage));
        } else {
          return errors.concat(deepMatchType.call(self, data[key], ruleset[key], depth + 1, key, customMessage));
        }
      }, []);
    }
  }
}



/**
 * `matchType()`
 * 
 * Return whether a piece of data matches a rule
 *
 * @param {?} datum
 * @param {Array|Object|String|Regexp} ruleName
 * @param {String} keyName
 * @param {String} customMessage
 *                      (optional)
 *
 * @returns a list of errors, or an empty list in the absense of them
 * @api private
 */

function matchType(datum, ruleName, keyName, customMessage) {

  var self = this;

  try {
    var rule;
    var outcome;

    // Determine rule
    if (_.isEqual(ruleName, [])) {
      // [] specified as data type checks for an array
      rule = _.isArray;
    }
    else if (_.isEqual(ruleName, {})) {
      // {} specified as data type checks for any object
      rule = _.isObject;
    }
    else if (_.isRegExp(ruleName)) {
      // Allow regexes to be used
      rule = function(x) {
        // If argument to regex rule is not a string,
        // fail on 'string' validation
        if (!_.isString(x)) {
          rule = rules['string'];
        } else x.match.call(self, ruleName);
      };
    }
    // Lookup rule
    else rule = rules[ruleName];


    // Determine outcome
    if (!rule) {
      return [
        new Error({message:'Unknown rule: ' + ruleName})
      ];
    }
    else outcome = rule.call(self, datum);

    // If validation failed, return an error
    if (!outcome) {
      return errorFactory(datum, ruleName, keyName, customMessage);
    }

    // If everything is ok, return an empty list
    else return [];
  }
  catch (e) {
    return errorFactory(datum, ruleName, keyName, customMessage);
  }

}


},{"./errorFactory":84,"./rules":88,"lodash":"lodash","util":"util"}],88:[function(require,module,exports){
(function (Buffer){
/**
 * Module dependencies
 */

var _ = require('lodash');
var validator = require('validator');



/**
 * Type rules
 */

module.exports = {

	'empty'		: _.isEmpty,

	'required'	: function (x) {
		// Transform data to work properly with node validator
		if(!x && x !== 0) x = '';
		else if(typeof x.toString !== 'undefined') x = x.toString();
		else x = '' + x;

		return !validator.isNull(x);
	},

	'protected'	: function () {return true;},

	'notEmpty'	: function (x) {

		// Transform data to work properly with node validator
		if (!x) x = '';
		else if (typeof x.toString !== 'undefined') x = x.toString();
		else x = '' + x;

		return !validator.isNull(x);
	},

	'undefined'	: _.isUndefined,

	'object'  : _.isObject,
	'json'    : function (x) {
		if (_.isUndefined(x)) return false;
		try { JSON.stringify(x); }
		catch(err) { return false; }
		return true;
	},
	'mediumtext'	: _.isString,
	'text'		: _.isString,
	'string'	: _.isString,
	'alpha'		: validator.isAlpha,
	'alphadashed': function (x) {return (/^[a-zA-Z-_]*$/).test(x); },
	'numeric'	: validator.isNumeric,
	'alphanumeric': validator.isAlphanumeric,
	'alphanumericdashed': function (x) {return (/^[a-zA-Z0-9-_]*$/).test(x); },
	'email'		: validator.isEmail,
	'url'		: function(x, opt) { return validator.isURL(x, opt === true ? undefined : opt); },
	'urlish'	: /^\s([^\/]+\.)+.+\s*$/g,
	'ip'			: validator.isIP,
	'ipv4'		: validator.isIPv4,
	'ipv6'		: validator.isIPv6,
	'creditcard': validator.isCreditCard,
	'uuid'		: validator.isUUID,
	'uuidv3'	: function (x){ return validator.isUUID(x, 3);},
	'uuidv4'	: function (x){ return validator.isUUID(x, 4);},

	'int'			: validator.isInt,
	'integer'	: validator.isInt,
	'number'	: _.isNumber,
	'finite'	: _.isFinite,

	'decimal'	: validator.isFloat,
	'float'		: validator.isFloat,

	'falsey'	: function (x) { return !x; },
	'truthy'	: function (x) { return !!x; },
	'null'		: _.isNull,
	'notNull'	: function (x) { return !validator.isNull(x); },

	'boolean'	: _.isBoolean,

	'array'		: _.isArray,

	'binary'	: function (x) { return Buffer.isBuffer(x) || _.isString(x); },

	'date'		: validator.isDate,
	'datetime': validator.isDate,

	'hexadecimal': validator.hexadecimal,
	'hexColor': validator.isHexColor,

	'lowercase': validator.isLowercase,
	'uppercase': validator.isUppercase,

	// Miscellaneous rules
	'after'		: validator.isAfter,
	'before'	: validator.isBefore,

	'equals'	: validator.equals,
	'contains': validator.contains,
	'notContains': function (x, str) { return !validator.contains(x, str); },
	'len'			: function (x, min, max) { return validator.len(x, min, max); },
	'in'			: validator.isIn,
	'notIn'		: function (x, arrayOrString) { return !validator.isIn(x, arrayOrString); },
	'max'			: function (x, val) {
		var number = parseFloat(x);
		return isNaN(number) || number <= val;
	},
	'min'			: function (x, val) {
		var number = parseFloat(x);
		return isNaN(number) || number >= val;
	},
	'greaterThan' : function (x, val) {
    var number = parseFloat(x);
    return isNaN(number) || number > val;
  },
  'lessThan' : function (x, val) {
    var number = parseFloat(x);
    return isNaN(number) || number < val;
  },
	'minLength'	: function (x, min) { return validator.isLength(x, min); },
	'maxLength'	: function (x, max) { return validator.isLength(x, 0, max); },

	'regex' : function (x, regex) { return validator.matches(x, regex); },
	'notRegex' : function (x, regex) { return !validator.matches(x, regex); }

};

}).call(this,require("buffer").Buffer)
},{"buffer":"buffer","lodash":"lodash","validator":89}],89:[function(require,module,exports){
/*!
 * Copyright (c) 2014 Chris O'Hara <cohara87@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

(function (name, definition) {
    if (typeof exports !== 'undefined' && typeof module !== 'undefined') {
        module.exports = definition();
    } else if (typeof define === 'function' && typeof define.amd === 'object') {
        define(definition);
    } else {
        this[name] = definition();
    }
})('validator', function (validator) {

    'use strict';

    validator = { version: '3.22.2' };

    var email = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i;

    var creditCard = /^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})$/;

    var isbn10Maybe = /^(?:[0-9]{9}X|[0-9]{10})$/
      , isbn13Maybe = /^(?:[0-9]{13})$/;

    var ipv4Maybe = /^(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)$/
      , ipv6 = /^::|^::1|^([a-fA-F0-9]{1,4}::?){1,7}([a-fA-F0-9]{1,4})$/;

    var uuid = {
        '3': /^[0-9A-F]{8}-[0-9A-F]{4}-3[0-9A-F]{3}-[0-9A-F]{4}-[0-9A-F]{12}$/i
      , '4': /^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i
      , '5': /^[0-9A-F]{8}-[0-9A-F]{4}-5[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i
      , all: /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i
    };

    var alpha = /^[a-zA-Z]+$/
      , alphanumeric = /^[a-zA-Z0-9]+$/
      , numeric = /^-?[0-9]+$/
      , int = /^(?:-?(?:0|[1-9][0-9]*))$/
      , float = /^(?:-?(?:[0-9]+))?(?:\.[0-9]*)?(?:[eE][\+\-]?(?:[0-9]+))?$/
      , hexadecimal = /^[0-9a-fA-F]+$/
      , hexcolor = /^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/;

    var ascii = /^[\x00-\x7F]+$/
      , multibyte = /[^\x00-\x7F]/
      , fullWidth = /[^\u0020-\u007E\uFF61-\uFF9F\uFFA0-\uFFDC\uFFE8-\uFFEE0-9a-zA-Z]/
      , halfWidth = /[\u0020-\u007E\uFF61-\uFF9F\uFFA0-\uFFDC\uFFE8-\uFFEE0-9a-zA-Z]/;

    var surrogatePair = /[\uD800-\uDBFF][\uDC00-\uDFFF]/;

    var base64 = /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$/;

    validator.extend = function (name, fn) {
        validator[name] = function () {
            var args = Array.prototype.slice.call(arguments);
            args[0] = validator.toString(args[0]);
            return fn.apply(validator, args);
        };
    };

    //Right before exporting the validator object, pass each of the builtins
    //through extend() so that their first argument is coerced to a string
    validator.init = function () {
        for (var name in validator) {
            if (typeof validator[name] !== 'function' || name === 'toString' ||
                    name === 'toDate' || name === 'extend' || name === 'init') {
                continue;
            }
            validator.extend(name, validator[name]);
        }
    };

    validator.toString = function (input) {
        if (typeof input === 'object' && input !== null && input.toString) {
            input = input.toString();
        } else if (input === null || typeof input === 'undefined' || (isNaN(input) && !input.length)) {
            input = '';
        } else if (typeof input !== 'string') {
            input += '';
        }
        return input;
    };

    validator.toDate = function (date) {
        if (Object.prototype.toString.call(date) === '[object Date]') {
            return date;
        }
        date = Date.parse(date);
        return !isNaN(date) ? new Date(date) : null;
    };

    validator.toFloat = function (str) {
        return parseFloat(str);
    };

    validator.toInt = function (str, radix) {
        return parseInt(str, radix || 10);
    };

    validator.toBoolean = function (str, strict) {
        if (strict) {
            return str === '1' || str === 'true';
        }
        return str !== '0' && str !== 'false' && str !== '';
    };

    validator.equals = function (str, comparison) {
        return str === validator.toString(comparison);
    };

    validator.contains = function (str, elem) {
        return str.indexOf(validator.toString(elem)) >= 0;
    };

    validator.matches = function (str, pattern, modifiers) {
        if (Object.prototype.toString.call(pattern) !== '[object RegExp]') {
            pattern = new RegExp(pattern, modifiers);
        }
        return pattern.test(str);
    };

    validator.isEmail = function (str) {
        return email.test(str);
    };

    var default_url_options = {
        protocols: [ 'http', 'https', 'ftp' ]
      , require_tld: true
      , require_protocol: false
      , allow_underscores: false
    };

    validator.isURL = function (url, options) {
        if (!url || url.length >= 2083) {
            return false;
        }
        if (url.indexOf('mailto:') === 0) {
            return false;
        }
        options = merge(options, default_url_options);
        var protocol, user, pass, auth, host, hostname, port,
            port_str, path, query, hash, split;
        split = url.split('://');
        if (split.length > 1) {
            protocol = split.shift();
            if (options.protocols.indexOf(protocol) === -1) {
                return false;
            }
        } else if (options.require_protocol) {
            return false;
        }
        url = split.join('://');
        split = url.split('#');
        url = split.shift();
        hash = split.join('#');
        if (hash && /\s/.test(hash)) {
            return false;
        }
        split = url.split('?');
        url = split.shift();
        query = split.join('?');
        if (query && /\s/.test(query)) {
            return false;
        }
        split = url.split('/');
        url = split.shift();
        path = split.join('/');
        if (path && /\s/.test(path)) {
            return false;
        }
        split = url.split('@');
        if (split.length > 1) {
            auth = split.shift();
            if (auth.indexOf(':') >= 0) {
                auth = auth.split(':');
                user = auth.shift();
                if (!/^\S+$/.test(user)) {
                    return false;
                }
                pass = auth.join(':');
                if (!/^\S*$/.test(user)) {
                    return false;
                }
            }
        }
        hostname = split.join('@');
        split = hostname.split(':');
        host = split.shift();
        if (split.length) {
            port_str = split.join(':');
            port = parseInt(port_str, 10);
            if (!/^[0-9]+$/.test(port_str) || port <= 0 || port > 65535) {
                return false;
            }
        }
        if (!validator.isIP(host) && !validator.isFQDN(host, options) &&
                host !== 'localhost') {
            return false;
        }
        if (options.host_whitelist &&
                options.host_whitelist.indexOf(host) === -1) {
            return false;
        }
        if (options.host_blacklist &&
                options.host_blacklist.indexOf(host) !== -1) {
            return false;
        }
        return true;
    };

    validator.isIP = function (str, version) {
        version = validator.toString(version);
        if (!version) {
            return validator.isIP(str, 4) || validator.isIP(str, 6);
        } else if (version === '4') {
            if (!ipv4Maybe.test(str)) {
                return false;
            }
            var parts = str.split('.').sort(function (a, b) {
                return a - b;
            });
            return parts[3] <= 255;
        }
        return version === '6' && ipv6.test(str);
    };

    var default_fqdn_options = {
        require_tld: true
      , allow_underscores: false
    };

    validator.isFQDN = function (str, options) {
        options = merge(options, default_fqdn_options);
        var parts = str.split('.');
        if (options.require_tld) {
            var tld = parts.pop();
            if (!parts.length || !/^[a-z]{2,}$/i.test(tld)) {
                return false;
            }
        }
        for (var part, i = 0; i < parts.length; i++) {
            part = parts[i];
            if (options.allow_underscores) {
                if (part.indexOf('__') >= 0) {
                    return false;
                }
                part = part.replace(/_/g, '');
            }
            if (!/^[a-z\u00a1-\uffff0-9-]+$/i.test(part)) {
                return false;
            }
            if (part[0] === '-' || part[part.length - 1] === '-' ||
                    part.indexOf('---') >= 0) {
                return false;
            }
        }
        return true;
    };

    validator.isAlpha = function (str) {
        return alpha.test(str);
    };

    validator.isAlphanumeric = function (str) {
        return alphanumeric.test(str);
    };

    validator.isNumeric = function (str) {
        return numeric.test(str);
    };

    validator.isHexadecimal = function (str) {
        return hexadecimal.test(str);
    };

    validator.isHexColor = function (str) {
        return hexcolor.test(str);
    };

    validator.isLowercase = function (str) {
        return str === str.toLowerCase();
    };

    validator.isUppercase = function (str) {
        return str === str.toUpperCase();
    };

    validator.isInt = function (str) {
        return int.test(str);
    };

    validator.isFloat = function (str) {
        return str !== '' && float.test(str);
    };

    validator.isDivisibleBy = function (str, num) {
        return validator.toFloat(str) % validator.toInt(num) === 0;
    };

    validator.isNull = function (str) {
        return str.length === 0;
    };

    validator.isLength = function (str, min, max) {
        var surrogatePairs = str.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]/g) || [];
        var len = str.length - surrogatePairs.length;
        return len >= min && (typeof max === 'undefined' || len <= max);
    };

    validator.isByteLength = function (str, min, max) {
        return str.length >= min && (typeof max === 'undefined' || str.length <= max);
    };

    validator.isUUID = function (str, version) {
        var pattern = uuid[version ? version : 'all'];
        return pattern && pattern.test(str);
    };

    validator.isDate = function (str) {
        return !isNaN(Date.parse(str));
    };

    validator.isAfter = function (str, date) {
        var comparison = validator.toDate(date || new Date())
          , original = validator.toDate(str);
        return !!(original && comparison && original > comparison);
    };

    validator.isBefore = function (str, date) {
        var comparison = validator.toDate(date || new Date())
          , original = validator.toDate(str);
        return original && comparison && original < comparison;
    };

    validator.isIn = function (str, options) {
        if (!options || typeof options.indexOf !== 'function') {
            return false;
        }
        if (Object.prototype.toString.call(options) === '[object Array]') {
            var array = [];
            for (var i = 0, len = options.length; i < len; i++) {
                array[i] = validator.toString(options[i]);
            }
            options = array;
        }
        return options.indexOf(str) >= 0;
    };

    validator.isCreditCard = function (str) {
        var sanitized = str.replace(/[^0-9]+/g, '');
        if (!creditCard.test(sanitized)) {
            return false;
        }
        var sum = 0, digit, tmpNum, shouldDouble;
        for (var i = sanitized.length - 1; i >= 0; i--) {
            digit = sanitized.substring(i, (i + 1));
            tmpNum = parseInt(digit, 10);
            if (shouldDouble) {
                tmpNum *= 2;
                if (tmpNum >= 10) {
                    sum += ((tmpNum % 10) + 1);
                } else {
                    sum += tmpNum;
                }
            } else {
                sum += tmpNum;
            }
            shouldDouble = !shouldDouble;
        }
        return !!((sum % 10) === 0 ? sanitized : false);
    };

    validator.isISBN = function (str, version) {
        version = validator.toString(version);
        if (!version) {
            return validator.isISBN(str, 10) || validator.isISBN(str, 13);
        }
        var sanitized = str.replace(/[\s-]+/g, '')
          , checksum = 0, i;
        if (version === '10') {
            if (!isbn10Maybe.test(sanitized)) {
                return false;
            }
            for (i = 0; i < 9; i++) {
                checksum += (i + 1) * sanitized.charAt(i);
            }
            if (sanitized.charAt(9) === 'X') {
                checksum += 10 * 10;
            } else {
                checksum += 10 * sanitized.charAt(9);
            }
            if ((checksum % 11) === 0) {
                return !!sanitized;
            }
        } else  if (version === '13') {
            if (!isbn13Maybe.test(sanitized)) {
                return false;
            }
            var factor = [ 1, 3 ];
            for (i = 0; i < 12; i++) {
                checksum += factor[i % 2] * sanitized.charAt(i);
            }
            if (sanitized.charAt(12) - ((10 - (checksum % 10)) % 10) === 0) {
                return !!sanitized;
            }
        }
        return false;
    };

    validator.isJSON = function (str) {
        try {
            JSON.parse(str);
        } catch (e) {
            return false;
        }
        return true;
    };

    validator.isMultibyte = function (str) {
        return multibyte.test(str);
    };

    validator.isAscii = function (str) {
        return ascii.test(str);
    };

    validator.isFullWidth = function (str) {
        return fullWidth.test(str);
    };

    validator.isHalfWidth = function (str) {
        return halfWidth.test(str);
    };

    validator.isVariableWidth = function (str) {
        return fullWidth.test(str) && halfWidth.test(str);
    };

    validator.isSurrogatePair = function (str) {
        return surrogatePair.test(str);
    };

    validator.isBase64 = function (str) {
        return base64.test(str);
    };

    validator.isMongoId = function (str) {
        return validator.isHexadecimal(str) && str.length === 24;
    };

    validator.ltrim = function (str, chars) {
        var pattern = chars ? new RegExp('^[' + chars + ']+', 'g') : /^\s+/g;
        return str.replace(pattern, '');
    };

    validator.rtrim = function (str, chars) {
        var pattern = chars ? new RegExp('[' + chars + ']+$', 'g') : /\s+$/g;
        return str.replace(pattern, '');
    };

    validator.trim = function (str, chars) {
        var pattern = chars ? new RegExp('^[' + chars + ']+|[' + chars + ']+$', 'g') : /^\s+|\s+$/g;
        return str.replace(pattern, '');
    };

    validator.escape = function (str) {
        return (str.replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;'));
    };

    validator.stripLow = function (str, keep_new_lines) {
        var chars = keep_new_lines ? '\x00-\x09\x0B\x0C\x0E-\x1F\x7F' : '\x00-\x1F\x7F';
        return validator.blacklist(str, chars);
    };

    validator.whitelist = function (str, chars) {
        return str.replace(new RegExp('[^' + chars + ']+', 'g'), '');
    };

    validator.blacklist = function (str, chars) {
        return str.replace(new RegExp('[' + chars + ']+', 'g'), '');
    };

    var default_normalize_email_options = {
        lowercase: true
    };

    validator.normalizeEmail = function (email, options) {
        options = merge(options, default_normalize_email_options);
        if (!validator.isEmail(email)) {
            return false;
        }
        var parts = email.split('@', 2);
        parts[1] = parts[1].toLowerCase();
        if (options.lowercase) {
            parts[0] = parts[0].toLowerCase();
        }
        if (parts[1] === 'gmail.com' || parts[1] === 'googlemail.com') {
            if (!options.lowercase) {
                parts[0] = parts[0].toLowerCase();
            }
            parts[0] = parts[0].replace(/\./g, '').split('+')[0];
            parts[1] = 'gmail.com';
        }
        return parts.join('@');
    };

    function merge(obj, defaults) {
        obj = obj || {};
        for (var key in defaults) {
            if (typeof obj[key] === 'undefined') {
                obj[key] = defaults[key];
            }
        }
        return obj;
    }

    validator.init();

    return validator;

});

},{}],90:[function(require,module,exports){
(function (global){
;(function(undefined) {
	"use strict";

	var $scope
	, conflict, conflictResolution = [];
	if (typeof global == 'object' && global) {
		$scope = global;
	} else if (typeof window !== 'undefined'){
		$scope = window;
	} else {
		$scope = {};
	}
	conflict = $scope.DeepDiff;
	if (conflict) {
		conflictResolution.push(
			function() {
				if ('undefined' !== typeof conflict && $scope.DeepDiff === accumulateDiff) {
					$scope.DeepDiff = conflict;
					conflict = undefined;
				}
			});
	}

	// nodejs compatible on server side and in the browser.
  function inherits(ctor, superCtor) {
    ctor.super_ = superCtor;
    ctor.prototype = Object.create(superCtor.prototype, {
      constructor: {
        value: ctor,
        enumerable: false,
        writable: true,
        configurable: true
      }
    });
  }

  function Diff(kind, path) {
  	Object.defineProperty(this, 'kind', { value: kind, enumerable: true });
  	if (path && path.length) {
  		Object.defineProperty(this, 'path', { value: path, enumerable: true });
  	}
  }

  function DiffEdit(path, origin, value) {
  	DiffEdit.super_.call(this, 'E', path);
  	Object.defineProperty(this, 'lhs', { value: origin, enumerable: true });
  	Object.defineProperty(this, 'rhs', { value: value, enumerable: true });
  }
  inherits(DiffEdit, Diff);

  function DiffNew(path, value) {
  	DiffNew.super_.call(this, 'N', path);
  	Object.defineProperty(this, 'rhs', { value: value, enumerable: true });
  }
  inherits(DiffNew, Diff);

  function DiffDeleted(path, value) {
  	DiffDeleted.super_.call(this, 'D', path);
  	Object.defineProperty(this, 'lhs', { value: value, enumerable: true });
  }
  inherits(DiffDeleted, Diff);

  function DiffArray(path, index, item) {
  	DiffArray.super_.call(this, 'A', path);
  	Object.defineProperty(this, 'index', { value: index, enumerable: true });
  	Object.defineProperty(this, 'item', { value: item, enumerable: true });
  }
  inherits(DiffArray, Diff);

  function arrayRemove(arr, from, to) {
  	var rest = arr.slice((to || from) + 1 || arr.length);
  	arr.length = from < 0 ? arr.length + from : from;
  	arr.push.apply(arr, rest);
  	return arr;
  }

  function deepDiff(lhs, rhs, changes, prefilter, path, key, stack) {
  	path = path || [];
  	var currentPath = path.slice(0);
  	if (key) {
  		if (prefilter && prefilter(currentPath, key)) return;
  		currentPath.push(key);
  	}
  	var ltype = typeof lhs;
  	var rtype = typeof rhs;
  	if (ltype === 'undefined') {
  		if (rtype !== 'undefined') {
  			changes(new DiffNew(currentPath, rhs ));
  		}
  	} else if (rtype === 'undefined') {
  		changes(new DiffDeleted(currentPath, lhs));
  	} else if (ltype !== rtype) {
  		changes(new DiffEdit(currentPath, lhs, rhs));
  	} else if (lhs instanceof Date && rhs instanceof Date && ((lhs-rhs) != 0) ) {
  		changes(new DiffEdit(currentPath, lhs, rhs));
  	} else if (ltype === 'object' && lhs != null && rhs != null) {
  		stack = stack || [];
  		if (stack.indexOf(lhs) < 0) {
  			stack.push(lhs);
  			if (Array.isArray(lhs)) {
  				var i
  				, len = lhs.length
  				, ea = function(d) {
  					changes(new DiffArray(currentPath, i, d));
  				};
  				for(i = 0; i < lhs.length; i++) {
  					if (i >= rhs.length) {
  						changes(new DiffArray(currentPath, i, new DiffDeleted(undefined, lhs[i])));
  					} else {
  						deepDiff(lhs[i], rhs[i], ea, prefilter, [], null, stack);
  					}
  				}
  				while(i < rhs.length) {
  					changes(new DiffArray(currentPath, i, new DiffNew(undefined, rhs[i++])));
  				}
  			} else {
  				var akeys = Object.keys(lhs);
  				var pkeys = Object.keys(rhs);
  				akeys.forEach(function(k) {
  					var i = pkeys.indexOf(k);
  					if (i >= 0) {
  						deepDiff(lhs[k], rhs[k], changes, prefilter, currentPath, k, stack);
  						pkeys = arrayRemove(pkeys, i);
  					} else {
  						deepDiff(lhs[k], undefined, changes, prefilter, currentPath, k, stack);
  					}
  				});
  				pkeys.forEach(function(k) {
  					deepDiff(undefined, rhs[k], changes, prefilter, currentPath, k, stack);
  				});
  			}
  			stack.length = stack.length - 1;
  		}
  	} else if (lhs !== rhs) {
      if(!(ltype === "number" && isNaN(lhs) && isNaN(rhs))) {
  		  changes(new DiffEdit(currentPath, lhs, rhs));
      }
  	}
  }

  function accumulateDiff(lhs, rhs, prefilter, accum) {
  	accum = accum || [];
  	deepDiff(lhs, rhs,
  		function(diff) {
  			if (diff) {
  				accum.push(diff);
  			}
  		},
  		prefilter);
  	return (accum.length) ? accum : undefined;
  }

	function applyArrayChange(arr, index, change) {
		if (change.path && change.path.length) {
			// the structure of the object at the index has changed...
			var it = arr[index], i, u = change.path.length - 1;
			for(i = 0; i < u; i++){
				it = it[change.path[i]];
			}
			switch(change.kind) {
				case 'A':
					// Array was modified...
					// it will be an array...
					applyArrayChange(it[change.path[i]], change.index, change.item);
					break;
				case 'D':
					// Item was deleted...
					delete it[change.path[i]];
					break;
				case 'E':
				case 'N':
					// Item was edited or is new...
					it[change.path[i]] = change.rhs;
					break;
			}
		} else {
			// the array item is different...
			switch(change.kind) {
				case 'A':
					// Array was modified...
					// it will be an array...
					applyArrayChange(arr[index], change.index, change.item);
					break;
				case 'D':
					// Item was deleted...
					arr = arrayRemove(arr, index);
					break;
				case 'E':
				case 'N':
					// Item was edited or is new...
					arr[index] = change.rhs;
					break;
			}
		}
		return arr;
	}

	function applyChange(target, source, change) {
		if (!(change instanceof Diff)) {
			throw new TypeError('[Object] change must be instanceof Diff');
		}
		if (target && source && change) {
			var it = target, i, u;
			u = change.path.length - 1;
			for(i = 0; i < u; i++){
				if (typeof it[change.path[i]] === 'undefined') {
					it[change.path[i]] = {};
				}
				it = it[change.path[i]];
			}
			switch(change.kind) {
				case 'A':
					// Array was modified...
					// it will be an array...
					applyArrayChange(it[change.path[i]], change.index, change.item);
					break;
				case 'D':
					// Item was deleted...
					delete it[change.path[i]];
					break;
				case 'E':
				case 'N':
					// Item was edited or is new...
					it[change.path[i]] = change.rhs;
					break;
				}
			}
		}

	function applyDiff(target, source, filter) {
		if (target && source) {
			var onChange = function(change) {
				if (!filter || filter(target, source, change)) {
					applyChange(target, source, change);
				}
			};
			deepDiff(target, source, onChange);
		}
	}

	Object.defineProperties(accumulateDiff, {

		diff: { value: accumulateDiff, enumerable:true },
		observableDiff: { value: deepDiff, enumerable:true },
		applyDiff: { value: applyDiff, enumerable:true },
		applyChange: { value: applyChange, enumerable:true },
		isConflict: { get: function() { return 'undefined' !== typeof conflict; }, enumerable: true },
		noConflict: {
			value: function () {
				if (conflictResolution) {
					conflictResolution.forEach(function (it) { it(); });
					conflictResolution = null;
				}
				return accumulateDiff;
			},
			enumerable: true
		}
	});

	if (typeof module != 'undefined' && module && typeof exports == 'object' && exports && module.exports === exports) {
		module.exports = accumulateDiff; // nodejs
	} else {
		$scope.DeepDiff = accumulateDiff; // other... browser?
	}
}());


}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{}],91:[function(require,module,exports){
module.exports = {

  // Used to identify a function as a switchback.
  telltale: {
    key: '_TELLTALE',
    value: 'a94hgd9gal2gl2bmc,=1aga'
  }
};

},{}],92:[function(require,module,exports){
/**
 * Module dependencies
 */
var util = require('util');
var _ = require('lodash');
var constants = require('./constants');



/**
 * factory
 *
 * @return {Switchback}
 *
 * An anonymous function is used as the base for switchbacks so that
 * they are both dereferenceable AND callable.  This allows functions
 * which accept switchback definitions to maintain compatibility with
 * standard node callback conventions (which are better for many situations).
 *
 * This also means that instantiated switchbacks may be passed interchangably
 * into functions expecting traditional node callbacks, and everything will
 * "just work".
 */

module.exports = function(callbackContext) {

  var _switch = function( /* err, arg1, arg2, ..., argN */ ) {
    var args = Array.prototype.slice.call(arguments);

    // Trigger error handler
    var err = args[0];
    if (err) {
      return _switch.error.apply(callbackContext || this, args);
    }
    return _switch.success.apply(callbackContext || this, args.slice(1));
  };

  // Mark switchback function so it can be identified for tests
  _switch[constants.telltale.key] = constants.telltale.value;

  // Mix in non-enumerable `.inspect()` method
  Object.defineProperty(this, 'inspect', { enumerable: false, writable: true });
  _switch.inspect = function () { return '[Switchback]'; };

  return _switch;
};

},{"./constants":91,"lodash":"lodash","util":"util"}],93:[function(require,module,exports){
/**
 * Module dependencies
 */
var _ = require('lodash');
var util = require('util');
var factory = require('./factory');
var normalize = require('./normalize');
var redirect = require('./redirect');
var wildcard = require('./wildcard');
var constants = require('./constants');
var EventEmitter = require('events').EventEmitter;


/**
 * `switchback`
 *
 * Switching utility which builds and returns a handler which is capable
 * calling one of several callbacks.
 *
 * @param {Object|Function} callback
 *			- a switchback definition obj or a standard 1|2-ary node callback function.
 * @param {Object} [defaultHandlers]
 *			- '*': supply a special callback for when none of the other handlers match
 *			- a string can be supplied, e.g. {'invalid': 'error'}, to "forward" one handler to another
 *			- otherwise a function should be supplied, e.g. { 'error': res.serverError }
 * @param {Object} [callbackContext]
 *			- optional `this` context for callbacks
 */

var switchback = function(callback, defaultHandlers, callbackContext) {

  // Track whether a single tick of the event loop has elapsed yet since
  // this switchback was instantiated.
  var atLeastOneTickHasElapsed;
  setTimeout(function (){
    atLeastOneTickHasElapsed = true;
  }, 0);

  // Build switchback
  var Switchback = factory(callbackContext);

  // If callback is not a function or an object, I don't know wtf it is,
  // so let's just return early before anything bad happens, hmm?
  if (!_.isObject(callback) && !_.isFunction(callback)) {
    // Actually let's not.
    // Instead, make the new switchback an EventEmitter
    var e = new EventEmitter();
    Switchback.emit = function() {
      var args = Array.prototype.slice.call(arguments);

      // This will invoke the final runtime function
      //
      // But first ensure at least a single cycle of the event loop has elapsed
      // since this switchback was instantiated
      if (atLeastOneTickHasElapsed) {
        return e.emit.apply(e, args);
      }
      else {
        setTimeout(function (){
          return e.emit.apply(e, args);
        }, 0);
      }
    };
    Switchback.on = function(evName, handler) {
      return e.on.apply(e, Array.prototype.slice.call(arguments));
    };

    // Then emit the appropriate event when the switchback is triggered.
    callback = {
      error: function(err) {
        Switchback.emit('error', err);
      },
      success: function( /*...*/ ) {
        Switchback.emit.apply(e, ['success'].concat(Array.prototype.slice.call(arguments)));
      }
    };
  }



  // Normalize `callback` to a switchback definition object.
  callback = normalize.callback(callback, callbackContext);

  // Attach specified handlers
  _.extend(Switchback, callback);



  // Supply a handful of default handlers to provide better error messages.
  var getWildcardCaseHandler = function(caseName, err) {
    return function unknownCase( /* ... */ ) {
      var args = Array.prototype.slice.call(arguments);
      err = (args[0] ? util.inspect(args[0]) + '        ' : '') + (err ? '(' + (err || '') + ')' : '');

      if (_.isObject(defaultHandlers) && _.isFunction(defaultHandlers['*'])) {
        return defaultHandlers['*'](err);
      } else throw new Error(err);
    };
  };

  // redirect any handler defaults specified as strings
  if (_.isObject(defaultHandlers)) {
    defaultHandlers = _.mapValues(defaultHandlers, function(handler, name) {
      if (_.isFunction(handler)) return handler;

      // Closure which will resolve redirected handler
      return function() {
        var runtimeHandler = handler;
        var runtimeArgs = Array.prototype.slice.call(arguments);
        var runtimeCtx = callbackContext || this;

        // Track previous handler to make usage error messages more useful.
        var prevHandler;

        // No more than 5 "redirects" allowed (prevents never-ending loop)
        var MAX_FORWARDS = 5;
        var numIterations = 0;
        do {
          prevHandler = runtimeHandler;
          runtimeHandler = Switchback[runtimeHandler];
          // console.log('redirecting '+name+' to "'+prevHandler +'"-- got ' + runtimeHandler);
          numIterations++;
        }
        while (_.isString(runtimeHandler) && numIterations <= MAX_FORWARDS);

        if (numIterations > MAX_FORWARDS) {
          throw new Error('Default handlers object (' + util.inspect(defaultHandlers) + ') has a cyclic redirect.');
        }

        // Redirects to unknown handler
        if (!_.isFunction(runtimeHandler)) {
          runtimeHandler = getWildcardCaseHandler(runtimeHandler, '`' + name + '` case triggered, but no handler was implemented.');
        }

        // Invoke final runtime function
        //
        // But first ensure at least a single cycle of the event loop has elapsed
        // since this switchback was instantiated
        if (atLeastOneTickHasElapsed) {
          runtimeHandler.apply(runtimeCtx, runtimeArgs);
        }
        // Otherwise wait until that happens and then invoke the runtime function
        else {
          setTimeout(function (){
            runtimeHandler.apply(runtimeCtx, runtimeArgs);
          }, 0);
        }

      };
    });
  }

  _.defaults(Switchback, defaultHandlers, {
    success: getWildcardCaseHandler('success', '`success` case triggered, but no handler was implemented.'),
    error: getWildcardCaseHandler('error', '`error` case triggered, but no handler was implemented.'),
    invalid: getWildcardCaseHandler('invalid', '`invalid` case triggered, but no handler was implemented.')
  });

  return Switchback;
};


/**
 * `isSwitchback`
 *
 * @param  {*}  something
 * @return {Boolean}           [whether `something` is a valid switchback instance]
 */
switchback.isSwitchback = function(something) {
  return _.isObject(something) && something[constants.telltale.key] === constants.telltale.value;
};


module.exports = switchback;

},{"./constants":91,"./factory":92,"./normalize":94,"./redirect":95,"./wildcard":96,"events":"events","lodash":"lodash","util":"util"}],94:[function(require,module,exports){
/**
 * Module dependencies
 */
var _ = require('lodash');
var util = require('util');



module.exports = {


  /**
   * `normalize.callback( callback )`
   *
   * If `callback` is provided as a function, transform it into
   * a "Switchback Definition Object" by using modified copies
   * of the original callback function as error/success handlers.
   *
   * @param  {Function|Object} callback [cb function or switchback def]
   * @return {Object}                   [switchback def]
   */
  callback: function _normalizeCallback(callback, callbackContext) {

    if (_.isFunction(callback)) {
      var _originalCallbackFn = callback;
      callback = {
        success: function() {
          // Shift arguments over (prepend a `null` first argument)
          // so this will never be perceived as an `err` when it's
          // used as a traditional callback
          var args = Array.prototype.slice.call(arguments);
          args.unshift(null);
          _originalCallbackFn.apply(callbackContext || this, args);
        },
        error: function() {
          // Ensure a first arg exists (err)
          // (if not, prepend an anonymous Error)
          var args = Array.prototype.slice.call(arguments);
          if (!args[0]) {
            args[0] = new Error();
          }
          _originalCallbackFn.apply(callbackContext || this, args);
        }
      };
      callback = callback || {};
    }
    return callback;
  }
};

},{"lodash":"lodash","util":"util"}],95:[function(require,module,exports){

},{}],96:[function(require,module,exports){
module.exports=require(95)
},{"/media/ext/mnt/home/cha0s6983/dev/code/js/shrub/node_modules/waterline-browser/node_modules/node-switchback/lib/redirect.js":95}],97:[function(require,module,exports){
module.exports = require('./lib');
},{"./lib":102}],98:[function(require,module,exports){
// See http://stackoverflow.com/a/3143231/486547
module.exports = /(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d+([+-][0-2]\d:[0-5]\d|Z))|(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d([+-][0-2]\d:[0-5]\d|Z))|(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d([+-][0-2]\d:[0-5]\d|Z))/;

},{}],99:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash')
  , util = require('util');


/**
 * Apply a `limit` modifier to `data` using `limit`.
 *
 * @param  { Object[] }  data
 * @param  { Integer }    limit
 * @return { Object[] }
 */
module.exports = function (data, limit) {
  if( limit === undefined || !data || limit === 0) return data;
  return _.first(data, limit);
};

},{"lodash":"lodash","util":"util"}],100:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash')
  , util = require('util');


/**
 * Apply a `skip` modifier to `data` using `numToSkip`.
 * 
 * @param  { Object[] }  data
 * @param  { Integer }   numToSkip
 * @return { Object[] }
 */
module.exports = function (data, numToSkip) {

  if(!numToSkip || !data) return data;
  
  // Ignore the first `numToSkip` tuples
  return _.rest(data, numToSkip);
};

},{"lodash":"lodash","util":"util"}],101:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');
var X_ISO_DATE = require('../X_ISO_DATE.constant');



/**
 * Apply a(nother) `where` filter to `data`
 *
 * @param  { Object[] }  data
 * @param  { Object }    where
 * @return { Object[] }
 */
module.exports = function (data, where) {
  if( !data ) return data;
  return _.filter(data, function(tuple) {
    return matchSet(tuple, where);
  });
};






//////////////////////////
///
/// private methods   ||
///                   \/
///
//////////////////////////


// Match a model against each criterion in a criteria query
function matchSet(model, criteria, parentKey) {

  // Null or {} WHERE query always matches everything
  if(!criteria || _.isEqual(criteria, {})) return true;

  // By default, treat entries as AND
  return _.all(criteria, function(criterion, key) {
    return matchItem(model, key, criterion, parentKey);
  });
}


function matchOr(model, disjuncts) {
  var outcomes = [];
  _.each(disjuncts, function(criteria) {
    if(matchSet(model, criteria)) outcomes.push(true);
  });

  var outcome = outcomes.length > 0 ? true : false;
  return outcome;
}

function matchAnd(model, conjuncts) {
  var outcome = true;
  _.each(conjuncts, function(criteria) {
    if(!matchSet(model, criteria)) outcome = false;
  });
  return outcome;
}

function matchLike(model, criteria) {
  for(var key in criteria) {
    // Return false if no match is found
    if (!checkLike(model[key], criteria[key])) return false;
  }
  return true;
}

function matchNot(model, criteria) {
  return !matchSet(model, criteria);
}

function matchItem(model, key, criterion, parentKey) {

  // Handle special attr query
  if (parentKey) {

    if (key === 'equals' || key === '=' || key === 'equal') {
      return matchLiteral(model,parentKey,criterion, compare['=']);
    }
    else if (key === 'not' || key === '!') {

      // Check for Not In
      if(Array.isArray(criterion)) {

        var match = false;
        criterion.forEach(function(val) {
          if(compare['='](model[parentKey], val)) {
            match = true;
          }
        });

        return match ? false : true;
      }

      return matchLiteral(model,parentKey,criterion, compare['!']);
    }
    else if (key === 'greaterThan' || key === '>') {
      return matchLiteral(model,parentKey,criterion, compare['>']);
    }
    else if (key === 'greaterThanOrEqual' || key === '>=')  {
      return matchLiteral(model,parentKey,criterion, compare['>=']);
    }
    else if (key === 'lessThan' || key === '<')  {
      return matchLiteral(model,parentKey,criterion, compare['<']);
    }
    else if (key === 'lessThanOrEqual' || key === '<=')  {
      return matchLiteral(model,parentKey,criterion, compare['<=']);
    }
    else if (key === 'startsWith') return matchLiteral(model,parentKey,criterion, checkStartsWith);
    else if (key === 'endsWith') return matchLiteral(model,parentKey,criterion, checkEndsWith);
    else if (key === 'contains') return matchLiteral(model,parentKey,criterion, checkContains);
    else if (key === 'like') return matchLiteral(model,parentKey,criterion, checkLike);
    else throw new Error ('Invalid query syntax!');
  }
  else if(key.toLowerCase() === 'or') {
    return matchOr(model, criterion);
  } else if(key.toLowerCase() === 'not') {
    return matchNot(model, criterion);
  } else if(key.toLowerCase() === 'and') {
    return matchAnd(model, criterion);
  } else if(key.toLowerCase() === 'like') {
    return matchLike(model, criterion);
  }
  // IN query
  else if(_.isArray(criterion)) {
    return _.any(criterion, function(val) {
      return compare['='](model[key], val);
    });
  }

  // Special attr query
  else if (_.isObject(criterion) && validSubAttrCriteria(criterion)) {
    // Attribute is being checked in a specific way
    return matchSet(model, criterion, key);
  }

  // Otherwise, try a literal match
  else return matchLiteral(model,key,criterion, compare['=']);

}

// Comparison fns
var compare = {

  // Equalish
  '=' : function (a,b) {
    var x = normalizeComparison(a,b);
    return x[0] == x[1];
  },

  // Not equalish
  '!' : function (a,b) {
    var x = normalizeComparison(a,b);
    return x[0] != x[1];
  },
  '>' : function (a,b) {
    var x = normalizeComparison(a,b);
    return x[0] > x[1];
  },
  '>=': function (a,b) {
    var x = normalizeComparison(a,b);
    return x[0] >= x[1];
  },
  '<' : function (a,b) {
    var x = normalizeComparison(a,b);
    return x[0] < x[1];
  },
  '<=': function (a,b) {
    var x = normalizeComparison(a,b);
    return x[0] <= x[1];
  }
};

// Prepare two values for comparison
function normalizeComparison(a,b) {

  if(_.isUndefined(a) || a === null) a = '';
  if(_.isUndefined(b) || b === null) b = '';

  if (_.isString(a) && _.isString(b)) {
    a = a.toLowerCase();
    b = b.toLowerCase();
  }

  // If Comparing dates, keep them as dates
  if(_.isDate(a) && _.isDate(b)) {
    return [a.getTime(), b.getTime()];
  }
  // Otherwise convert them to ISO strings
  if (_.isDate(a)) { a = a.toISOString(); }
  if (_.isDate(b)) { b = b.toISOString(); }


  // Stringify for comparisons- except for numbers, null, and undefined
  if (!_.isNumber(a)) {
    a = typeof a.toString !== 'undefined' ? a.toString() : '' + a;
  }
  if (!_.isNumber(b)) {
    b = typeof b.toString !== 'undefined' ? b.toString() : '' + b;
  }

  // If comparing date-like things, treat them like dates
  if (_.isString(a) && _.isString(b) && a.match(X_ISO_DATE) && b.match(X_ISO_DATE)) {
    return ([new Date(a).getTime(), new Date(b).getTime()]);
  }

  return [a,b];
}

// Return whether this criteria is valid as an object inside of an attribute
function validSubAttrCriteria(c) {

  if(!_.isObject(c)) return false;

  var valid = false;
  var validAttributes = [
    'equals', 'not', 'greaterThan', 'lessThan', 'greaterThanOrEqual', 'lessThanOrEqual',
    '<', '<=', '!', '>', '>=', 'startsWith', 'endsWith', 'contains', 'like'];

  _.each(validAttributes, function(attr) {
    if(hasOwnProperty(c, attr)) valid = true;
  });

  return valid;
}

// Returns whether this value can be successfully parsed as a finite number
function isNumbery (value) {
  if(_.isDate(value)) return false;
  return Math.pow(+value, 2) > 0;
}

// matchFn => the function that will be run to check for a match between the two literals
function matchLiteral(model, key, criterion, matchFn) {

  var val = _.cloneDeep(model[key]);

  // If the criterion are both parsable finite numbers, cast them
  if(isNumbery(criterion) && isNumbery(val)) {
    criterion = +criterion;
    val = +val;
  }

  // ensure the key attr exists in model
  if(!model.hasOwnProperty(key)) return false;
  if(_.isUndefined(criterion)) return false;

  // ensure the key attr matches model attr in model
  if((!matchFn(val,criterion))) {
    return false;
  }

  // Otherwise this is a match
  return true;
}


function checkStartsWith (value, matchString) {
  // console.log('CheCKING startsWith ', value, 'against matchString:', matchString, 'result:',sqlLikeMatch(value, matchString));
  return sqlLikeMatch(value, matchString + '%');
}
function checkEndsWith (value, matchString) {
  return sqlLikeMatch(value, '%' + matchString);
}
function checkContains (value, matchString) {
  return sqlLikeMatch(value, '%' + matchString + '%');
}
function checkLike (value, matchString) {
  // console.log('CheCKING  ', value, 'against matchString:', matchString, 'result:',sqlLikeMatch(value, matchString));
  return sqlLikeMatch(value, matchString);
}

function sqlLikeMatch (value,matchString) {

  if(_.isRegExp(matchString)) {
    // awesome
  } else if(_.isString(matchString)) {
    // Handle escaped percent (%) signs
    matchString = matchString.replace(/%%%/g, '%');

    // Escape regex
    matchString = escapeRegExp(matchString);

    // Replace SQL % match notation with something the ECMA regex parser can handle
    matchString = matchString.replace(/([^%]*)%([^%]*)/g, '$1.*$2');

    // Case insensitive by default
    // TODO: make this overridable
    var modifiers = 'i';

    matchString = new RegExp('^' + matchString + '$', modifiers);
  }
  // Unexpected match string!
  else {
    console.error('matchString:');
    console.error(matchString);
    throw new Error('Unexpected match string: ' + matchString + ' Please use a regexp or string.');
  }

  // Deal with non-strings
  if(_.isNumber(value)) value = '' + value;
  else if(_.isBoolean(value)) value = value ? 'true' : 'false';
  else if(!_.isString(value)) {
    // Ignore objects, arrays, null, and undefined data for now
    // (and maybe forever)
    return false;
  }

  // Check that criterion attribute and is at least similar to the model's value for that attr
  if(!value.match(matchString)) {
    return false;
  }
  return true;
}

function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
}



/**
 * Safer helper for hasOwnProperty checks
 *
 * @param {Object} obj
 * @param {String} prop
 * @return {Boolean}
 * @api public
 */

var hop = Object.prototype.hasOwnProperty;
function hasOwnProperty(obj, prop) {
  return hop.call(obj, prop);
}

},{"../X_ISO_DATE.constant":98,"lodash":"lodash"}],102:[function(require,module,exports){
(function (__dirname){
/**
 * Module dependencies
 */

var _ = require('lodash');
var util = require('util');
var path = require('path');


module.exports = _.extend(

  // Provide all-in-one top-level function
  require('./query'),

  // but also expose direct access
  // to all filters and projections.
  {
    where: require('./filters/where'),
    limit: require('./filters/limit'),
    skip: require('./filters/skip'),
    sort: require('./sort'),

    // Projections and aggregations are not-yet-officially supported:
    groupBy: require('./projections/groupBy'),
    select: require('./projections/select')

    // Joins are currently supported by Waterline core:
    // , populate : require('./projections/populate')
    // , leftJoin : require('./projections/leftJoin')
    // , join     : require('./projections/join')
    // , rightJoin : require('./projections/rightJoin')

  });



/**
 * Load CommonJS submodules from the specified
 * relative path.
 *
 * @return {Object}
 */
function loadSubModules(relPath) {
  return require('include-all')({
    dirname: path.resolve(__dirname, relPath),
    filter: /(.+)\.js$/
  });
}

}).call(this,"/node_modules/waterline-browser/node_modules/waterline-criteria/lib")
},{"./filters/limit":99,"./filters/skip":100,"./filters/where":101,"./projections/groupBy":103,"./projections/select":104,"./query":105,"./sort":106,"include-all":107,"lodash":"lodash","path":116,"util":"util"}],103:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash')
  , util = require('util');


/**
 * Partition the tuples in `filteredData` into buckets via `groupByAttribute`.
 * Works with aggregations to allow for powerful reporting queries.
 * 
 * @param  { Object[] }  filteredData
 * @param  { String }    groupByAttribute
 * @return { Object[] }
 */
module.exports = function (filteredData, groupByAttribute) {
  return filteredData;
};

},{"lodash":"lodash","util":"util"}],104:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');
var util = require('util');


/**
 * Project `tuples` on `fields`.
 * 
 * @param  { Object[] }  tuples    [i.e. filteredData]
 * @param  { String[]/Object{} }  fields    [i.e. schema]
 * @return { Object[] }
 */
function select (tuples, fields) {

  // Expand splat shortcut syntax
  if (fields === '*') {
    fields = { '*': true };
  }

  // If `fields` are not an Object or Array, don't modify the output.
  if (typeof fields !== 'object') return tuples;

  // If `fields` are specified as an Array, convert them to an Object.
  if (_.isArray(fields)) {
    fields = _.reduce(fields, function arrayToObj(memo, attrName) {
      memo[attrName] = true;
      return memo;
    }, {});
  }

  // If the '*' key is specified, the projection algorithm is flipped:
  // only keys which are explicitly set to `false` will be excluded--
  // all other keys will be left alone (this lasts until the recursive step.)
  var hasSplat = !!fields['*'];
  var fieldsToExplicitlyOmit = _(fields).where(function _areExplicitlyFalse (v,k){ return v === false; }).keys();
  delete fields['*'];


  // Finally, select fields from tuples.
  return _.map(tuples, function (tuple) {

    // Select the requested attributes of the tuple
    if (hasSplat) {
      tuple = _.omit(tuple, function (value, attrName){
        return _.contains(fieldsToExplicitlyOmit, attrName);
      });
    }
    else {
      tuple = _.pick(tuple, Object.keys(fields));
    }


    // || NOTE THAT THIS APPROACH WILL CHANGE IN AN UPCOMING RELEASE
    // \/ TO MATCH THE CONVENTIONS ESTABLISHED IN WL2.

    // Take recursive step if necessary to support nested
    // SELECT clauses (NOT nested modifiers- more like nested
    // WHEREs)
    // 
    // e.g.:
    // like this:
    //   -> { select: { pet: { collarSize: true } } }
    //   
    // not this:
    //   -> { select: { pet: { select: { collarSize: true } } } }
    //
    _.each(fields, function (subselect, attrName) {

      if (typeof subselect === 'object') {
        if (_.isArray(tuple[attrName])) {
          tuple[attrName] = select(tuple[attrName], subselect);
        }
        else if (_.isObject(tuple[attrName])) {
          tuple[attrName] = select([tuple[attrName]], subselect)[0];
        }
      }
    });

    return tuple;
  });
}

module.exports = select;

},{"lodash":"lodash","util":"util"}],105:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');
var util = require('util');
var _where = require('./filters/where');
var _limit = require('./filters/limit');
var _skip = require('./filters/skip');
var _select = require('./projections/select');
var _groupBy = require('./projections/groupBy');
var _sort = require('./sort');



/**
 * Filter/aggregate/partition/map the tuples known as `classifier`
 * in `data` using `criteria` (a Waterline criteria object)
 * 
 * @param  { Object[] }           data
 * @param  { Object }             criteria         [the Waterline criteria object- complete w/ `where`, `limit`, `sort, `skip`, and `joins`]
 * 
 * @return { Integer | Object | Object[] }
 */

module.exports = function query ( /* classifier|tuples, data|criteria [, criteria] */ ) {
  
  // Embed an `INDEX_IN_ORIG_DATA` for each tuple to remember its original index
  // within `data`.  At the end, we'll lookup the `INDEX_IN_ORIG_DATA` for each tuple
  // and expose it as part of our results.
  var INDEX_IN_ORIG_DATA = '.(ørigindex)';

  var tuples, classifier, data, criteria;

  // If no classifier is provided, and data was specified as an array
  // instead of an object, infer tuples from the array
  if (_.isArray(arguments[0]) && !arguments[2]) {
    tuples = arguments[0];
    criteria = arguments[1];
  }
  // If all three arguments were supplied:
  // get tuples of type `classifier` (i.e. SELECT * FROM __________)
  // and clone 'em.
  else {
    classifier = arguments[0];
    data = arguments[1];
    criteria = arguments[2];
    tuples = data[classifier];
  }

  // Clone tuples to avoid dirtying things up
  tuples = _.cloneDeep(tuples);

  // Embed `INDEX_IN_ORIG_DATA` in each tuple
  _.each(tuples, function(tuple, i) {
    tuple[INDEX_IN_ORIG_DATA] = i;
  });

  // Ensure criteria object exists
  criteria = criteria || {};

  // Query and return result set using criteria
  tuples = _where(tuples, criteria.where);
  tuples = _sort(tuples, criteria.sort);
  tuples = _skip(tuples, criteria.skip);
  tuples = _limit(tuples, criteria.limit);
  tuples = _select(tuples, criteria.select);
  
  // TODO:
  // tuples = _groupBy(tuples, criteria.groupBy);

  // Grab the INDEX_IN_ORIG_DATA from each matched tuple
  // this is typically used to update the tuples in the external source data.
  var originalIndices = _.pluck(tuples, INDEX_IN_ORIG_DATA);

  // Remove INDEX_IN_ORIG_DATA from each tuple--
  // it is no longer needed.
  _.each(tuples, function(tuple) {
    delete tuple[INDEX_IN_ORIG_DATA];
  });

  return {
    results: tuples,
    indices: originalIndices
  };
};


},{"./filters/limit":99,"./filters/skip":100,"./filters/where":101,"./projections/groupBy":103,"./projections/select":104,"./sort":106,"lodash":"lodash","util":"util"}],106:[function(require,module,exports){
/**
 * Module dependencies
 */

var _ = require('lodash');
var util = require('util');
var X_ISO_DATE = require('./X_ISO_DATE.constant');



/**
 * Sort the tuples in `data` using `comparator`.
 *
 * @param  { Object[] }  data
 * @param  { Object }    comparator
 * @param  { Function }    when
 * @return { Object[] }
 */
module.exports = function(data, comparator, when) {
  if (!comparator || !data) return data;

  // Equivalent to a SQL "WHEN"
  when = when||function rankSpecialCase (record, attrName) {

    // null ranks lower than anything else
    if ( typeof record[attrName]==='undefined' || record[attrName] === null ) {
      return false;
    }
    else return true;
  };

  return sortData(_.cloneDeep(data), comparator, when);
};



//////////////////////////
///
/// private methods   ||
///                   \/
///                   
//////////////////////////






/**
 * Sort `data` (tuples) using `sortVector` (comparator obj)
 *
 * Based on method described here:
 * http://stackoverflow.com/a/4760279/909625
 *
 * @param  { Object[] } data         [tuples]
 * @param  { Object }   sortVector [mongo-style comparator object]
 * @return { Object[] }
 */

function sortData(data, sortVector, when) {

  // Constants
  var GREATER_THAN = 1;
  var LESS_THAN = -1;
  var EQUAL = 0;
  
  return data.sort(function comparator(a, b) {
    return _(sortVector).reduce(function (flagSoFar, sortDirection, attrName){


      var outcome;

      // Handle special cases (defined by WHEN):
      var $a = when(a, attrName);
      var $b = when(b, attrName);
      if (!$a && !$b) outcome = EQUAL;
      else if (!$a && $b) outcome = LESS_THAN;
      else if ($a && !$b) outcome = GREATER_THAN;

      // General case:
      else {
        // Coerce types
        $a = a[attrName];
        $b = b[attrName];
        if ( $a < $b ) outcome = LESS_THAN;
        else if ( $a > $b ) outcome = GREATER_THAN;
        else outcome = EQUAL;
      }

      // Less-Than case (-1)
      // (leaves flagSoFar untouched if it has been set, otherwise sets it)
      if ( outcome === LESS_THAN ) {
        return flagSoFar || -sortDirection;
      }
      // Greater-Than case (1)
      // (leaves flagSoFar untouched if it has been set, otherwise sets it)
      else if ( outcome === GREATER_THAN ) {
        return flagSoFar || sortDirection;
      }
      // Equals case (0)
      // (always leaves flagSoFar untouched)
      else return flagSoFar;

    }, 0);
  });
}






/**
 * Coerce a value to its probable intended type for sorting.
 * 
 * @param  {???} x
 * @return {???}
 */
function coerceIntoBestGuessType (x) {
  switch ( guessType(x) ) {
    case 'booleanish': return (x==='true')?true:false;
    case 'numberish': return +x;
    case 'dateish': return new Date(x);
    default: return x;
  }
}


function guessType (x) {

  if (!_.isString(x)) {
    return typeof x;
  }

  // Probably meant to be a boolean
  else if (x === 'true' || x === 'false') {
    return 'booleanish';
  }

  // Probably meant to be a number
  else if (+x === x) {
    return 'numberish';
  }

  // Probably meant to be a date
  else if (x.match(X_ISO_DATE)) {
    return 'dateish';
  }

  // Just another string
  else return typeof x;
}

},{"./X_ISO_DATE.constant":98,"lodash":"lodash","util":"util"}],107:[function(require,module,exports){
var fs = require('fs');
var ltrim = require('underscore.string').ltrim;


// Returns false if the directory doesn't exist
module.exports = function requireAll(options) {
  var files;
  var modules = {};

  if (typeof(options.force) == 'undefined') {
    options.force = true;
  }

  // Sane default for `filter` option
  if (!options.filter) {
    options.filter = /(.*)/;
  }

  // Reset our depth counter the first time
  if (typeof options._depth === 'undefined') {
    options._depth = 0;
  }

  // Bail out if our counter has reached the desired depth
  // indicated by the user in options.depth
  if (typeof options.depth !== 'undefined' &&
    options._depth >= options.depth) {
    return;
  }

  // Remember the starting directory
  if (!options.startDirname) {
    options.startDirname = options.dirname;
  }

  try {
    files = fs.readdirSync(options.dirname);
  } catch (e) {
    if (options.optional) return {};
    else throw new Error('Directory not found: ' + options.dirname);
  }

  // Iterate through files in the current directory
  files.forEach(function(file) {
    var filepath = options.dirname + '/' + file;

    // For directories, continue to recursively include modules
    if (fs.statSync(filepath).isDirectory()) {

      // Ignore explicitly excluded directories
      if (excludeDirectory(file)) return;

      // Recursively call requireAll on each child directory
      modules[file] = requireAll({
        dirname: filepath,
        filter: options.filter,
        pathFilter: options.pathFilter,
        excludeDirs: options.excludeDirs,
        startDirname: options.startDirname,
        dontLoad: options.dontLoad,
        markDirectories: options.markDirectories,
        flattenDirectories: options.flattenDirectories,
        keepDirectoryPath: options.keepDirectoryPath,
        force: options.force,

        // Keep track of depth
        _depth: options._depth+1,
        depth: options.depth
      });

      if (options.markDirectories || options.flattenDirectories) {
        modules[file].isDirectory = true;
      }

      if (options.flattenDirectories) {

        modules = (function flattenDirectories(modules, accum, path) {
          accum = accum || {};
          Object.keys(modules).forEach(function(identity) {
            if (typeof(modules[identity]) !== 'object' && typeof(modules[identity]) !== 'function') {
              return;
            }
            if (modules[identity].isDirectory) {
              flattenDirectories(modules[identity], accum, path ? path + '/' + identity : identity );
            } else {
              accum[options.keepDirectoryPath ? (path ? path + '/' + identity : identity) : identity] = modules[identity];
            }
          });
          return accum;
        })(modules);

      }

    }
    // For files, go ahead and add the code to the module map
    else {

      // Key name for module
      var identity;

      // Filename filter
      if (options.filter) {
        var match = file.match(options.filter);
        if (!match) return;
        identity = match[1];
      }

      // Full relative path filter
      if (options.pathFilter) {
        // Peel off relative path
        var path = filepath.replace(options.startDirname, '');

        // make sure a slash exists on the left side of path
        path = '/' + ltrim(path, '/');

        var pathMatch = path.match(options.pathFilter);
        if (!pathMatch) return;
        identity = pathMatch[2];
      }

      // Load module into memory (unless `dontLoad` is true)
      if (options.dontLoad) {
        modules[identity] = true;
      } else {
        if (options.force) {
          var resolved = require.resolve(filepath);
          if (require.cache[resolved]) delete require.cache[resolved];
        }
        modules[identity] = require(filepath);
      }
    }
  });

  // Pass map of modules back to app code
  return modules;

  function excludeDirectory(dirname) {
    return options.excludeDirs && dirname.match(options.excludeDirs);
  }
};
},{"fs":115,"underscore.string":108}],108:[function(require,module,exports){
//  Underscore.string
//  (c) 2010 Esa-Matti Suuronen <esa-matti aet suuronen dot org>
//  Underscore.string is freely distributable under the terms of the MIT license.
//  Documentation: https://github.com/epeli/underscore.string
//  Some code is borrowed from MooTools and Alexandru Marasteanu.
//  Version '2.3.1'

!function(root, String){
  'use strict';

  // Defining helper functions.

  var nativeTrim = String.prototype.trim;
  var nativeTrimRight = String.prototype.trimRight;
  var nativeTrimLeft = String.prototype.trimLeft;

  var parseNumber = function(source) { return source * 1 || 0; };

  var strRepeat = function(str, qty){
    if (qty < 1) return '';
    var result = '';
    while (qty > 0) {
      if (qty & 1) result += str;
      qty >>= 1, str += str;
    }
    return result;
  };

  var slice = [].slice;

  var defaultToWhiteSpace = function(characters) {
    if (characters == null)
      return '\\s';
    else if (characters.source)
      return characters.source;
    else
      return '[' + _s.escapeRegExp(characters) + ']';
  };

  var escapeChars = {
    lt: '<',
    gt: '>',
    quot: '"',
    amp: '&',
    apos: "'"
  };

  var reversedEscapeChars = {};
  for(var key in escapeChars) reversedEscapeChars[escapeChars[key]] = key;
  reversedEscapeChars["'"] = '#39';

  // sprintf() for JavaScript 0.7-beta1
  // http://www.diveintojavascript.com/projects/javascript-sprintf
  //
  // Copyright (c) Alexandru Marasteanu <alexaholic [at) gmail (dot] com>
  // All rights reserved.

  var sprintf = (function() {
    function get_type(variable) {
      return Object.prototype.toString.call(variable).slice(8, -1).toLowerCase();
    }

    var str_repeat = strRepeat;

    var str_format = function() {
      if (!str_format.cache.hasOwnProperty(arguments[0])) {
        str_format.cache[arguments[0]] = str_format.parse(arguments[0]);
      }
      return str_format.format.call(null, str_format.cache[arguments[0]], arguments);
    };

    str_format.format = function(parse_tree, argv) {
      var cursor = 1, tree_length = parse_tree.length, node_type = '', arg, output = [], i, k, match, pad, pad_character, pad_length;
      for (i = 0; i < tree_length; i++) {
        node_type = get_type(parse_tree[i]);
        if (node_type === 'string') {
          output.push(parse_tree[i]);
        }
        else if (node_type === 'array') {
          match = parse_tree[i]; // convenience purposes only
          if (match[2]) { // keyword argument
            arg = argv[cursor];
            for (k = 0; k < match[2].length; k++) {
              if (!arg.hasOwnProperty(match[2][k])) {
                throw new Error(sprintf('[_.sprintf] property "%s" does not exist', match[2][k]));
              }
              arg = arg[match[2][k]];
            }
          } else if (match[1]) { // positional argument (explicit)
            arg = argv[match[1]];
          }
          else { // positional argument (implicit)
            arg = argv[cursor++];
          }

          if (/[^s]/.test(match[8]) && (get_type(arg) != 'number')) {
            throw new Error(sprintf('[_.sprintf] expecting number but found %s', get_type(arg)));
          }
          switch (match[8]) {
            case 'b': arg = arg.toString(2); break;
            case 'c': arg = String.fromCharCode(arg); break;
            case 'd': arg = parseInt(arg, 10); break;
            case 'e': arg = match[7] ? arg.toExponential(match[7]) : arg.toExponential(); break;
            case 'f': arg = match[7] ? parseFloat(arg).toFixed(match[7]) : parseFloat(arg); break;
            case 'o': arg = arg.toString(8); break;
            case 's': arg = ((arg = String(arg)) && match[7] ? arg.substring(0, match[7]) : arg); break;
            case 'u': arg = Math.abs(arg); break;
            case 'x': arg = arg.toString(16); break;
            case 'X': arg = arg.toString(16).toUpperCase(); break;
          }
          arg = (/[def]/.test(match[8]) && match[3] && arg >= 0 ? '+'+ arg : arg);
          pad_character = match[4] ? match[4] == '0' ? '0' : match[4].charAt(1) : ' ';
          pad_length = match[6] - String(arg).length;
          pad = match[6] ? str_repeat(pad_character, pad_length) : '';
          output.push(match[5] ? arg + pad : pad + arg);
        }
      }
      return output.join('');
    };

    str_format.cache = {};

    str_format.parse = function(fmt) {
      var _fmt = fmt, match = [], parse_tree = [], arg_names = 0;
      while (_fmt) {
        if ((match = /^[^\x25]+/.exec(_fmt)) !== null) {
          parse_tree.push(match[0]);
        }
        else if ((match = /^\x25{2}/.exec(_fmt)) !== null) {
          parse_tree.push('%');
        }
        else if ((match = /^\x25(?:([1-9]\d*)\$|\(([^\)]+)\))?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(_fmt)) !== null) {
          if (match[2]) {
            arg_names |= 1;
            var field_list = [], replacement_field = match[2], field_match = [];
            if ((field_match = /^([a-z_][a-z_\d]*)/i.exec(replacement_field)) !== null) {
              field_list.push(field_match[1]);
              while ((replacement_field = replacement_field.substring(field_match[0].length)) !== '') {
                if ((field_match = /^\.([a-z_][a-z_\d]*)/i.exec(replacement_field)) !== null) {
                  field_list.push(field_match[1]);
                }
                else if ((field_match = /^\[(\d+)\]/.exec(replacement_field)) !== null) {
                  field_list.push(field_match[1]);
                }
                else {
                  throw new Error('[_.sprintf] huh?');
                }
              }
            }
            else {
              throw new Error('[_.sprintf] huh?');
            }
            match[2] = field_list;
          }
          else {
            arg_names |= 2;
          }
          if (arg_names === 3) {
            throw new Error('[_.sprintf] mixing positional and named placeholders is not (yet) supported');
          }
          parse_tree.push(match);
        }
        else {
          throw new Error('[_.sprintf] huh?');
        }
        _fmt = _fmt.substring(match[0].length);
      }
      return parse_tree;
    };

    return str_format;
  })();



  // Defining underscore.string

  var _s = {

    VERSION: '2.3.1',

    isBlank: function(str){
      if (str == null) str = '';
      return (/^\s*$/).test(str);
    },

    stripTags: function(str){
      if (str == null) return '';
      return String(str).replace(/<\/?[^>]+>/g, '');
    },

    capitalize : function(str){
      str = str == null ? '' : String(str);
      return str.charAt(0).toUpperCase() + str.slice(1);
    },

    chop: function(str, step){
      if (str == null) return [];
      str = String(str);
      step = ~~step;
      return step > 0 ? str.match(new RegExp('.{1,' + step + '}', 'g')) : [str];
    },

    clean: function(str){
      return _s.strip(str).replace(/\s+/g, ' ');
    },

    count: function(str, substr){
      if (str == null || substr == null) return 0;

      str = String(str);
      substr = String(substr);

      var count = 0,
        pos = 0,
        length = substr.length;

      while (true) {
        pos = str.indexOf(substr, pos);
        if (pos === -1) break;
        count++;
        pos += length;
      }

      return count;
    },

    chars: function(str) {
      if (str == null) return [];
      return String(str).split('');
    },

    swapCase: function(str) {
      if (str == null) return '';
      return String(str).replace(/\S/g, function(c){
        return c === c.toUpperCase() ? c.toLowerCase() : c.toUpperCase();
      });
    },

    escapeHTML: function(str) {
      if (str == null) return '';
      return String(str).replace(/[&<>"']/g, function(m){ return '&' + reversedEscapeChars[m] + ';'; });
    },

    unescapeHTML: function(str) {
      if (str == null) return '';
      return String(str).replace(/\&([^;]+);/g, function(entity, entityCode){
        var match;

        if (entityCode in escapeChars) {
          return escapeChars[entityCode];
        } else if (match = entityCode.match(/^#x([\da-fA-F]+)$/)) {
          return String.fromCharCode(parseInt(match[1], 16));
        } else if (match = entityCode.match(/^#(\d+)$/)) {
          return String.fromCharCode(~~match[1]);
        } else {
          return entity;
        }
      });
    },

    escapeRegExp: function(str){
      if (str == null) return '';
      return String(str).replace(/([.*+?^=!:${}()|[\]\/\\])/g, '\\$1');
    },

    splice: function(str, i, howmany, substr){
      var arr = _s.chars(str);
      arr.splice(~~i, ~~howmany, substr);
      return arr.join('');
    },

    insert: function(str, i, substr){
      return _s.splice(str, i, 0, substr);
    },

    include: function(str, needle){
      if (needle === '') return true;
      if (str == null) return false;
      return String(str).indexOf(needle) !== -1;
    },

    join: function() {
      var args = slice.call(arguments),
        separator = args.shift();

      if (separator == null) separator = '';

      return args.join(separator);
    },

    lines: function(str) {
      if (str == null) return [];
      return String(str).split("\n");
    },

    reverse: function(str){
      return _s.chars(str).reverse().join('');
    },

    startsWith: function(str, starts){
      if (starts === '') return true;
      if (str == null || starts == null) return false;
      str = String(str); starts = String(starts);
      return str.length >= starts.length && str.slice(0, starts.length) === starts;
    },

    endsWith: function(str, ends){
      if (ends === '') return true;
      if (str == null || ends == null) return false;
      str = String(str); ends = String(ends);
      return str.length >= ends.length && str.slice(str.length - ends.length) === ends;
    },

    succ: function(str){
      if (str == null) return '';
      str = String(str);
      return str.slice(0, -1) + String.fromCharCode(str.charCodeAt(str.length-1) + 1);
    },

    titleize: function(str){
      if (str == null) return '';
      return String(str).replace(/(?:^|\s)\S/g, function(c){ return c.toUpperCase(); });
    },

    camelize: function(str){
      return _s.trim(str).replace(/[-_\s]+(.)?/g, function(match, c){ return c.toUpperCase(); });
    },

    underscored: function(str){
      return _s.trim(str).replace(/([a-z\d])([A-Z]+)/g, '$1_$2').replace(/[-\s]+/g, '_').toLowerCase();
    },

    dasherize: function(str){
      return _s.trim(str).replace(/([A-Z])/g, '-$1').replace(/[-_\s]+/g, '-').toLowerCase();
    },

    classify: function(str){
      return _s.titleize(String(str).replace(/[\W_]/g, ' ')).replace(/\s/g, '');
    },

    humanize: function(str){
      return _s.capitalize(_s.underscored(str).replace(/_id$/,'').replace(/_/g, ' '));
    },

    trim: function(str, characters){
      if (str == null) return '';
      if (!characters && nativeTrim) return nativeTrim.call(str);
      characters = defaultToWhiteSpace(characters);
      return String(str).replace(new RegExp('\^' + characters + '+|' + characters + '+$', 'g'), '');
    },

    ltrim: function(str, characters){
      if (str == null) return '';
      if (!characters && nativeTrimLeft) return nativeTrimLeft.call(str);
      characters = defaultToWhiteSpace(characters);
      return String(str).replace(new RegExp('^' + characters + '+'), '');
    },

    rtrim: function(str, characters){
      if (str == null) return '';
      if (!characters && nativeTrimRight) return nativeTrimRight.call(str);
      characters = defaultToWhiteSpace(characters);
      return String(str).replace(new RegExp(characters + '+$'), '');
    },

    truncate: function(str, length, truncateStr){
      if (str == null) return '';
      str = String(str); truncateStr = truncateStr || '...';
      length = ~~length;
      return str.length > length ? str.slice(0, length) + truncateStr : str;
    },

    /**
     * _s.prune: a more elegant version of truncate
     * prune extra chars, never leaving a half-chopped word.
     * @author github.com/rwz
     */
    prune: function(str, length, pruneStr){
      if (str == null) return '';

      str = String(str); length = ~~length;
      pruneStr = pruneStr != null ? String(pruneStr) : '...';

      if (str.length <= length) return str;

      var tmpl = function(c){ return c.toUpperCase() !== c.toLowerCase() ? 'A' : ' '; },
        template = str.slice(0, length+1).replace(/.(?=\W*\w*$)/g, tmpl); // 'Hello, world' -> 'HellAA AAAAA'

      if (template.slice(template.length-2).match(/\w\w/))
        template = template.replace(/\s*\S+$/, '');
      else
        template = _s.rtrim(template.slice(0, template.length-1));

      return (template+pruneStr).length > str.length ? str : str.slice(0, template.length)+pruneStr;
    },

    words: function(str, delimiter) {
      if (_s.isBlank(str)) return [];
      return _s.trim(str, delimiter).split(delimiter || /\s+/);
    },

    pad: function(str, length, padStr, type) {
      str = str == null ? '' : String(str);
      length = ~~length;

      var padlen  = 0;

      if (!padStr)
        padStr = ' ';
      else if (padStr.length > 1)
        padStr = padStr.charAt(0);

      switch(type) {
        case 'right':
          padlen = length - str.length;
          return str + strRepeat(padStr, padlen);
        case 'both':
          padlen = length - str.length;
          return strRepeat(padStr, Math.ceil(padlen/2)) + str
                  + strRepeat(padStr, Math.floor(padlen/2));
        default: // 'left'
          padlen = length - str.length;
          return strRepeat(padStr, padlen) + str;
        }
    },

    lpad: function(str, length, padStr) {
      return _s.pad(str, length, padStr);
    },

    rpad: function(str, length, padStr) {
      return _s.pad(str, length, padStr, 'right');
    },

    lrpad: function(str, length, padStr) {
      return _s.pad(str, length, padStr, 'both');
    },

    sprintf: sprintf,

    vsprintf: function(fmt, argv){
      argv.unshift(fmt);
      return sprintf.apply(null, argv);
    },

    toNumber: function(str, decimals) {
      if (!str) return 0;
      str = _s.trim(str);
      if (!str.match(/^-?\d+(?:\.\d+)?$/)) return NaN;
      return parseNumber(parseNumber(str).toFixed(~~decimals));
    },

    numberFormat : function(number, dec, dsep, tsep) {
      if (isNaN(number) || number == null) return '';

      number = number.toFixed(~~dec);
      tsep = typeof tsep == 'string' ? tsep : ',';

      var parts = number.split('.'), fnums = parts[0],
        decimals = parts[1] ? (dsep || '.') + parts[1] : '';

      return fnums.replace(/(\d)(?=(?:\d{3})+$)/g, '$1' + tsep) + decimals;
    },

    strRight: function(str, sep){
      if (str == null) return '';
      str = String(str); sep = sep != null ? String(sep) : sep;
      var pos = !sep ? -1 : str.indexOf(sep);
      return ~pos ? str.slice(pos+sep.length, str.length) : str;
    },

    strRightBack: function(str, sep){
      if (str == null) return '';
      str = String(str); sep = sep != null ? String(sep) : sep;
      var pos = !sep ? -1 : str.lastIndexOf(sep);
      return ~pos ? str.slice(pos+sep.length, str.length) : str;
    },

    strLeft: function(str, sep){
      if (str == null) return '';
      str = String(str); sep = sep != null ? String(sep) : sep;
      var pos = !sep ? -1 : str.indexOf(sep);
      return ~pos ? str.slice(0, pos) : str;
    },

    strLeftBack: function(str, sep){
      if (str == null) return '';
      str += ''; sep = sep != null ? ''+sep : sep;
      var pos = str.lastIndexOf(sep);
      return ~pos ? str.slice(0, pos) : str;
    },

    toSentence: function(array, separator, lastSeparator, serial) {
      separator = separator || ', '
      lastSeparator = lastSeparator || ' and '
      var a = array.slice(), lastMember = a.pop();

      if (array.length > 2 && serial) lastSeparator = _s.rtrim(separator) + lastSeparator;

      return a.length ? a.join(separator) + lastSeparator + lastMember : lastMember;
    },

    toSentenceSerial: function() {
      var args = slice.call(arguments);
      args[3] = true;
      return _s.toSentence.apply(_s, args);
    },

    slugify: function(str) {
      if (str == null) return '';

      var from  = "ąàáäâãåæćęèéëêìíïîłńòóöôõøùúüûñçżź",
          to    = "aaaaaaaaceeeeeiiiilnoooooouuuunczz",
          regex = new RegExp(defaultToWhiteSpace(from), 'g');

      str = String(str).toLowerCase().replace(regex, function(c){
        var index = from.indexOf(c);
        return to.charAt(index) || '-';
      });

      return _s.dasherize(str.replace(/[^\w\s-]/g, ''));
    },

    surround: function(str, wrapper) {
      return [wrapper, str, wrapper].join('');
    },

    quote: function(str) {
      return _s.surround(str, '"');
    },

    exports: function() {
      var result = {};

      for (var prop in this) {
        if (!this.hasOwnProperty(prop) || prop.match(/^(?:include|contains|reverse)$/)) continue;
        result[prop] = this[prop];
      }

      return result;
    },

    repeat: function(str, qty, separator){
      if (str == null) return '';

      qty = ~~qty;

      // using faster implementation if separator is not needed;
      if (separator == null) return strRepeat(String(str), qty);

      // this one is about 300x slower in Google Chrome
      for (var repeat = []; qty > 0; repeat[--qty] = str) {}
      return repeat.join(separator);
    },

    levenshtein: function(str1, str2) {
      if (str1 == null && str2 == null) return 0;
      if (str1 == null) return String(str2).length;
      if (str2 == null) return String(str1).length;

      str1 = String(str1); str2 = String(str2);

      var current = [], prev, value;

      for (var i = 0; i <= str2.length; i++)
        for (var j = 0; j <= str1.length; j++) {
          if (i && j)
            if (str1.charAt(j - 1) === str2.charAt(i - 1))
              value = prev;
            else
              value = Math.min(current[j], current[j - 1], prev) + 1;
          else
            value = i + j;

          prev = current[j];
          current[j] = value;
        }

      return current.pop();
    }
  };

  // Aliases

  _s.strip    = _s.trim;
  _s.lstrip   = _s.ltrim;
  _s.rstrip   = _s.rtrim;
  _s.center   = _s.lrpad;
  _s.rjust    = _s.lpad;
  _s.ljust    = _s.rpad;
  _s.contains = _s.include;
  _s.q        = _s.quote;

  // Exporting

  // CommonJS module is defined
  if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports)
      module.exports = _s;

    exports._s = _s;
  }

  // Register as a named module with AMD.
  if (typeof define === 'function' && define.amd)
    define('underscore.string', [], function(){ return _s; });


  // Integrate with Underscore.js if defined
  // or create our own underscore object.
  root._ = root._ || {};
  root._.string = root._.str = _s;
}(this, String);

},{}],109:[function(require,module,exports){

/**
 * Module dependencies
 */

var Attributes = require('./waterline-schema/attributes');
var ForeignKeys = require('./waterline-schema/foreignKeys');
var JoinTables = require('./waterline-schema/joinTables');
var References = require('./waterline-schema/references');

/**
 * Used to build a Waterline Schema object from a set of
 * loaded collections. It should turn the attributes into an
 * object that can be sent down to an adapter and understood.
 *
 * @param {Array} collections
 * @param {Object} connections
 * @return {Object}
 * @api public
 */

module.exports = function(collections, connections, defaults) {

  this.schema = {};

  // Transform Collections into a basic schema
  this.schema = new Attributes(collections, connections, defaults);

  // Build Out Foreign Keys
  this.schema = new ForeignKeys(this.schema);

  // Add Join Tables
  this.schema = new JoinTables(this.schema);

  // Add References for Has Many Keys
  this.schema = new References(this.schema);

  return this.schema;

};

},{"./waterline-schema/attributes":110,"./waterline-schema/foreignKeys":111,"./waterline-schema/joinTables":112,"./waterline-schema/references":113}],110:[function(require,module,exports){

/**
 * Module dependencies
 */

var _ = require('lodash');
var utils = require('./utils');
var hop = utils.object.hasOwnProperty;

/**
 * Expose Attributes
 */

module.exports = Attributes;

/**
 * Build an Attributes Definition
 *
 * Takes a collection of attributes from a Waterline Collection
 * and builds up an initial schema by normalizing into a known format.
 *
 * @param {Array} collections
 * @param {Object} connections
 * @return {Object}
 * @api private
 */

function Attributes(collections, connections, defaults) {
  var self = this;

  this.attributes = {};

  // Ensure a value is set for connections
  connections = connections || {};

  collections.forEach(function (collection) {
    collection = self.normalize(collection.prototype, connections, defaults);
    var conns = _.cloneDeep(collection.connection);
    var attributes = _.cloneDeep(collection.attributes);

    self.stripFunctions(attributes);
    self.stripProperties(attributes);
    self.validatePropertyNames(attributes);

    self.attributes[collection.identity.toLowerCase()] = {
      connection: conns,
      identity: collection.identity.toLowerCase(),
      tableName: collection.tableName || collection.identity,
      migrate: collection.migrate || 'safe',
      attributes: attributes
    };
  });

  return this.attributes;

}

/**
 * Normalize attributes for a collection into a known format.
 *
 * @param {Object} collection
 * @param {Object} connections
 * @return {Object}
 * @api private
 */

Attributes.prototype.normalize = function(collection, connections, defaults) {

  this.normalizeIdentity(collection);
  this.setDefaults(collection, defaults);
  this.autoAttributes(collection, connections);

  return collection;

};

/**
 * Set Default Values for the collection.
 *
 * Adds flags to the collection to determine if timestamps and a primary key
 * should be added to the collection's schema.
 *
 * @param {Object} collection
 * @api private
 */

Attributes.prototype.setDefaults = function(collection, defaults) {

  // Ensure defaults is always set to something
  defaults = defaults || {};

  if(!hop(collection, 'connection')) {
    collection.connection = '';
  }

  if(!hop(collection, 'attributes')) {
    collection.attributes = {};
  }

  var defaultSettings = {
    autoPK: true,
    autoCreatedAt: true,
    autoUpdatedAt: true,
    migrate: 'alter'
  };

  // Override default settings with user defined defaults
  if(hop(defaults, 'autoPK')) defaultSettings.autoPK = defaults.autoPK;
  if(hop(defaults, 'autoCreatedAt')) defaultSettings.autoCreatedAt = defaults.autoCreatedAt;
  if(hop(defaults, 'autoUpdatedAt')) defaultSettings.autoUpdatedAt = defaults.autoUpdatedAt;
  if(hop(defaults, 'migrate')) defaultSettings.migrate = defaults.migrate;

  // Override defaults with collection defined values
  if(hop(collection, 'autoPK')) defaultSettings.autoPK = collection.autoPK;
  if(hop(collection, 'autoCreatedAt')) defaultSettings.autoCreatedAt = collection.autoCreatedAt;
  if(hop(collection, 'autoUpdatedAt')) defaultSettings.autoUpdatedAt = collection.autoUpdatedAt;
  if(hop(collection, 'migrate')) defaultSettings.migrate = collection.migrate;

  var flags = {
    autoPK: defaultSettings.autoPK,
    autoCreatedAt: defaultSettings.autoCreatedAt,
    autoUpdatedAt: defaultSettings.autoUpdatedAt,
    migrate: defaultSettings.migrate
  };

  for(var flag in flags) {
    collection[flag] = flags[flag];
  }

};

/**
 * Normalize identity
 *
 * @param {Object} collection
 * @api private
 */

Attributes.prototype.normalizeIdentity = function(collection) {

  if(hop(collection, 'tableName') && !hop(collection, 'identity')) {
    collection.identity = collection.tableName.toLowerCase();
  }

  // Require an identity so the object key can be set
  if(!hop(collection, 'identity')) {
    throw new Error('A Collection must include an identity or tableName attribute');
  }

};

/**
 * Add Auto Attribute definitions to the schema if they are not defined.
 *
 * Adds in things such as an Id primary key and timestamps unless they have been
 * disabled in the collection.
 *
 * @param {Object} collection
 * @param {Object} connections
 * @api private
 */

Attributes.prototype.autoAttributes = function(collection, connections) {

  var attributes = collection.attributes;
  var pk = false;
  var mainConnection;

  // Check to make sure another property hasn't set itself as a primary key
  for(var key in attributes) {
    if(hop(attributes[key], 'primaryKey')) pk = true;
  }

  // If a primary key was manually defined, turn off autoPK
  if(pk) collection.autoPK = false;

  // Add a primary key attribute
  if(!pk && collection.autoPK && !attributes.id) {
    attributes.id = {
      type: 'integer',
      autoIncrement: true,
      primaryKey: true,
      unique: true
    };

    // Check if the adapter used in the collection specifies the primary key format
    if(Array.isArray(collection.connection)) {
      mainConnection = collection.connection[0];
    }
    else {
      mainConnection = collection.connection;
    }

    if(hop(connections, mainConnection)) {
      var connection = connections[mainConnection];
      if(hop(connection._adapter, 'pkFormat')) {
        attributes.id.type = connection._adapter.pkFormat;
      }
    }
  }

  // Extend definition with autoUpdatedAt and autoCreatedAt timestamps
  var now = {
    type: 'datetime',
    'default': 'NOW'
  };

  if(collection.autoCreatedAt && !attributes.createdAt) {
    attributes.createdAt = now;
  }

  if(collection.autoUpdatedAt && !attributes.updatedAt) {
    attributes.updatedAt = now;
  }

};

/**
 * Strip Functions From Schema
 *
 * @param {Object} attributes
 * @api private
 */

Attributes.prototype.stripFunctions = function(attributes) {

  for(var attribute in attributes) {
    if(typeof attributes[attribute] === 'function') delete attributes[attribute];
  }

};

/**
 * Strip Non-Reserved Properties
 *
 * @param {Object} attributes
 * @api private
 */

Attributes.prototype.stripProperties = function(attributes) {

  for(var attribute in attributes) {
    this.stripProperty(attributes[attribute]);
  }

};

/**
 * Strip Property that isn't in the reserved words list.
 *
 * @param {Object}
 * @api private
 */

Attributes.prototype.stripProperty = function(properties) {

  for(var prop in properties) {
    if(utils.reservedWords.indexOf(prop) > -1) continue;
    delete properties[prop];
  }

};

/**
 * Validates property names to ensure they are valid.
 *
 * @param {Object}
 * @api private
 */

Attributes.prototype.validatePropertyNames = function(attributes) {

  for(var attribute in attributes) {

    // Check for dots in name
    if(attribute.match(/\./g)) {
      var error = 'Invalid Attribute Name: Attributes may not contain a "."" character';
      throw new Error(error);
    }

  }

};

},{"./utils":114,"lodash":"lodash"}],111:[function(require,module,exports){

/**
 * Module Dependencies
 */

var _ = require('lodash');
var utils = require('./utils');
var hop = utils.object.hasOwnProperty;

/**
 * Expose Foreign Keys
 */

module.exports = ForeignKeys;

/**
 * Adds Foreign keys to a Collection where needed for belongsTo associations.
 *
 * @param {Object} collections
 * @return {Object}
 * @api private
 */

function ForeignKeys(collections) {

  collections = collections || {};
  this.collections = _.clone(collections);

  for(var collection in collections) {
    this.replaceKeys(collections[collection].attributes);
  }

  return collections;

}

/**
 * Replace Model Association with a foreign key attribute
 *
 * @param {Object} attributes
 * @api private
 */

ForeignKeys.prototype.replaceKeys = function(attributes) {

  for(var attribute in attributes) {

    // We only care about adding foreign key values to attributes
    // with a `model` key
    if(!hop(attributes[attribute], 'model')) continue;

    var modelName = attributes[attribute].model.toLowerCase();
    var primaryKey = this.findPrimaryKey(modelName);
    var columnName = this.buildColumnName(attribute, attributes[attribute]);
    var foreignKey = {
      columnName: columnName,
      type: primaryKey.attributes.type,
      foreignKey: true,
      references: modelName,
      on: primaryKey.attributes.columnName || primaryKey.name,
      onKey: primaryKey.name
    };

    // Remove the attribute and replace it with the foreign key
    delete attributes[attribute];
    attributes[attribute] = foreignKey;
  }

};

/**
 * Find a collection's primary key attribute
 *
 * @param {String} collection
 * @return {Object}
 * @api private
 */

ForeignKeys.prototype.findPrimaryKey = function(collection) {

  if(!this.collections[collection]) {
    throw new Error('Trying to access a collection ' + collection + ' that is not defined.');
  }

  if(!this.collections[collection].attributes) {
    throw new Error('Collection, ' + collection + ', has no attributes defined.');
  }

  var primaryKey = null;

  for(var key in this.collections[collection].attributes) {
    var attribute = this.collections[collection].attributes[key];

    if(!hop(attribute, 'primaryKey')) continue;

    primaryKey = {
      name: key,
      attributes: attribute
    };
  }

  if(!primaryKey) {
    var error = 'Trying to create an association on a model that doesn\'t have a Primary Key.';
    throw new Error(error);
  }

  return primaryKey;

};

/**
 * Build A Column Name
 *
 * Uses either the attributes defined columnName or the user defined attribute name
 *
 * @param {String} key
 * @param {Object} attribute
 * @param {Object} primaryKey
 * @return {String}
 * @api private
 */

ForeignKeys.prototype.buildColumnName = function(key, attribute) {

  if(hop(attribute, 'columnName')) return attribute.columnName;
  return key;

};

},{"./utils":114,"lodash":"lodash"}],112:[function(require,module,exports){

/**
 * Module dependencies
 */

var _ = require('lodash');
var utils = require('./utils');
var hop = utils.object.hasOwnProperty;

/**
 * Expose JoinTables
 */

module.exports = JoinTables;

/**
 * Insert Join/Junction Tables where needed whenever two collections
 * point to each other. Also replaces the references to point to the new join table.
 *
 * @param {Object} collections
 * @return {Object}
 * @api private
 */

function JoinTables(collections) {

  var self = this;
  var joinTables;

  collections = collections || {};
  this.tables = {};

  this.collections = _.cloneDeep(collections);

  // Build Up Join Tables
  for(var collection in collections) {

    // Parse the collection's attributes and create join tables
    // where needed for collections
    joinTables = this.buildJoins(collection);
    this.uniqueTables(joinTables);

    // Mark hasManyThrough tables as junction tables with select all set to true
    this.markCustomJoinTables(collection);
  }

  // Update Collection Attributes to point to the join table
  this.linkAttributes();

  // Filter all the tables which have at least on collection on migrate: self, so they won't be built
  this.filterMigrateSafeTables();

  // Remove properties added just for unqueness
  Object.keys(this.tables).forEach(function(table) {
    delete self.tables[table].joinedAttributes;
  });

  return _.extend(this.collections, this.tables);

}

/**
 * Build A Set of Join Tables
 *
 * @param {String} collection
 * @api private
 * @return {Array}
 */

JoinTables.prototype.buildJoins = function(collection) {

  var self = this;
  var tables = [];

  var attributes = this.collections[collection].attributes;
  var collectionAttributes = this.mapCollections(attributes);

  // If there are no collection attributes return an empty array
  if(Object.keys(collectionAttributes).length === 0) return [];

  // For each collection attribute, inspect it to build up a join table if needed.
  collectionAttributes.forEach(function(attribute) {
    var table = self.parseAttribute(collection, attribute);
    if(table) tables.push(self.buildTable(table));
  });

  return tables;

};

/**
 * Find Has Many attributes for a given set of attributes.
 *
 * @param {Object} attributes
 * @return {Object}
 * @api private
 */

JoinTables.prototype.mapCollections = function(attributes) {

  var collectionAttributes = [];

  for(var attribute in attributes) {
    if(!hop(attributes[attribute], 'collection')) continue;
    collectionAttributes.push({ key: attribute, val: attributes[attribute] });
  }

  return collectionAttributes;

};

/**
 * Parse Collection Attributes
 *
 * Check the collection the attribute references to see if this is a one-to-many or many-to-many
 * relationship. If it's a one-to-many we don't need to build up a join table.
 *
 * @param {String} collectionName
 * @param {Object} attribute
 * @return {Object}
 * @api private
 */

JoinTables.prototype.parseAttribute = function(collectionName, attribute) {

  var error = '';
  var attr = attribute.val;

  // Check if this is a hasManyThrough attribute,
  // if so a join table doesn't need to be created
  if(hop(attr, 'through')) return;

  // Normalize `collection` property name to lowercased version
  attr.collection = attr.collection.toLowerCase();

  // Grab the associated collection and ensure it exists
  var child = this.collections[attr.collection];
  if(!child) {
    error = 'Collection ' + collectionName + ' has an attribute named ' + attribute.key + ' that is ' +
            'pointing to a collection named ' + attr.collection + ' which doesn\'t exist. You must ' +
            ' first create the ' + attr.collection + ' collection.';

    throw new Error(error);
  }

  // If the attribute has a `via` key, check if it's a foreign key. If so this is a one-to-many
  // relationship and no join table is needed.
  if(hop(attr, 'via') && hop(child.attributes[attr.via], 'foreignKey')) return;

  // If no via is specified, a name needs to be created for the other column
  // in the join table. Use the attribute key and the associated collection name
  // which will be unique.
  if(!hop(attr, 'via')) attr.via = attribute.key + '_' + attr.collection;

  // Build up an object that can be used to build a join table
  var tableAttributes = {
    column_one: {
      collection: collectionName.toLowerCase(),
      attribute: attribute.key,
      via: attr.via
    },

    column_two: {
      collection: attr.collection,
      attribute: attr.via,
      via: attribute.key
    }
  };

  return tableAttributes;

};

/**
 * Build Collection for a single join
 *
 * @param {Object} columns
 * @return {Object}
 * @api private
 */

JoinTables.prototype.buildTable = function(columns) {

  var table = {};
  var c1 = columns.column_one;
  var c2 = columns.column_two;

  table.identity = this.buildCollectionName(columns).toLowerCase();
  table.tableName = table.identity;
  table.tables = [c1.collection, c2.collection];
  table.joinedAttributes = [];
  table.junctionTable = true;

  // Look for a dominant collection property so the join table can be created on the correct connection.
  table.connection = this.findDominantConnection(columns);
  if(!table.connection) {
    var err = "A 'dominant' property was not supplied for the two collections in a many-to-many relationship. " +
        "One side of the relationship between '" + c1.collection + "' and '" + c2.collection + "' needs a " +
        "'dominant: true' flag set so a join table can be created on the correct connection.";

    throw new Error(err);
  }

  // Set a primary key (should probably be refactored)
  table.attributes = {
    id: {
      primaryKey: true,
      autoIncrement: true,
      type: 'integer'
    }
  };

  // Add each foreign key as an attribute
  table.attributes[c1.collection + '_' + c1.attribute] = this.buildForeignKey(c1, c2);
  table.attributes[c2.collection + '_' + c2.attribute] = this.buildForeignKey(c2, c1);

  table.joinedAttributes.push(c1.collection + '_' + c1.attribute);
  table.joinedAttributes.push(c2.collection + '_' + c2.attribute);

  return table;

};

/**
 * Build a collection name by combining two collection and attribute names.
 *
 * @param {Object} columns
 * @return {String}
 * @api private
 */

JoinTables.prototype.buildCollectionName = function(columns) {

  var c1 = columns.column_one;
  var c2 = columns.column_two;

  if(c1.collection < c2.collection) {
    return c1.collection + '_' + c1.attribute + '__' + c2.collection + '_' + c2.attribute;
  }

  return c2.collection + '_' + c2.attribute + '__' + c1.collection + '_' + c1.attribute;

};

/**
 * Find the dominant collection.
 *
 * @param {Object} columns
 * @return {String}
 * @api private
 */

JoinTables.prototype.findDominantConnection = function(columns) {

  var c1 = this.collections[columns.column_one.collection];
  var c2 = this.collections[columns.column_two.collection];
  var dominantCollection;

  // Don't require a dominant collection on self-referencing associations
  if(columns.column_one.collection === columns.column_two.collection) {
    return c1.connection;
  }

  dominantCollection = this.searchForAttribute(columns.column_one.collection, 'dominant');
  if(dominantCollection) return c1.connection;

  dominantCollection = this.searchForAttribute(columns.column_two.collection, 'dominant');
  if(dominantCollection) return c2.connection;

  // Don't require a dominant collection for models on the same connection.
  if (c1.connection[0] === c2.connection[0]) {
    return c1.connection;
  }

  return false;

};

/**
 * Search Attributes for an attribute property.
 *
 * @param {String} collectionName
 * @param {String} attributeName
 * @param {String} value (optional)
 * @return {String}
 * @api private
 */

JoinTables.prototype.searchForAttribute = function(collectionName, attributeName, value) {

  var collection = this.collections[collectionName];
  var matching;
  var properties;

  Object.keys(collection.attributes).forEach(function(key) {
    properties = collection.attributes[key];
    if(!value && hop(properties, attributeName)) matching = key;
    if(hop(properties, attributeName) && properties[attributeName] === value) matching = key;
  });

  return matching;

};

/**
 * Build a Foreign Key value for an attribute in the join collection
 *
 * @param {Object} column_one
 * @param {Object} column_two
 * @return {Object}
 * @api private
 */

JoinTables.prototype.buildForeignKey = function(column_one, column_two) {

  var primaryKey = this.findPrimaryKey(column_one.collection);
  var columnName = (column_one.collection + '_' + column_one.attribute);
  var viaName = column_two.collection + '_' + column_one.via;

  return {
    columnName: columnName,
    type: primaryKey.attributes.type,
    foreignKey: true,
    references: column_one.collection,
    on: primaryKey.name,
    onKey: primaryKey.name,
    via: viaName,
    groupKey: column_one.collection
  };

};

/**
 * Filter Out Duplicate Join Tables
 *
 * @param {Array} tables
 * @api private
 */

JoinTables.prototype.uniqueTables = function(tables) {

  var self = this;

  tables.forEach(function(table) {
    var add = true;

    // Check if any tables are already joining these attributes together
    Object.keys(self.tables).forEach(function(tableName) {
      var currentTable = self.tables[tableName];
      if(currentTable.joinedAttributes.indexOf(table.joinedAttributes[0]) === -1) return;
      if(currentTable.joinedAttributes.indexOf(table.joinedAttributes[1]) === -1) return;

      add = false;
    });

    if(hop(self.tables, table.identity)) return;
    if(add) self.tables[table.identity] = table;
  });

};

/**
 * Find a collection's primary key attribute
 *
 * @param {String} collection
 * @return {Object}
 * @api private
 */

JoinTables.prototype.findPrimaryKey = function(collection) {

  var primaryKey = null;
  var attribute;
  var error;

  if(!this.collections[collection]) {
    throw new Error('Trying to access a collection ' + collection + ' that is not defined.');
  }

  if(!this.collections[collection].attributes) {
    throw new Error('Collection, ' + collection + ', has no attributes defined.');
  }

  for(var key in this.collections[collection].attributes) {
    attribute = this.collections[collection].attributes[key];

    if(!hop(attribute, 'primaryKey')) continue;

    primaryKey = {
      name: attribute.columnName || key,
      attributes: attribute
    };
  }

  if(!primaryKey) {
    error = 'Trying to create an association on a model that doesn\'t have a Primary Key.';
    throw new Error(error);
  }

  return primaryKey;

};

/**
 * Update Collection Attributes to point to the join table instead of the other collection
 *
 * @api private
 */

JoinTables.prototype.linkAttributes = function() {

  for(var collection in this.collections) {
    var attributes = this.collections[collection].attributes;
    this.updateAttribute(collection, attributes);
  }

};

/**
 * Update An Attribute
 *
 * @param {String} collection
 * @param {Object} attributes
 * @api private
 */

JoinTables.prototype.updateAttribute = function(collection, attributes) {

  for(var attribute in attributes) {
    if(!hop(attributes[attribute], 'collection')) continue;

    var attr = attributes[attribute];
    var parent = collection;
    var child = attr.collection;
    var via = attr.via;

    var joined = this.findJoinTable(parent, child, via);

    if(!joined.join) continue;

    // If the table doesn't know about the other side ignore updating anything
    if(!hop(joined.table.attributes, collection + '_' + attribute)) continue;

    this.collections[collection].attributes[attribute] = {
      collection: joined.table.identity,
      references: joined.table.identity,
      on: joined.table.attributes[collection + '_' + attribute].columnName,
      onKey: joined.table.attributes[collection + '_' + attribute].columnName
    };
  }

};

/**
 * Mark Custom Join Tables as a Junction Table
 *
 * If a collection has an attribute with a `through` property, lookup
 * the collection it points to and mark it as a `junctionTable`.
 *
 * @param {String} collection
 * @api private
 */

JoinTables.prototype.markCustomJoinTables = function(collection) {

  var attributes = this.collections[collection].attributes;

  for(var attribute in attributes) {
    if(!hop(attributes[attribute], 'through')) continue;

    var linkedCollection = attributes[attribute].through;
    this.collections[linkedCollection].junctionTable = true;

    // Build up proper reference on the attribute
    attributes[attribute].collection = linkedCollection;
    attributes[attribute].references = linkedCollection;

    // Find Reference Key
    var reference = this.findReference(collection, linkedCollection);
    attributes[attribute].on = reference;
    attributes[attribute].onKey = reference;

    delete attributes[attribute].through;
  }

};

/**
 * Find Reference attribute name in a set of attributes
 *
 * @param {String} parent
 * @param {String} collection
 * @return {String}
 * @api private
 */

JoinTables.prototype.findReference = function(parent, collection) {

  var attributes = this.collections[collection].attributes;
  var reference;

  for(var attribute in attributes) {
    if(!hop(attributes[attribute], 'foreignKey')) continue;
    if(!hop(attributes[attribute], 'references')) continue;
    if(attributes[attribute].references !== parent) continue;

    reference = attributes[attribute].columnName || attribute;
    break;
  }

  return reference;

};

/**
 * Search for a matching join table
 *
 * @param {String} parent
 * @param {String} child
 * @param {String} via
 * @return {Object}
 * @api private
 */

JoinTables.prototype.findJoinTable = function(parent, child, via) {

  var join = false;
  var tableCollection;

  for(var table in this.tables) {
    var tables = this.tables[table].tables;

    if(tables.indexOf(parent) < 0) continue;
    if(tables.indexOf(child) < 0) continue;

    var column = child + '_' + via;

    if(!hop(this.tables[table].attributes, column)) continue;

    join = true;
    tableCollection = this.tables[table];
    break;
  }

  return { join: join, table: tableCollection };

};


/**
 * Filter all tables which have at least one collection set to migrate: true, before they get physically created in the database
 * AFTER all references are set and all collections have been linked
 *
 * @param {String} tables
 * @api private
 */

JoinTables.prototype.filterMigrateSafeTables = function() {
  var self = this;

  for(var table in this.tables) {
    var tables = this.tables[table].tables;

    // iterate through all collections, if one of them is migrate: safe we delete the table
    // so it does not get built
    var migrateSafe = false;
    tables.forEach(function(collection) {
      if(self.collections[collection].migrate === 'safe') {
        migrateSafe = true;
      }
    });

    if(migrateSafe === true) {
      this.tables[table].migrate = 'safe';
    }
  }

  return this.tables;
};



},{"./utils":114,"lodash":"lodash"}],113:[function(require,module,exports){

/**
 * Module Dependencies
 */

var _ = require('lodash');
var utils = require('./utils');
var hop = utils.object.hasOwnProperty;

/**
 * Expose References
 */

module.exports = References;

/**
 * Map References for hasMany attributes. Not necessarily used for most schemas
 * but used internally in Waterline. It could also be helpful for key/value datastores.
 *
 * @param {Object} collections
 * @return {Object}
 * @api private
 */

function References(collections) {

  collections = collections || {};
  this.collections = _.clone(collections);

  for(var collection in collections) {
    this.addKeys(collection);
  }

  return this.collections;

}

/**
 * Add Reference Keys to hasMany attributes
 *
 * @param {String} collection
 * @api private
 */

References.prototype.addKeys = function(collection) {

  var attributes = this.collections[collection].attributes;
  var reference;

  for(var attribute in attributes) {
    if(!hop(attributes[attribute], 'collection')) continue;

    // If references have already been configured, continue on
    if(attributes[attribute].references && attributes[attribute].on) continue;

    attributes[attribute].collection = attributes[attribute].collection;

    // Check For HasMany Through
    if(hop(attributes[attribute], 'through')) {
      reference = this.findReference(attributes[attribute].collection.toLowerCase(), attributes[attribute].through.toLowerCase());
      if(!reference) continue;

      attributes[attribute].references = attributes[attribute].through;
      attributes[attribute].on = reference.reference;
      attributes[attribute].onKey = reference.keyName;
      delete attributes[attribute].through;

      continue;
    }

    // Figure out what to reference by looping through the other collection
    reference = this.findReference(collection, attributes[attribute].collection.toLowerCase(), attributes[attribute]);
    if(!reference) continue;

    attributes[attribute].references = attributes[attribute].collection.toLowerCase();
    attributes[attribute].on = reference.reference;
    attributes[attribute].onKey = reference.keyName;
  }

};

/**
 * Find Reference attribute name in a set of attributes
 *
 * @param {String} parent
 * @param {String} collection
 * @param {Object} attribute
 * @return {String}
 * @api private
 */

References.prototype.findReference = function(parent, collection, attribute) {

  if(typeof this.collections[collection] != 'object') {
    throw new Error('Cannot find collection \'' + collection + '\' referenced in ' + parent);
  }

  var attributes = this.collections[collection].attributes;
  var reference;
  var matchingAttributes = [];
  var obj = {};

  for(var attr in attributes) {
    if(!hop(attributes[attr], 'foreignKey')) continue;
    if(!hop(attributes[attr], 'references')) continue;
    if(attributes[attr].references !== parent) continue;

    // Add the attribute to the matchingAttribute array
    matchingAttributes.push(attr);
  }

  // If no matching attributes are found, throw an error because you are trying to add a hasMany
  // attribute to a model where the association doesn't have a foreign key matching the collection.
  if(matchingAttributes.length === 0) {
    throw new Error('Trying to associate a collection attribute to a model that doesn\'t have a ' +
                    'Foreign Key. ' + parent + ' is trying to reference a foreign key in ' + collection);
  }

  // If multiple matching attributes were found on the model, ensure that the collection has a `via`
  // key that describes which foreign key to use when populating.
  if(matchingAttributes.length > 1) {
    if(!hop(attribute, 'via')) {
      throw new Error('Multiple foreign keys were found on ' + collection + '. You need to specify a ' +
                      'foreign key to use by adding in the `via` property to the collection association');
    }

    // Find the collection attribute used in the `via` property
    var via = false;
    var viaName;

    matchingAttributes.forEach(function(attr) {
      if(attr !== attribute.via) return;
      via = attributes[attr];
      viaName = attr;
    });

    if(!via) {
      throw new Error('No matching attribute was found on ' + collection + ' with the name ' + attribute.via);
    }

    reference = via.columnName || viaName;
    obj = { reference: reference, keyName: viaName };
    return obj;
  }

  // If only a single matching attribute was found we can just use that for the reference
  reference = attributes[matchingAttributes[0]].columnName || matchingAttributes[0];
  obj = { reference: reference, keyName: matchingAttributes[0] };
  return obj;

};

},{"./utils":114,"lodash":"lodash"}],114:[function(require,module,exports){


/**
 * Contains a list of reserved words. All others should be stripped from
 * a schema when building.
 */

exports.reservedWords = [
  'defaultsTo',
  'primaryKey',
  'autoIncrement',
  'unique',
  'index',
  'columnName',
  'foreignKey',
  'references',
  'on',
  'through',
  'groupKey',
  'required',
  'default',
  'type',
  'collection',
  'model',
  'via',
  'dominant',
  'migrate'
];

/**
 * ignore
 */

exports.object = {};

/**
 * Safer helper for hasOwnProperty checks
 *
 * @param {Object} obj
 * @param {String} prop
 * @return {Boolean}
 * @api public
 */

var hop = Object.prototype.hasOwnProperty;
exports.object.hasOwnProperty = function(obj, prop) {
  return hop.call(obj, prop);
};

},{}],115:[function(require,module,exports){
module.exports=require(95)
},{"/media/ext/mnt/home/cha0s6983/dev/code/js/shrub/node_modules/waterline-browser/node_modules/node-switchback/lib/redirect.js":95}],116:[function(require,module,exports){
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

}).call(this,require('_process'))
},{"_process":117}],117:[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
    && window.setImmediate;
    var canMutationObserver = typeof window !== 'undefined'
    && window.MutationObserver;
    var canPost = typeof window !== 'undefined'
    && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return function (f) { return window.setImmediate(f) };
    }

    var queue = [];

    if (canMutationObserver) {
        var hiddenDiv = document.createElement("div");
        var observer = new MutationObserver(function () {
            var queueList = queue.slice();
            queue.length = 0;
            queueList.forEach(function (fn) {
                fn();
            });
        });

        observer.observe(hiddenDiv, { attributes: true });

        return function nextTick(fn) {
            if (!queue.length) {
                hiddenDiv.setAttribute('yes', 'no');
            }
            queue.push(fn);
        };
    }

    if (canPost) {
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

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};

},{}],"waterline-browser":[function(require,module,exports){
var _ = require('lodash'),
    async = require('async'),
    Schema = require('waterline-schema'),
    Connections = require('./waterline/connections'),
    CollectionLoader = require('./waterline/collection/loader'),
    hasOwnProperty = require('./waterline/utils/helpers').object.hasOwnProperty;

/**
 * Waterline
 */

var Waterline = module.exports = function() {

  if(!(this instanceof Waterline)) {
    return new Waterline();
  }

  // Keep track of all the collections internally so we can build associations
  // between them when needed.
  this._collections = [];

  // Keep track of all the active connections used by collections
  this._connections = {};

  return this;
};


/***********************************************************
 * Modules that can be extended
 ***********************************************************/


// Collection to be extended in your application
Waterline.Collection = require('./waterline/collection');

// Model Instance, returned as query results
Waterline.Model = require('./waterline/model');


/***********************************************************
 * Prototype Methods
 ***********************************************************/


/**
 * loadCollection
 *
 * Loads a new Collection. It should be an extended Waterline.Collection
 * that contains your attributes, instance methods and class methods.
 *
 * @param {Object} collection
 * @return {Object} internal models dictionary
 * @api public
 */

Waterline.prototype.loadCollection = function(collection) {

  // Cache collection
  this._collections.push(collection);

  return this._collections;
};


/**
 * initialize
 *
 * Creates an initialized version of each Collection and auto-migrates depending on
 * the Collection configuration.
 *
 * @param {Object} config object containing adapters
 * @param {Function} callback
 * @return {Array} instantiated collections
 * @api public
 */

Waterline.prototype.initialize = function(options, cb) {
  var self = this;

  // Ensure a config object is passed in containing adapters
  if(!options) throw new Error('Usage Error: function(options, callback)');
  if(!options.adapters) throw new Error('Options object must contain an adapters object');
  if(!options.connections) throw new Error('Options object must contain a connections object');

  // Allow collections to be passed in to the initialize method
  if(options.collections) {
    for(var collection in options.collections) {
      this.loadCollection(_.cloneDeep(options.collections[collection]));
    }

    // Remove collections from the options after they have been loaded
    delete options.collections;
  }

  // Cache a reference to instantiated collections
  this.collections = {};

  // Build up all the connections used by the collections
  this.connections = new Connections(options.adapters, options.connections);

  // Grab config defaults or set them to empty
  var defaults = options.defaults || {};

  // Build a schema map
  this.schema = new Schema(this._collections, this.connections, defaults);

  // Load a Collection into memory
  function loadCollection(item , next) {
    var loader = new CollectionLoader(item, self.connections, defaults);
    var collection = loader.initialize(self);

    // Store the instantiated collection so it can be used
    // internally to create other records
    self.collections[collection.identity.toLowerCase()] = collection;

    next();
  }

  async.auto({

    // Load all the collections into memory
    loadCollections: function(next) {
      async.each(self._collections, loadCollection, function(err) {
        if(err) return next(err);

        // Migrate Junction Tables
        var junctionTables = [];

        Object.keys(self.schema).forEach(function(table) {
          if(!self.schema[table].junctionTable) return;
          junctionTables.push(Waterline.Collection.extend(self.schema[table]));
        });

        async.each(junctionTables, loadCollection, function(err) {
          if(err) return next(err);
          next(null, self.collections);
        });
      });
    },


    // Build up Collection Schemas
    buildCollectionSchemas: ['loadCollections', function(next, results) {
      var collections = self.collections,
          schemas = {};

      Object.keys(collections).forEach(function(key) {
        var collection = collections[key];

        // Remove hasMany association keys
        var schema = _.clone(collection._schema.schema);

        Object.keys(schema).forEach(function(key) {
          if(hasOwnProperty(schema[key], 'type')) return;
          delete schema[key];
        });

        // Grab JunctionTable flag
        var meta = collection.meta || {};
        meta.junctionTable = hasOwnProperty(collection.waterline.schema[collection.identity], 'junctionTable') ?
          collection.waterline.schema[collection.identity].junctionTable : false;

        schemas[collection.identity] = collection;
        schemas[collection.identity].definition = schema;
        schemas[collection.identity].meta = meta;
      });

      next(null, schemas);
    }],


    // Register the Connections with an adapter
    registerConnections: ['buildCollectionSchemas', function(next, results) {
      async.each(Object.keys(self.connections), function(item, nextItem) {
        var connection = self.connections[item],
            config = {},
            usedSchemas = {};

        // Check if the connection's adapter has a register connection method
        if(!hasOwnProperty(connection._adapter, 'registerConnection')) return nextItem();

        // Copy all values over to a tempory object minus the adapter definition
        Object.keys(connection.config).forEach(function(key) {
          config[key] = connection.config[key];
        });

        // Set an identity on the connection
        config.identity = item;

        // Grab the schemas used on this connection
        connection._collections.forEach(function(coll) {
          var identity = coll;
          if(hasOwnProperty(self.collections[coll].__proto__, 'tableName')) {
            identity = self.collections[coll].__proto__.tableName;
          }

          usedSchemas[identity] = results.buildCollectionSchemas[coll];
        });

        // Call the registerConnection method
        connection._adapter.registerConnection(_.cloneDeep(config), usedSchemas, function(err) {
          if(err) return nextItem(err);
          nextItem();
        });
      }, next);
    }]

  }, function(err) {
    if(err) return cb(err);
    self.bootstrap(function(err) {
      if(err) return cb(err);
      cb(null, { collections: self.collections, connections: self.connections });
    });
  });

};

/**
 * Teardown
 *
 * Calls the teardown method on each connection if available.
 */

Waterline.prototype.teardown = function teardown(cb) {
  var self = this;

  async.each(Object.keys(this.connections), function(item, next) {
    var connection = self.connections[item];

    // Check if the adapter has a teardown method implemented
    if(!hasOwnProperty(connection._adapter, 'teardown')) return next();

    connection._adapter.teardown(item, next);
  }, cb);
};



/**
 * Bootstrap
 *
 * Auto-migrate all collections
 */

Waterline.prototype.bootstrap = function bootstrap(cb) {
  var self = this;


  //
  // TODO:
  // Come back to this -- see https://github.com/balderdashy/waterline/issues/259
  // (the stuff in this file works fine-- the work would be structural changes elsewhere)
  //

  // // Use the shema to get a list of junction tables idents
  // // and then determine which are "logical" collections
  // // (i.e. everything EXCEPT junction tables)
  // var junctionTableIdents = _(this.schema).filter({junctionTable: true}).pluck('identity').value();
  // var logicalCollections = _(this.collections).omit(junctionTableIdents).value();

  // // Flatten logical collections obj into an array for convenience
  // var toBeSynced = _.reduce(logicalCollections, function (logicals,coll,ident) {
  //     logicals.push(coll);
  //     return logicals;
  //   }, []);

  // // console.log(junctionTableIdents);
  // // console.log(Object.keys(logicalCollections));
  // // console.log('\n',
  // //   'Migrating collections ::',
  // //   _(toBeSynced).pluck('identity').value()
  // // );



  // For now:
  var toBeSynced = _.reduce(this.collections, function (resources, collection, ident) {
    resources.push(collection);
    return resources;
  }, []);

  // Run auto-migration strategies on each collection
  // async.each(toBeSynced, function(collection, next) {
  async.eachSeries(toBeSynced, function(collection, next) {
  // async.eachLimit(toBeSynced, 9, function(collection, next) {
    collection.sync(next);
  }, cb);
};

},{"./waterline/collection":13,"./waterline/collection/loader":14,"./waterline/connections":15,"./waterline/model":26,"./waterline/utils/helpers":70,"async":"async","lodash":"lodash","waterline-schema":109}]},{},[])("waterline-browser")
});