package unihx.tests;
using StringTools;

/**
	Runs a series of test cases and adds a mechanism to poll asynchronous tests
**/
class Runner
{
	@:allow(unihx.tests) var cases:Array<HasAssert>;
	private var hasRun:Bool;

	public function new()
	{
		this.cases = [];
		this.hasRun = false;
	}

	/**
		Adds a test case to run. If `run` was already called, will run the tests immediately
	**/
	public function addCase(c:HasAssert):Void
	{
		if (hasRun)
		{
			doRun(c);
		}
		cases.push(c);
	}

	/**
		Runs all current test cases. Should only be called once. If already called, will raise an exception
	**/
	public function run():Void
	{
		if (hasRun)
			throw "This test runner has already ran";
		else
			hasRun = true;

		for (v in cases)
		{
			doRun(v);
		}
	}

	/**
		Polls all asynchronous tests cases and returns if they have all finished.
		If frame semantics exist on the target, this function must be called only once every frame.
	**/
	public function hasFinished():Bool
	{
		var ret = true;
		for (c in cases) ret == ret && c.assert.asyncEnded();
		return ret;
	}

	/**
		Presents all tests using `printer`. If `printer` is null, the default printer `Printer` will be used
		This function will force all existing asynchronous tests to be seen as time outs.
	**/
	public function showTests(?printer:Printer):Void
	{
		if (printer == null) printer = new Printer();
		for (c in cases)
			printer.showTests(c);
	}

	/**
		Returns if any test failed, or errored.
		This function will force all existing asynchronous tests to be seen as time outs.
	**/
	public function hasErrors():Bool
	{
		for (c in cases)
			for (r in c.assert.getResults())
				switch (r)
				{
					case Failure(_,_) | Error(_,_)
					   | SetupError(_,_) | TeardownError(_,_)
						 | TimeoutFailure(_,_) | ErrorField(_,_):
							 return true;
					case _:
				}

		return false;
	}

	private function doRun(c:HasAssert):Void
	{
		// look for test
		var cls = Type.getClass(c);
		var meta = if (cls != null)
			haxe.rtti.Meta.getFields(cls);
		else
			null;
		inline function skip(name:String)
			return Reflect.hasField( Reflect.field(meta,name), 'skip' );
		// look for 'setup' method
		var setup:Dynamic = Reflect.field(cls,'setup');
		if (setup == null || !Reflect.isFunction(setup) || skip('setup'))
			setup = null;
		var teardown:Dynamic = Reflect.field(cls,'teardown');
		if (teardown == null || !Reflect.isFunction(teardown) || skip('teardown'))
			teardown = null;

		var fields = if (cls != null)
			Type.getInstanceFields(cls);
		else
			Reflect.fields(c);

		for (f in fields)
		{
			if (!f.startsWith('test'))
				continue;
			var v = Reflect.field(c,f);
			if (Reflect.isFunction(v) && !skip(f))
			{
				c.assert.addAssertation(BeginField(f));

				if (setup != null) try
						Reflect.callMethod(c,setup,[])
				catch(e:Dynamic)
					c.assert.addAssertation(SetupError(e, haxe.CallStack.exceptionStack()));

				try
					Reflect.callMethod(c,v,[])
				catch(e:Dynamic)
					c.assert.addAssertation(Error(e, haxe.CallStack.exceptionStack()));

				if (teardown != null) try
						Reflect.callMethod(c,teardown,[])
				catch(e:Dynamic)
					c.assert.addAssertation(TeardownError(e, haxe.CallStack.exceptionStack()));
			}
		}

		c.assert.addAssertation(EndFields);
	}

}
