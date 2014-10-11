package unihx._internal;

class Yield
{
	macro public static function getIterator(e:haxe.macro.Expr):haxe.macro.Expr
	{
		return YieldGenerator.getIterator(e);
	}

	// only typing helper
	private static function __yield__<T>(t:T):T
	{
		return t;
	}
}
