"use strict";

var env = function(k) {
	if (!process.env[k]) throw 'missing environment variable ' + k;
	return process.env[k];
}; // env

var myo = require('./index')({
		host: env('TEST_HOST'),
		user: env('TEST_USER'),
		password: env('TEST_PASSWORD'),
		database: env('TEST_DATABASE'),
		port: process.env['TEST_PORT'] || 3306,
	}), // myo
	assert = require('assert'),
	async = require('async'),
	fs = require('fs');

var tests = {
	simpleNumber: 1,
	simpleString: 'foo',
	simpleObject: {
		bar: 2
	}, // simpleObject
	complexObject: {
		baz: 7,
		qux: 'I R teh qux!',
		sub: {
			wan: 3,
			can: 'lerp',
		}, // sub
	}, // complexObject
	simpleArray: [1, 2, 3],
	complexArray: [1, 2, {
			name: 'Dennis',
			old: false,
			age: 37,
		},
		[3, 5, 7, 9, 11], 19, 'omega'
	], // complex array
	largeString: fs.readFileSync('ipsum.txt', {
		encoding: 'utf8',
	}), // largeString
}; // tests


var ITERATIONS = 100;


var originalTests = Object.keys(tests),
	addTest = function(i) {
		return function(key) {
			tests[key + '-' + i] = tests[key];
		}; // return
	}; // addTest
	

for (var i = 0; i < ITERATIONS; ++i)
	originalTests.forEach(addTest(i));


var makeTest = function(test) {
	console.log('starting', test);
	var key = 'test.' + test,
		value = tests[test];
	return function(cb) {
		myo.store(key, value, function(err) {
			if (err) return cb(err);
			myo.load(key, function(err, obj) {
				if (err) return cb(err);
				try {
					assert.deepEqual(obj, value);
				} catch (ex) {
					return cb(ex);
				} // catch
				console.log(test, 'OK');
				return cb();
			}); // load
		}); // store
	}; // return
}; // makeTest


var multiWriteTest = makeTest('complexArray'),
	multiWrite = [];

for (i = 0; i < ITERATIONS; ++i) multiWrite.push(multiWriteTest);


console.log('starting tests');

var start = Date.now();

var end = function(err) {
	myo.end();
	if (err) console.error('err:', err);
	else console.log('tests OK', Date.now() - start, 'ms');
}; // end

async.parallel(Object.keys(tests).map(makeTest), function(err) {
	if (err) return end(err);
	
	async.parallel([{
		k: 'name',
		v: 'Dennis'
	}, {
		k: 'age',
		v: 37
	}].map(function(c) {
		return function(cb) {
			console.log('starting search', c.k, '=', c.v);
			myo.search(c.k, c.v, function(err, data) {
				if (err) return cb(err);
				data.forEach(function(row) {
					assert.equal(row.name.split('.').pop(), c.k);
				}); // forEach
				try {
					assert(data.length >= ITERATIONS + 1, 'insufficient rows returned for ' + c.k + ' = ' + c.v);
				} catch (ex) {
					return cb(ex);
				} // catch
				console.log('search', c.k, '=', c.v, 'OK');
				cb();
			}); // search
		}; // return
	}), function(err) {
		if (err) return end(err);
		console.log('start multi-write');
		async.parallel(multiWrite, end);
	}); // parallel
}); // parallel
