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
		return unihx._internal.YieldGenerator.make(expr);
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
}
