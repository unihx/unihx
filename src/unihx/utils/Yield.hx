package unihx.utils;

class Yield
{
	macro public static function block(e:haxe.macro.Expr):haxe.macro.Expr
	{
		var ret = YieldGenerator.getIterator(e);
		return macro ( $ret : unihx.utils.YieldBlockBase );
	}

	// only typing helper
	private static function __yield__<T>(t:T):T
	{
		return t;
	}
}
