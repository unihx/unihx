package unihx.tests;
import haxe.PosInfos;
import haxe.io.Bytes;
import haxe.Timer;

using Lambda;

/**
	* This class mirrors the utest `Assert` class, but providing member functions so assertions
	* can be tested asynchronously and still keep their own environment.
	* Its use is straight forward:
	* <pre>
	* public function testObvious() {
	* assert.equals(1, 0); // fails
	* assert.isFalse(1 == 1, "guess what?"); // fails and returns the passed message
	* assert.isTrue(true); // successfull
	* }
	* </pre>
	*/
class Assert
{
	public function new()
	{
		this.results = new Array();
		this.asyncs = [];
		this.curFrame = 0;
	}

	/**
		* Returns a stack of results for the current testing workflow. Any async test waiting completion
		* will be set as timed out, and
		* by other classes of the utest library.
		*/
	public function getResults():Array<Assertation>
	{
		for (i in 0...asyncs.length)
		{
			checkTimeout(i,true);
		}
		return results.array();
	}

	var results : Array<Assertation>;
	var asyncs : Array<{ pos:PosInfos, timeout:Timeout, startTime:Float, startFrame:Int }>;
	var curFrame:Int;

	/**
	  * Creates an asynchronous context for test execution. The returned function must be called
		* when the asyncrhonous context is done.
		* @param timeout: sets the time until time out. May be set in either milliseconds or frame amount
		* @pos: code position
	  */
	public function createAsync(?timeout:Timeout, ?pos:PosInfos):Void->Void
	{
		var cur = asyncs.length;
		if (timeout == null)
			timeout = MS(200);
		asyncs.push({ pos:pos, timeout:timeout, startTime:Timer.stamp() * 1000, startFrame:curFrame });
		return function() {
			if (asyncs[cur] == null)
			{
				warn('Asynchronous function set as done, however it doesn\'t exist anymore',pos);
			}
			checkTimeout(cur);
			asyncs[cur] = null;
		};
	}

	/**
	  * This function must be called each frame to check if all asynchronous operations have ended.
	  * The `frame` amount is computed by the amount of times this function is called - so beware to call this only once each frame
	  */
	public function asyncEnded():Bool
	{
		for (i in 0...asyncs.length)
		{
			checkTimeout(i);
		}
		this.curFrame++;

		for (a in asyncs)
			if (a != null)
				return false;
		return true;
	}

	private function checkTimeout(index:Int,forceFail=false):Void
	{
		var v = asyncs[index];
		if (v == null) return;

		switch(v.timeout)
		{
			case MS(time):
				var cur = haxe.Timer.stamp() * 1000;
				if (forceFail || cur > (v.startTime + time))
				{
					results.push(TimeoutFailure(v.pos));
					asyncs[index] = null;
				}
			case NFrames(frames):
				if (forceFail || this.curFrame > (v.startFrame + frames))
				{
					results.push(TimeoutFailure(v.pos));
					asyncs[index] = null;
				}
		}
	}

	/**
		* Asserts successfully when the condition is true.
		* @param cond: The condition to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function isTrue(cond : Bool, ?msg : String, ?pos : PosInfos) {
		if (results == null) throw "results is not currently bound to any assert context";
		if (null == msg)
			msg = "expected true";
		if(cond)
			results.push(Success(pos));
		else
			results.push(Failure(msg, pos));
	}

	/**
		* Asserts successfully when the condition is false.
		* @param cond: The condition to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function isFalse(value : Bool, ?msg : String, ?pos : PosInfos) {
		if (null == msg)
			msg = "expected false";
		isTrue(value == false, msg, pos);
	}

	/**
		* Asserts successfully when the value is null.
		* @param value: The value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function isNull(value : Dynamic, ?msg : String, ?pos : PosInfos) {
		if (msg == null)
			msg = "expected null but was " + q(value);
		isTrue(value == null, msg, pos);
	}

	/**
		* Asserts successfully when the value is not null.
		* @param value: The value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function notNull(value : Dynamic, ?msg : String, ?pos : PosInfos) {
		if (null == msg)
			msg = "expected not null";
		isTrue(value != null, msg, pos);
	}

	/**
		* Asserts successfully when the 'value' parameter is of the of the passed type 'type'.
		* @param value: The value to test
		* @param type: The type to test against
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function is(value : Dynamic, type : Dynamic, ?msg : String , ?pos : PosInfos) {
		if (msg == null) msg = "expected type " + typeToString(type) + " but was " + typeToString(Type.getClass(value));
		isTrue(Std.is(value, type), msg, pos);
	}

	/**
		* Asserts successfully when the value parameter is not the same as the expected one.
		* <pre>
		* Assert.notEquals(10, age);
		* </pre>
		* @param expected: The expected value to check against
		* @param value: The value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function notEquals(expected : Dynamic, value : Dynamic, ?msg : String , ?pos : PosInfos) {
		if(msg == null) msg = "expected " + q(expected) + " and testa value " + q(value) + " should be different";
		isFalse(expected == value, msg, pos);
	}

	/**
		* Asserts successfully when the value parameter is equal to the expected one.
		* <pre>
		* Assert.equals(10, age);
		* </pre>
		* @param expected: The expected value to check against
		* @param value: The value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function equals(expected : Dynamic, value : Dynamic, ?msg : String , ?pos : PosInfos) {
		if(msg == null) msg = "expected " + q(expected) + " but was " + q(value);
		isTrue(expected == value, msg, pos);
	}


	/**
		* Asserts successfully when the value parameter does match against the passed EReg instance.
		* <pre>
		* Assert.match(~/x/i, "haXe");
		* </pre>
		* @param pattern: The pattern to match against
		* @param value: The value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function match(pattern : EReg, value : Dynamic, ?msg : String , ?pos : PosInfos) {
		if(msg == null) msg = "the value " + q(value) + "does not match the provided pattern";
		isTrue(pattern.match(value), msg, pos);
	}

	/**
		* Same as Assert.equals but considering an approximation error.
		* <pre>
		* Assert.floatEquals(Math.PI, value);
		* </pre>
		* @param expected: The expected value to check against
		* @param value: The value to test
		* @param approx: The approximation tollerance. Default is 1e-5
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		* @todo test the approximation argument
		*/
	public function floatEquals(expected : Float, value : Float, ?approx : Float, ?msg : String , ?pos : PosInfos) : Void {
		if (msg == null) msg = "expected " + q(expected) + " but was " + q(value);
		return isTrue(_floatEquals(expected, value, approx), msg, pos);
	}

	function _floatEquals(expected : Float, value : Float, ?approx : Float)
	{
		if (Math.isNaN(expected))
			return Math.isNaN(value);
		else if (Math.isNaN(value))
			return false;
		else if (!Math.isFinite(expected) && !Math.isFinite(value))
			return (expected > 0) == (value > 0);
		if (null == approx)
			approx = 1e-5;
		return Math.abs(value-expected) < approx;
	}

	function getTypeName(v : Dynamic) {
		switch(Type.typeof(v))
		{
			case TNull    : return "[null]";
			case TInt     : return "Int";
			case TFloat   : return "Float";
			case TBool    : return "Bool";
			case TFunction: return "function";
			case TClass(c): return Type.getClassName(c);
			case TEnum(e) : return Type.getEnumName(e);
			case TObject  : return "Object";
			case TUnknown : return "Unknown";
		}
	}

	function isIterable(v : Dynamic, isAnonym : Bool) {
		var fields = isAnonym ? Reflect.fields(v) : Type.getInstanceFields(Type.getClass(v));
		if(!Lambda.has(fields, "iterator")) return false;
		return Reflect.isFunction(Reflect.field(v, "iterator"));
	}

	function isIterator(v : Dynamic, isAnonym : Bool) {
		var fields = isAnonym ? Reflect.fields(v) : Type.getInstanceFields(Type.getClass(v));
		if(!Lambda.has(fields, "next") || !Lambda.has(fields, "hasNext")) return false;
		return Reflect.isFunction(Reflect.field(v, "next")) && Reflect.isFunction(Reflect.field(v, "hasNext"));
	}

	function sameAs(expected : Dynamic, value : Dynamic, status : LikeStatus) {
		var texpected = getTypeName(expected);
		var tvalue = getTypeName(value);

		if(texpected != tvalue) {
			status.error = "expected type " + texpected + " but it is " + tvalue + (status.path == '' ? '' : ' for field ' + status.path);
			return false;
		}
		switch(Type.typeof(expected))
		{
			case TFloat:
				if (!_floatEquals(expected, value))
				{
					status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
					return false;
				}
				return true;
			case TNull, TInt, TBool:
				if(expected != value) {
					status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
					return false;
				}
				return true;
			case TFunction:
				if (!Reflect.compareMethods(expected, value))
				{
					status.error = "expected same function reference" + (status.path == '' ? '' : ' for field '+status.path);
					return false;
				}
				return true;
			case TClass(c):
				var cexpected = Type.getClassName(c);
				var cvalue = Type.getClassName(Type.getClass(value));
				if (cexpected != cvalue)
				{
					status.error = "expected instance of " + q(cexpected) + " but it is " + q(cvalue) + (status.path == '' ? '' : ' for field '+status.path);
					return false;
				}

				// string
				if (Std.is(expected, String) && expected != value)
				{
					status.error = "expected '" + expected + "' but it is '" + value + "'";
					return false;
				}

				// arrays
				if(Std.is(expected, Array)) {
					if(status.recursive || status.path == '') {
						if(expected.length != value.length) {
							status.error = "expected "+expected.length+" elements but they were "+value.length + (status.path == '' ? '' : ' for field '+status.path);
							return false;
						}
						var path = status.path;
						for(i in 0...expected.length) {
							status.path = path == '' ? 'array['+i+']' : path + '['+i+']';
							if (!sameAs(expected[i], value[i], status))
							{
								status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
								return false;
							}
						}
					}
					return true;
				}

				// date
				if(Std.is(expected, Date)) {
					if(expected.getTime() != value.getTime()) {
						status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
						return false;
					}
					return true;
				}

				// bytes
				if(Std.is(expected, Bytes)) {
					if(status.recursive || status.path == '') {
						var ebytes : Bytes = expected;
						var vbytes : Bytes = value;
						if (ebytes.length != vbytes.length) return false;
						for (i in 0...ebytes.length)
							if (ebytes.get(i) != vbytes.get(i))
							{
								status.error = "expected byte " + ebytes.get(i) + " but wss " + ebytes.get(i) + (status.path == '' ? '' : ' for field '+status.path);
								return false;
							}
					}
					return true;
				}

				// hash, inthash
				if(Std.is(expected, haxe.ds.StringMap) || Std.is(expected, haxe.ds.IntMap)) {
					if(status.recursive || status.path == '') {
						var keys  = Lambda.array({ iterator : function() return expected.keys() });
						var vkeys = Lambda.array({ iterator : function() return value.keys() });
						if(keys.length != vkeys.length) {
							status.error = "expected "+keys.length+" keys but they were "+vkeys.length + (status.path == '' ? '' : ' for field '+status.path);
							return false;
						}
						var path = status.path;
						for(key in keys) {
							status.path = path == '' ? 'hash['+key+']' : path + '['+key+']';
							if (!sameAs(expected.get(key), value.get(key), status))
							{
								status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
								return false;
							}
						}
					}
					return true;
				}

				// iterator
				if(isIterator(expected, false)) {
					if(status.recursive || status.path == '') {
						var evalues = Lambda.array({ iterator : function() return expected });
						var vvalues = Lambda.array({ iterator : function() return value });
						if(evalues.length != vvalues.length) {
							status.error = "expected "+evalues.length+" values in Iterator but they were "+vvalues.length + (status.path == '' ? '' : ' for field '+status.path);
							return false;
						}
						var path = status.path;
						for(i in 0...evalues.length) {
							status.path = path == '' ? 'iterator['+i+']' : path + '['+i+']';
							if (!sameAs(evalues[i], vvalues[i], status))
							{
								status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
								return false;
							}
						}
					}
					return true;
				}

				// iterable
				if(isIterable(expected, false)) {
					if(status.recursive || status.path == '') {
						var evalues = Lambda.array(expected);
						var vvalues = Lambda.array(value);
						if(evalues.length != vvalues.length) {
							status.error = "expected "+evalues.length+" values in Iterable but they were "+vvalues.length + (status.path == '' ? '' : ' for field '+status.path);
							return false;
						}
						var path = status.path;
						for(i in 0...evalues.length) {
							status.path = path == '' ? 'iterable['+i+']' : path + '['+i+']';
							if(!sameAs(evalues[i], vvalues[i], status))
								return false;
						}
					}
					return true;
				}

				// custom class
				if(status.recursive || status.path == '') {
					var fields = Type.getInstanceFields(Type.getClass(expected));
					var path = status.path;
					for(field in fields) {
						status.path = path == '' ? field : path+'.'+field;
						var e = Reflect.field(expected, field);
						if(Reflect.isFunction(e)) continue;
						var v = Reflect.field(value, field);
						if(!sameAs(e, v, status))
							return false;
					}
				}

				return true;
			case TEnum(e) :
				var eexpected = Type.getEnumName(e);
				var evalue = Type.getEnumName(Type.getEnum(value));
				if (eexpected != evalue)
				{
					status.error = "expected enumeration of " + q(eexpected) + " but it is " + q(evalue) + (status.path == '' ? '' : ' for field '+status.path);
					return false;
				}
				if (status.recursive || status.path == '')
				{
					if (Type.enumIndex(expected) != Type.enumIndex(value))
					{
						status.error = 'expected ' + q(Type.enumConstructor(expected)) + ' but is ' + q(Type.enumConstructor(value)) + (status.path == '' ? '' : ' for field '+status.path);
						return false;
					}
					var eparams = Type.enumParameters(expected);
					var vparams = Type.enumParameters(value);
					var path = status.path;
					for (i in 0...eparams.length)
					{
						status.path = path == '' ? 'enum[' + i + ']' : path + '[' + i + ']';
						if (!sameAs(eparams[i], vparams[i], status))
						{
							status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field ' + status.path);
							return false;
						}
					}
				}
				return true;
			case TObject  :
				// anonymous object
				if(status.recursive || status.path == '') {
					var tfields = Reflect.fields(value);
					var fields = Reflect.fields(expected);
					var path = status.path;
					for(field in fields) {
						tfields.remove(field);
						status.path = path == '' ? field : path+'.'+field;
						if(!Reflect.hasField(value, field)) {
							status.error = "expected field " + status.path + " does not exist in " + q(value);
							return false;
						}
						var e = Reflect.field(expected, field);
						if(Reflect.isFunction(e))
							continue;
						var v = Reflect.field(value, field);
						if(!sameAs(e, v, status))
							return false;
					}
					if(tfields.length > 0)
					{
						status.error = "the tested object has extra field(s) (" + tfields.join(", ") + ") not included in the expected ones";
						return false;
					}
				}

				// iterator
				if(isIterator(expected, true)) {
					if(!(isIterator(value, true))) {
						status.error = "expected Iterable but it is not " + (status.path == '' ? '' : ' for field '+status.path);
						return false;
					}
					if(status.recursive || status.path == '') {
						var evalues = Lambda.array({ iterator : function() return expected });
						var vvalues = Lambda.array({ iterator : function() return value });
						if(evalues.length != vvalues.length) {
							status.error = "expected "+evalues.length+" values in Iterator but they were "+vvalues.length + (status.path == '' ? '' : ' for field '+status.path);
							return false;
						}
						var path = status.path;
						for(i in 0...evalues.length) {
							status.path = path == '' ? 'iterator['+i+']' : path + '['+i+']';
							if (!sameAs(evalues[i], vvalues[i], status))
							{
								status.error = "expected " + q(expected) + " but it is " + q(value) + (status.path == '' ? '' : ' for field '+status.path);
								return false;
							}
						}
					}
					return true;
				}

				// iterable
				if(isIterable(expected, true)) {
					if(!(isIterable(value, true))) {
						status.error = "expected Iterator but it is not " + (status.path == '' ? '' : ' for field '+status.path);
						return false;
					}
					if(status.recursive || status.path == '') {
						var evalues = Lambda.array(expected);
						var vvalues = Lambda.array(value);
						if(evalues.length != vvalues.length) {
							status.error = "expected "+evalues.length+" values in Iterable but they were "+vvalues.length + (status.path == '' ? '' : ' for field '+status.path);
							return false;
						}
						var path = status.path;
						for(i in 0...evalues.length) {
							status.path = path == '' ? 'iterable['+i+']' : path + '['+i+']';
							if(!sameAs(evalues[i], vvalues[i], status))
								return false;
						}
					}
					return true;
				}
				return true;
			case TUnknown :
				return throw "Unable to compare two unknown types";
		}
		return throw "Unable to compare values: " + q(expected) + " and " + q(value);
	}

	function q(v : Dynamic)
	{
		if (Std.is(v, String))
			return '"' + StringTools.replace(v, '"', '\\"') + '"';
		else
			return Std.string(v);
	}

	/**
		* Check that value is an object with the same fields and values found in expected.
		* The default behavior is to check nested objects in fields recursively.
		* <pre>
		* Assert.same({ name : "utest"}, ob);
		* </pre>
		* @param expected: The expected value to check against
		* @param value: The value to test
		* @param recursive: States whether or not the test will apply also to sub-objects.
		* Defaults to true
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function same(expected : Dynamic, value : Dynamic, ?recursive : Bool, ?msg : String, ?pos : PosInfos) {
		var status = { recursive : null == recursive ? true : recursive, path : '', error : null };
		if(sameAs(expected, value, status)) {
			isTrue(true, msg, pos);
		} else {
			fail(msg == null ? status.error : msg, pos);
		}
	}

	/**
		* It is used to test an application that under certain circumstances must
		* react throwing an error. This assert guarantees that the error is of the
		* correct type (or Dynamic if non is specified).
		* <pre>
		* Assert.raises(function() { throw "Error!"; }, String);
		* </pre>
		* @param method: A method that generates the exception.
		* @param type: The type of the expected error. Defaults to Dynamic (catch all).
		* @param msgNotThrown: An optional error message used when the function fails to raise the expected
		* exception. If not passed a default one will be used
		* @param msgWrongType: An optional error message used when the function raises the exception but it is
		* of a different type than the one expected. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		* @todo test the optional type parameter
		*/
	public function raises(method:Void -> Void, ?type:Dynamic, ?msgNotThrown : String , ?msgWrongType : String, ?pos : PosInfos) {
		try {
			method();
			var name = Type.getClassName(type);
			if (name == null) name = ""+type;
			if (null == msgNotThrown)
				msgNotThrown = "exception of type " + name + " not raised";
			fail(msgNotThrown, pos);
		} catch (ex : Dynamic) {
			if (type != null && !Std.is(ex,Type))
			{
				if (null == msgWrongType)
				{
					msgWrongType = "expected throw of type " + typeToString(type) + " but was "  + typeToString(Type.getClass(ex));
				}
				fail(msgWrongType, pos);
			}
		}
	}

	/**
		* Checks that the test value matches at least one of the possibilities.
		* @param possibility: An array of mossible matches
		* @param value: The value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function allows<T>(possibilities : Array<T>, value : T, ?msg : String , ?pos : PosInfos) {
		if(Lambda.has(possibilities, value)) {
			isTrue(true, msg, pos);
		} else {
			fail(msg == null ? "value " + q(value) + " not found in the expected possibilities " + possibilities : msg, pos);
		}
	}

	/**
		* Checks that the test array contains the match parameter.
		* @param match: The element that must be included in the tested array
		* @param values: The values to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function contains<T>(match : T, values : Array<T>, ?msg : String , ?pos : PosInfos) {
		if(Lambda.has(values, match)) {
			isTrue(true, msg, pos);
		} else {
			fail(msg == null ? "values " + q(values) + " do not contain "+match: msg, pos);
		}
	}

	/**
		* Checks that the test array does not contain the match parameter.
		* @param match: The element that must NOT be included in the tested array
		* @param values: The values to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function notContains<T>(match : T, values : Array<T>, ?msg : String , ?pos : PosInfos) {
		if(!Lambda.has(values, match)) {
			isTrue(true, msg, pos);
		} else {
			fail(msg == null ? "values " + q(values) + " do contain "+match: msg, pos);
		}
	}

	/**
		* Checks that the expected values is contained in value.
		* @param match: the string value that must be contained in value
		* @param value: the value to test
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		*/
	public function stringContains(match : String, value : String, ?msg : String , ?pos : PosInfos) {
		if (value != null && value.indexOf(match) >= 0) {
			isTrue(true, msg, pos);
		} else {
			fail(msg == null ? "value " + q(value) + " does not contain " + q(match) : msg, pos);
		}
	}

	public function stringSequence(sequence : Array<String>, value : String, ?msg : String , ?pos : PosInfos) {
		if (null == value)
		{
			fail(msg == null ? "null argument value" : msg, pos);
			return;
		}
		var p = 0;
		for (s in sequence)
		{
			var p2 = value.indexOf(s, p);
			if (p2 < 0)
			{
				if (msg == null)
				{
					msg = "expected '" + s + "' after ";
					if (p > 0)
					{
						var cut = value.substr(0, p);
						if (cut.length > 30)
							cut = '...' + cut.substr( -27);
						msg += " '" + cut + "'" ;
					} else
						msg += " begin";
				}
				fail(msg, pos);
				return;
			}
			p = p2 + s.length;
		}
		isTrue(true, msg, pos);
	}

	/**
		* Forces a failure.
		* @param msg: An optional error message. If not passed a default one will be used
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function fail(msg = "failure expected", ?pos : PosInfos) {
		isTrue(false, msg, pos);
	}

	/**
		* Creates a warning message.
		* @param msg: A mandatory message that justifies the warning.
		* @param pos: Code position where the Assert call has been executed. Don't fill it
		* unless you know what you are doing.
		*/
	public function warn(msg, ?pos:PosInfos) {
		results.push(Warning(msg,pos));
	}

	function typeToString(t : Dynamic)
	{
		try return Type.getClassName(t) catch (e : Dynamic) { }
		try return Type.getEnumName(t) catch(e : Dynamic) {}
		try return Std.string(Type.typeof(t)) catch (e : Dynamic) { }
		try return Std.string(t) catch (e : Dynamic) { }
		return '<unable to retrieve type name>';
	}
}

private typedef LikeStatus = {
	recursive : Bool,
	path : String,
	error : String
};
