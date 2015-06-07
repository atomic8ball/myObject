# myObject
JSON serialization to schema-less MySQL

myObject lets you store, load, and search hierarchical data, represented by JSON objects, in a MySQL table.  Conceptually, you can consider the data stored in myObject as one, gigantic, JSON object.

## myObject is not an ORM tool.
myObject doesn't map your data to a specific table structure (schema).  Instead, each key/value is stored along with a reference to its parent, allowing any structure to be stored and recreated, and allowing somewhat efficient searches across the key/value pairs.  The project is used by us with [Node.js](http://nodejs.org) and can be installed with `npm install my-object`, but the schema and stored procedures may prove useful to any language or environment that can use MySQL.

## Quick Examples

```javascript
myo.store('britons.peasant', { name: 'Dennis', old: false, age: 37 }, function(err) {
	if (err) throw err;
}); // store

myo.load('britons.peasant', function(err, obj) {
	if (err) throw err;
    console.log(obj.name); // Dennis
    console.log(obj.old); // false
    console.log(obj.age); // 37
}); // load

myo.load('britons.peasant.age', function(err, obj) {
	if (err) throw err;
    console.log(obj); // 37
}); // load

myo.search('name', 'Dennis', function(err, matchingKeys) {
	if (err) throw err;
    // matchingKeys is an array of matching fully qualified key paths
    console.log(matchingKeys[0]); // britons.peasant.name
}); // search
```

That's just about it!  [`store`](#store) will store the JSON representation (e.g.: no functions and undefined values aren't recorded), and [`load`](#load) will retrieve it, or any key in the hierarchy.  All keys can be [`search`](#search)ed, but presently only strings and numbers will be matched (NaN, Infinity, -Infinity, true, and false values maybe in a future update?).

## Download

The source is on [GitHub](https://github.com/atomic8ball/myObject).
Alternatively, you can install using Node Package Manager (`npm`):

    npm install my-object

## Setup MySQL
You'll need to create the table and the stored procedures in you MySQL database before you can do anything else.
Running the script [schema.sql](https://github.com/atomic8ball/myObject/blob/master/schema.sql) will create the table, stored procedures, as well as the root object.

> **WARNING!** The first line of this file is `drop table if exists okeys;` *this will **destroy** any prior data* or anything else that was in that table.

## Documentation

* [`store`](#store)
* [`load`](#load)
* [`search`](#search)
* [`end`](#end)

<a name="store" />
### store(key, value, callback)

Store the value, and all child objects, in the database at the given key location.

__Arguments__

* `key` - The fully qualified path of where to store the value.
* `value` - The value, which can be any valid JSON datatype (string, number, boolean, etc.), to store.
* `callback(err)` - A *required* function that is called when the store completes. If an error has occured `err` will be truthy and contain details.  If `err` is falsey you can assume success.

__Example__

```javascript
myo.store('britons.peasant', { name: 'Dennis', old: false, age: 37 }, function(err) {
	if (err) throw err;
}); // store
```

<a name="load" />
### load(key, callback)

Loads object specified by the given key from the database, including all child objects.

__Arguments__

* `key` - The fully qualified path of where to begin contstructing the object
* `callback(err, obj)` - A *required* function that is called when the load completes. If an error has occured `err` will be truthy and contain details.  If `err` is falsey you can assume success. `obj` will be the complete object stored at the key or `undefined` if there was no object at that location.

__Examples__

```javascript

// this key specifies an object, so the object, and all its properties, will be returned

myo.load('britons.peasant', function(err, obj) {
	if (err) throw err;
    console.log(obj.name); // Dennis
    console.log(obj.old); // false
    console.log(obj.age); // 37
}); // load
```

```javascript

// this key specifies a single value, so only that value is returned

myo.load('britons.peasant.age', function(err, obj) {
	if (err) throw err;
    console.log(obj); // 37
}); // load
```

<a name="search" />
### search(name, value, callback)

Searches the database for all objects with properties named `name` that equal the `value`.  The callback will will contain an array of fully qualified keys of matching objects.

__Arguments__

* `name` - The *non*-qualified property name to test.
* `value` - The value to match against.  Presently, this must be either a `string` or numeric `number` (i.e.: not `NaN`, `Infinity`, or `-Infinity`).
* `callback(err, matchingKeys)` - A *required* function that is called when the search completes. If an error has occured `err` will be truthy and contain details.  If `err` is falsey you can assume success. `matchingKeys` is an array containing the fully qualified key names of *all objects that had a matching property*.  Construct your object property names accordingly.

__Example__

```javascript
myo.search('name', 'Dennis', function(err, matchingKeys) {
	if (err) throw err;
    // matchingKeys is an array of matching fully qualified key paths
    console.log(matchingKeys[0]); // britons.peasant.name
}); // search
```

<a name="end" />
### end([callback])

Ends the underlying connection pool to MySQL, closing all connections.  Used mainly for testing so Node will close.

__Arguments__

* `callback(err)` - A *optional* function that is called when the pool has closed all connections. If an error has occured `err` will be truthy and contain details.  If `err` is falsey you can assume success.

__Example__

```javascript
myo.end(function(err) {
	if (err) throw err;
    console.log('myObject connection pool closed');
}); // search
```

