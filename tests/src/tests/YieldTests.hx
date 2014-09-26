package tests;
import utest.Assert;
import unihx._internal.YieldBase;

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
}
