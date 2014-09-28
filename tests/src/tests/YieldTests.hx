package tests;
import utest.Assert;
import unihx._internal.YieldBase;

using Lambda;

class YieldTests
{
	public function new()
	{
	}

	macro private static function test(expr:haxe.macro.Expr):haxe.macro.Expr.ExprOf<unihx._internal.YieldBase>
	{
		var ret = unihx._internal.YieldGenerator.make('tests.unihx',expr);
		return macro ($ret : unihx._internal.YieldBase);
	}

#if !macro
	public function test_basic()
	{
		var t1 = test({
			var a:Array<Float> = [];
			{
				a.push(1);
				{
					@yield {retn:"A",arr:a};
					a.push(1.1);
				}
				{
					a.push(1.2);
					@yield {retn:"B",arr:a};
					a.push(1.3);
					a = [];
				}
				a.push(2);
				@yield {retn:"b",arr:a};
				a.push(3);
			}
			@yield {retn:"c",arr:a};
			a.push(4);
		});
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"A",arr:[1]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"B",arr:[1,1.1,1.2]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"b",arr:[2]}, t1.next());
		Assert.isTrue(t1.hasNext());
		var last = t1.next();
		Assert.same({retn:"c",arr:[2,3]}, last);
		Assert.isFalse(t1.hasNext());
		Assert.same([2,3,4],last.arr);
	}

	public function test_if()
	{
		var t = true, f = false;
		var t1 = test({
			var a:Array<Float> = [];
			if (t)
			{
				a.push(1);
				if (true)
				{
					@yield {retn:"A",arr:a};
					a.push(1.1);
				}
				if (f)
				{
					a.push(-2);
					@yield {retn:"-a",arr:a};
					a.push(-3);
				} else {
					a.push(1.2);
					@yield {retn:"B",arr:a};
					a.push(1.3);
				}
				a = [];
				a.push(2);
				@yield {retn:"b",arr:a};
				a.push(3);
			}
			@yield {retn:"c",arr:a};
			a.push(4);
		});

		Assert.isTrue(t1.hasNext());
		f = true; //it shouldn't change the behavior here - as vars aren't captured, they are copied
		Assert.same({retn:"A",arr:[1]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"B",arr:[1,1.1,1.2]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"b",arr:[2]}, t1.next());
		Assert.isTrue(t1.hasNext());
		var last = t1.next();
		Assert.same({retn:"c",arr:[2,3]}, last);
		Assert.isFalse(t1.hasNext());
		Assert.same([2,3,4],last.arr);

		//check for deep nesting
		var t = true, f = false;
		var t1 = test({
			var a:Array<Float> = [];
			if (t)
			{
				a.push(1);
				if (true)
				{
					@yield {retn:"A",arr:a};
					a.push(1.1);
				}
				if (f)
				{
					a.push(-2);
					@yield {retn:"-a",arr:a};
					a.push(-3);
					if (f)
					{
						a.push(-4);
						@yield null;
						a.push(-5);
					} else if (false) {
						a.push(-6);
						@yield null;
						if (true)
						{
							a.push(-6.1);
							@yield null;
							a.push(-6.2);
						}
						a.push(-7);
						@yield null;
						a.push(-8);
					} else {
						a.push(-9);
						@yield null;
						a.push(-10);
					}
				} else {
					if (t)
					{
						a.push(1.11);
						@yield {retn:"A1",arr:a};
						a.push(1.12);
					} else {
						a.push(-11);
						@yield null;
						a.push(-12);
					}
					a.push(1.2);
					@yield {retn:"B",arr:a};
					a.push(1.3);
				}
				a = [];
				//test now first true, then false
				if (t)
				{
					a.push(1.4);
					@yield {retn:"B1",arr:a};
					a.push(1.5);
					@yield {retn:"B2",arr:a};
				} else if (f) {
					a.push(-4);
					@yield null;
					a.push(-5);
				} else {
					a.push(-6);
					@yield null;
					if (true)
					{
						a.push(-6.1);
						@yield null;
						a.push(-6.2);
					}
					a.push(-7);
					@yield null;
					a.push(-8);
				}
				a = [];
				a.push(2);
				@yield {retn:"b",arr:a};
				a.push(3);
			}
			@yield {retn:"c",arr:a};
			a.push(4);
		});

		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"A",arr:[1]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"A1",arr:[1,1.1,1.11]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"B",arr:[1,1.1,1.11,1.12,1.2]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"B1",arr:[1.4]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"B2",arr:[1.4,1.5]}, t1.next());
		Assert.isTrue(t1.hasNext());
		Assert.same({retn:"b",arr:[2]}, t1.next());
		Assert.isTrue(t1.hasNext());
		var last = t1.next();
		Assert.same({retn:"c",arr:[2,3]}, last);
		Assert.isFalse(t1.hasNext());
		Assert.same([2,3,4],last.arr);
	}

	public function test_fibonacci()
	{
		//returns the 10 first fibonacci numbers
		var fib = test({
			var an2 = 0, an1 = 1;
			@yield 0; @yield 1;
			for (i in 0...8)
			{
				var c = an1 + an2;
				an2 = an1; an1 = c;
				@yield c;
			}
		});

		Assert.same([0,1, 1, 2, 3, 5, 8, 13, 21, 34], [for(v in fib) v]);

		//infinite version
		var fib = test({
			var an2 = 0, an1 = 1;
			@yield 0; @yield 1;
			while(true)
			{
				var c = an1 + an2;
				an2 = an1; an1 = c;
				@yield c;
			}
		});

		for (i in [0,1, 1, 2, 3, 5, 8, 13, 21, 34])
		{
			Assert.isTrue(fib.hasNext());
			Assert.equals(i,fib.next());
		}
		Assert.isTrue(fib.hasNext());
	}

	public function test_fact()
	{
		//first 10 factorial numbers
		var fact = test({
			var acc = 1;
			@yield 1;
			for (i in 1...10)
			{
				@yield (acc *= i);
			}
		});

		Assert.same([1,1,2,6,24,120,720,5040,40320,362880], [for(v in fact) v]);

		//infinite version
		var fact = test({
			var acc = 1, i = 1;
			@yield 1;
			while(true)
			{
				@yield (acc *= i++);
			}
		});

		for (i in [1,1,2,6,24,120,720,5040,40320,362880])
		{
			Assert.isTrue(fact.hasNext());
			Assert.equals(i,fact.next());
		}
		Assert.isTrue(fact.hasNext());
	}

	public function test_array_for()
	{
		var t = test({
			var arr = [1,2,3,4,5,6,7], lastValue = -1;
			for (a in arr)
			{
				var myval = a + lastValue;
				lastValue = a;
				@yield myval;
			}
		});
		for (i in [0, 3, 5, 7, 9, 11, 13])
		{
			Assert.isTrue(t.hasNext());
			Assert.equals(i, t.next());
		}

		//calling iterator() directly
		var t = test({
			var arr = [1,2,3,4,5,6,7], lastValue = -1;
			for (a in arr.iterator())
			{
				var myval = a + lastValue;
				lastValue = a;
				@yield myval;
			}
		});
		for (i in [0, 3, 5, 7, 9, 11, 13])
		{
			Assert.isTrue(t.hasNext());
			Assert.equals(i, t.next());
		}
	}

	public function test_list_for()
	{
		var t = test({
			var arr = [1,2,3,4,5,6,7].list(), lastValue = -1;
			for (a in arr)
			{
				var myval = a + lastValue;
				@yield myval;
				lastValue = a;
			}
		});
		for (i in [0, 3, 5, 7, 9, 11, 13])
		{
			Assert.isTrue(t.hasNext());
			Assert.equals(i, t.next());
		}
		var t = test({
			var arr = [1,2,3,4,5,6,7].list(), lastValue = -1;
			for (a in arr.iterator())
			{
				var myval = a + lastValue;
				lastValue = a;
				@yield myval;
			}
		});
		for (i in [0, 3, 5, 7, 9, 11, 13])
		{
			Assert.isTrue(t.hasNext());
			Assert.equals(i, t.next());
		}

	}

	public function test_while()
	{
		for (rand in [true,false])
		{
			var t = true, f = false;
			var t = test({
				var i = 10, a = [1.];
				while(++i < 15)
				{
					a.push(i / 10);
					if(t)
					{
						a.push(2);
						if (true)
						{
							@yield {retn:1, arr:a};
							if(rand)
								a.push(2.05);
						}
						if (f)
						{
							a.push(-2);
							@yield {retn:-1,arr:a};
							a.push(-3);
							if (f)
							{
								a.push(-4);
								@yield null;
								a.push(-5);
							} else if (false) {
								a.push(-6);
								for(i in 0...10)
									@yield null;
								if (true)
								{
									a.push(-6.1);
									do
									{
										@yield null;
									} while(--i > 0);
									a.push(-6.2);
								}
								a.push(-7);
								@yield null;
								a.push(-8);
							} else {
								a.push(-9);
								@yield null;
								a.push(-10);
							}
						} else {
							if (t)
							{
								a.push(2.10);
								@yield {retn:2, arr:a};
								if (rand)
									a.push(2.15);
							} else {
								a.push(-11);
								@yield null;
								a.push(-12);
							}
							a.push(2.2);
							@yield {retn:3, arr:a};
							var j = 3;
							do
							{
								a.push(2 + j / 10);
								@yield {retn:j+1, arr:a};
								if (rand)
									a.push(2 + j / 10 + .05);
							} while(++j < 6);
							a.push(2.6);
						}
						a = [];
						if(t)
						{
							a.push(3);
							@yield {retn:7, arr:a};
							var j = 0;
							while(++j < 3)
							{
								a.push(3 + j / 10);
								@yield {retn:7 + j, arr:a};
							}
						} else if (f) {
							a.push(-4);
							@yield null;
							a.push(-5);
						} else {
							a.push(-6);
							@yield null;
							if (true)
							{
								a.push(-7);
								@yield null;
								a.push(-8);
							}
							a.push(-9);
							@yield null;
							a.push(-10);
						}
						a = [];
						a.push(4);
						var j = 0;
						do
						{
							@yield {retn:10 + j, arr:a};
							a.push(4 + j / 10);
							if (rand)
								a.push(4 + j / 10 + .05);
						} while(++j < 4);
					}
					@yield {retn:14, arr:a};
					a.push(5);
				}
			});

			// var answers =
			var i = 10,
					a = [1.];
			inline function getValue() return t.hasNext() ? t.next() : null;

			for (i in 11...15)
			{
				a.push(i / 10);
				a.push(2);
				Assert.same({ retn:1, arr: a }, getValue());
				if (rand) a.push(2.05);
				a.push(2.10);
				Assert.same({ retn:2, arr: a }, getValue());
				if (rand) a.push(2.15);
				a.push(2.2);
				Assert.same({ retn:3, arr : a}, getValue());
				a.push(2.3);
				Assert.same({ retn:4, arr : a}, getValue());
				if (rand) a.push(2.35);
				a.push(2.4);
				Assert.same({ retn:5, arr : a}, getValue());
				if (rand) a.push(2.45);
				a.push(2.5);
				Assert.same({ retn:6, arr : a}, getValue());
				a.push(2.6);
				a = [3];
				Assert.same({ retn:7, arr : a}, getValue());
				a.push(3.1);
				Assert.same({ retn:8, arr : a}, getValue());
				a.push(3.2);
				Assert.same({ retn:9, arr : a}, getValue());
				a = [4];
				Assert.same({ retn:10, arr : a}, getValue());
				for (i in 0...4)
				{
					a.push(4 + i / 10);
					if (rand) a.push(4 + i / 10 + .05);
					Assert.same({ retn:11 + i, arr : a}, getValue());
				}
				a.push(5);
				// Assert.same({ retn: 12, arr : a}, getValue());
			}
			// for (v in t)
				// trace(v);
		}
	}

	public function test_pat_match()
	{
		var expr = macro 10 + 20 + 60 - 10;
		var t = test({
			var acc = 0;
			while(true)
			{
				switch(expr.expr)
				{
					case EBinop(op,{ expr:EConst(CInt(x)) },{ expr:EConst(CInt(y)) }):
						acc += Std.parseInt(x);
						acc += Std.parseInt(y);
						@yield { op:op + "", acc:acc, v:2 };
						break;
					case EBinop(op,e1,{ expr:EConst(CInt(x)) }):
						acc += Std.parseInt(x);
						@yield { op:op + "", acc:acc, v:1 };
						expr = e1;
					case _:
						throw "argh: " + expr;
				}
			}
		});
		inline function getValue() return t.hasNext() ? t.next() : null;

		Assert.same({ op:"OpSub", acc:10, v:1 }, getValue());
		Assert.same({ op:"OpAdd", acc:70, v:1 }, getValue());
		Assert.same({ op:"OpAdd", acc:100, v:2 }, getValue());
		Assert.isFalse(t.hasNext());

		expr = macro @:someMeta 50 + 5 - 10 + 20 + 60 - 10;
		t = test({
			var acc = 0;
			while(true)
			{
				switch(expr.expr)
				{
					case EBinop(op,{ expr:EConst(CInt(x)) },{ expr:EConst(CInt(y)) }):
						acc += Std.parseInt(x);
						acc += Std.parseInt(y);
						@yield { op:op + "", acc:acc, v:2 };
						break;
					case EBinop(op,e1 = { expr:EBinop(_,_,_) },{ expr:EConst(CInt(x)) }):
						acc += Std.parseInt(x);
						@yield { op:op + "", acc:acc, v:1 };
						expr = e1;
					case EBinop(op,e1,e2):
						acc += 5;
						@yield { op:"no const", acc:acc, v:0 };
						switch(e1)
						{
							case macro notHere:
								acc -= 10;
							case macro @:someMeta $v:
								switch(v.expr) {
									case EConst(CInt(x)):
										@yield { acc:acc, v:3 };
										acc += Std.parseInt(x);
										@yield { acc:acc, v:4 };
									case _:
										acc -= 100;
										@yield acc;
										acc -= 90;
										@yield acc;
								}
							case _:
								acc = 4;
								@yield false;
								trace(acc);
								@yield acc;
								acc -= 10;
						}
						acc += 5;
						@yield { op:"finished", acc:acc, v:5 };
						switch (e2) {
							case { expr: EConst(CInt(x)) }:
								@yield { acc:acc, v:6 };
								acc += Std.parseInt(x);
								@yield { acc:acc, v:7 };
								acc = Std.parseInt(x);
							case _:
								acc = 0;
								@yield false;
								trace(acc);
								@yield acc;
								acc -= 10;
						}
						@yield { op:op + "", acc:acc, v:8 };
						break;
						@yield { op:op + "", acc:acc, v:9 };
					case _:
						throw "shouldnt be here: " + expr;
				}
			}
		});
		inline function getValue() return t.hasNext() ? t.next() : null;

		Assert.same({ op:"OpSub", acc:10, v:1 }, getValue());
		Assert.same({ op:"OpAdd", acc:70, v:1 }, getValue());
		Assert.same({ op:"OpAdd", acc:90, v:1 }, getValue());
		Assert.same({ op:"OpSub", acc:100, v:1 }, getValue());
		Assert.same({ op:"no const", acc:105, v:0 }, getValue());
		Assert.same({ acc:105, v:3 }, getValue());
		Assert.same({ acc:155, v:4 }, getValue());
		Assert.same({ op:"finished", acc:160, v:5 }, getValue());
		Assert.same({ acc:160, v:6 }, getValue());
		Assert.same({ acc:165, v:7 }, getValue());
		Assert.same({ op:"OpAdd", acc:5, v:8 }, getValue());
		Assert.isFalse(t.hasNext());
	}

	public function test_try()
	{
		var throwobj:Dynamic = null,
				i = 0;
		function mayThrow()
		{
			if (throwobj != null)
			{
				var t = throwobj;
				throwobj = null;
				throw t;
			}
			return i++;
		}

		var t = test({
			while(true)
			{
				var acc = 100;
				try
				{
					acc+= 10;
					@yield { v:0, retn:"A", acc:acc };
					try
					{
						acc += 2;
						if (mayThrow() == 0)
						{
							acc -= 4;
							@yield { v:mayThrow(), retn:"B", acc:acc };
							acc += 6;
							@yield { v:mayThrow(), retn:"-", acc:acc };
							acc -= 100;
						} else {
							acc += 300;
							@yield { v:mayThrow(), retn:"AB", acc:acc };
							@yield { v:mayThrow(), retn:"-", acc:acc };
							acc -= 500;
						}
					}
					catch(e:String)
					{
						@yield { v:mayThrow(), retn:"String " + e, acc:++acc };
						acc = 5;
						@yield { v:mayThrow(), retn:"String", acc:++acc };
						acc += 4;
						try
						{
							@yield { v:mayThrow(), retn:"String", acc:++acc };
							acc += 15;
							@yield { v:mayThrow(), retn:"StringT2", acc:acc };
							acc += 5;
							@yield { v:mayThrow(), retn:"-", acc:acc };
						}
						catch(e:Dynamic)
						{
							@yield true;
							try
							{
								@yield { v:mayThrow(), retn:"StringT3", acc:acc };
								acc += 20;
								@yield { v:mayThrow(), retn:"-", acc:acc };
							}
							catch(str:String)
							{
								@yield { v:mayThrow(), retn:"-", acc:acc };
							}
						}
					}
					catch(e:haxe.io.Eof)
					{
						@yield { v:mayThrow(), retn:"-", acc:acc };
					}
				}
				catch(e:haxe.io.Eof)
				{
					@yield { v:mayThrow(), retn:"eof", acc:acc };
				}
			}
		});

		inline function getValue() return t.hasNext() ? t.next() : null;
		Assert.same({ v:0, retn:"A", acc:110 }, getValue());
		Assert.same({ v:1, retn:"B", acc:108 }, getValue());
		//114
		throwobj = "SomeString";
		Assert.same({ v:2, retn:"String SomeString", acc:115 }, getValue());
		Assert.same({ v:3, retn:"String", acc:6 }, getValue());
		Assert.same({ v:4, retn:"String", acc:11 }, getValue());
		Assert.same({ v:5, retn:"StringT2", acc:26 }, getValue());
		//31
		throwobj = new haxe.io.Eof();
		Assert.equals(true,getValue());
		Assert.same({ v:6, retn:"StringT3", acc:31 }, getValue());
		throwobj = new haxe.io.Eof();
		Assert.same({ v:7, retn:"eof", acc:51 }, getValue());

		Assert.same({ v:0, retn:"A", acc:110 }, getValue());
		Assert.same({ v:9, retn:"AB", acc:412 }, getValue());
		throwobj = "OtherString";
		Assert.same({ v:10, retn:"String OtherString", acc:413 }, getValue());
		throwobj = "AnotherString";
		var hadExc = false;
		try {
			getValue();
		} catch(e:String) {
			hadExc = true;
			Assert.equals("AnotherString",e);
		}
		Assert.isTrue(hadExc);
		Assert.isFalse(t.hasNext());
	}

	//TODO test private access
	//TODO test type parameter
	//TODO test inline for
	//TODO test that captured vars is kept to a minimum (checking Reflect.fields)
	//TODO test 'this'
	//TODO test conflicting vars
	//TODO test v_captured fail
#end
}
