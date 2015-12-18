"use strict";

var mysql = require('mysql'),
	fs = require('fs'),
	async = require('async');


var RETRIES = 1;


var merge = function() {
	return [].slice.apply(arguments).reduce(function(p, c) {
		return (typeof c !== 'object' || typeof p !== 'object') ? c //
			: Object.keys(c).reduce(function(o, k) {
				o[k] = merge(p[k], c[k]);
				return o;
			}, p); // forEach
	}, {}); // return reduce
}; // merge

var buildObject = function(data) {
	var o, names = {};
	data.forEach(function(row) {
					var parentName = names[row.parent],
						name = (parentName ? parentName + '.' : '') + row.name,
						t = row.type,
						v = (t === 'NaN' ? NaN //
							: t === 'Infinity' ? Infinity //
							: t === '-Infinity' ? -Infinity //
							: t === 'true' ? true //
							: t === 'false' ? false //
							: t === 'number' ? row.number //
							: t === 'string' ? row.string //
							: t === 'object' ? {} //
							: t === 'array' ? [] //
							: null);
					names[row.id] = name;
					if (o) {
						var target = names[row.parent].split('.').slice(1).reduce(function(p, c) {
							return p[c];
						}, o); // reduce
						target[row.name] = v;
					} else o = v;
				}); // forEach
				return o;
};


var sqlText = {
	read: fs.readFileSync(__dirname + '/read.sql', 'utf-8').replace(/^\uFEFF/, ''),
	write: fs.readFileSync(__dirname + '/write.sql', 'utf-8').replace(/^\uFEFF/, ''),
	cleanup: fs.readFileSync(__dirname + '/cleanup.sql', 'utf-8').replace(/^\uFEFF/, ''),
	search: fs.readFileSync(__dirname + '/search.sql', 'utf-8').replace(/^\uFEFF/, ''),
	multisearchload: fs.readFileSync(__dirname + '/multisearchload.sql', 'utf-8').replace(/^\uFEFF/, ''),
}; // sqlText


module.exports = function(cx) {
	// this is the connection pool for MySQL
	var pool = mysql.createPool(merge({
		// defaults
		connectionLimit: 20,
		connectTimeout: 60000,
		acquireTimeout: 60000,
	}, cx, { // user supplied connection info
		// required options
		supportBigNumbers: true,
		multipleStatements: true,
	})); // pool


	var doSql = function(sql, params, cb) {
		pool.query(sql, params, function(err, results) {
			process.nextTick(function() {
				cb(err, results);
			}); // nextTick
		}); // query
	}; // doSql


	var storePrime = function(k, v1) {
		var v = JSON.parse(JSON.stringify(v1)),
			t = typeof v,
			t1 = ((t === 'boolean' || (t === 'number' && (isNaN(v) || v === Infinity || v === -Infinity))) ? v + '' //
				: (t === 'object' && !v) ? 'null' //
				: (t === 'object' && v.length) ? 'array' //
				: t),
			number = (t1 === 'number' ? v : null),
			string = (t1 === 'string' ? v : null);

		var sql = mysql.format(sqlText.write, [k, t1, number, string]);

		return (t1 !== 'object' && t1 !== 'array') ? sql //
			: Object.keys(v).reduce(function(p, c) {
				return p + storePrime(k + '.' + c, v[c]);
			}, sql); // reduce
	}; // storePrime


	var activeWrites = {};

	var writeCount = 0;


	return {
		store: function(k, v1, cb) {
			var sql = 'start transaction;' + storePrime(k, v1) + 'commit;';

			if (++writeCount > 10000) {
				writeCount = 0;
				sql += sqlText.cleanup;
			} // if

			(function tryDoSql(tries) {
				doSql(sql, null, function(err) {
					if (err) console.log('write error', err);
					return (err && tries) ? tryDoSql(tries - 1) //
						: cb(err);
				}); // doSql
			})(RETRIES); // tryDoSql
		}, // store

		load: function(k, cb) {
			doSql(sqlText.read, [k], function(err, data) {
				if (err) console.log('read error', err);
				if (err || !data || !data.length) return cb(err);
				var o = buildObject(data[0]);
				cb(null, o);
			}); // doSql
		}, // load

		search: function(k, v, cb) {
			var t = typeof v,
				s = (t === 'string' ? v : null),
				n = (t === 'number' ? v : null);
			doSql(sqlText.search, [k, s, n], function(err, data) {
				cb(err, data && data.length ? data[0] : undefined);
			}); // doSql
		}, // search
		
		multisearchload: function(keys, value, depth, cb) {
			if(!depth) depth = 0;
			var searchkeys = keys.join('|'),
				t = typeof value,
				s = (t === 'string' ? value : null),
				n = (t === 'number' ? value : null);
			doSql(sqlText.multisearchload, [searchkeys, s, n, depth], function(err, data) {
				if (err) console.log(err);
				var theStuff;
				if (data.length > 2) {
					theStuff = data[0].reduce(function(p,c,i) {
					p[c.name] = buildObject(data[i+1]);
					return p;
				}, {});
			} else theStuff = data[0];
				cb(err, theStuff);
			}); // doSql
		}, // multisearchload

		end: function(cb) {
			pool.end(cb);
		}, // end
	}; // return
}; // exports
