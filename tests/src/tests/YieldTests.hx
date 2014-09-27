package tests;
import utest.Assert;
import unihx._internal.YieldBase;

using Lambda;

class YieldTests
{
	public function new()
	{
	}

	macro private static function test(expr:haxe.macro.Expr):haxe.macro.Expr
	{
		return unihx._internal.YieldGenerator.make('tests.unihx',expr);
	}

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
		var fib:Iterator<Dynamic> = test({
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
		var fact:Iterator<Dynamic> = test({
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

	//TODO test private access
	//TODO test type parameter
	//TODO test

}
