package unihx.tests;

class Printer
{
	public function new()
	{
	}

	public dynamic function print(str:String):Void
	{
		haxe.Log.trace(str,null);
	}

	private static function showPos(p:haxe.PosInfos)
	{
		if (p == null)
			return "";
		return p.fileName + ": " + p.lineNumber + ": ";
	}

	public function showTests(c:HasAssert)
	{
		var cls = Type.getClass(c);
		if (cls == null)
			print( 'Test case:' );
		else
			print( Type.getClassName(cls) + ":" );

		var results = c.assert.getResults();
		var ctx = new StringBuf(),
				err = new StringBuf(),
				hasVal = false,
				lastPos = null;
		for (r in results)
		{
			switch (r)
			{
				case BeginField(_) | EndFields:
					var c = ctx.toString(),
							e = err.toString();
					print(c);
					if (e != "")
						print(e);
				case BeginAsync(_,p) | Success(p)
				   | Failure(_,p) | Warning(_,p)
					 | TimeoutFailure(_,p):
						 lastPos = p;
				case _:
			}

			switch (r)
			{
				case BeginField(f):
					ctx = new StringBuf();
					err = new StringBuf();
					ctx.add('\t'); ctx.add(f); ctx.add(' : ');
				case ErrorField(f,msg):
					ctx.add('E');
					err.add(msg);
				case BeginAsync(name,pos):
					ctx.add('>');
				case EndFields:
					print("");
				case Success(_):
					ctx.add('.');
				case Failure(msg,p):
					ctx.add('F');
					err.add(showPos(p));
					err.add(msg);
					err.add('\n\t\t');
				case Warning(msg,p):
					ctx.add('W');
					err.add(showPos(p));
					err.add(msg);
					err.add('\n\t\t');

				case Error(e,stack):
					ctx.add('E');
					err.add(showPos(lastPos));
					err.add(Std.string(e) + ": \n");
					err.add(haxe.CallStack.toString(stack));
					err.add('\n\t\t');
				case SetupError(e,stack):
					err.add("Setup Error: ");
					err.add(Std.string(e) + ": \n");
					err.add(haxe.CallStack.toString(stack));
					err.add('\n\t\t');
				case TeardownError(e,stack):
					err.add("Teardown Error: ");
					err.add(Std.string(e) + ": \n");
					err.add(haxe.CallStack.toString(stack));
					err.add('\n\t\t');

				case TimeoutFailure(msg,pos):
					err.add(showPos(pos));
					err.add('Async timeout: ');
					err.add(msg);
					err.add('\n\t\t');
			}
		}
	}
}
