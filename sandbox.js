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
}); // myo
	
myo.multisearchload(['baz'], 7, 0, function(err, data) {
	if(err) return errHandler(err);
	console.log(data);
	myo.end();
});
