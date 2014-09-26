package unihx._internal;

class Yield
{
	macro public static function getIterator(e:haxe.macro.Expr):haxe.macro.Expr
	{
		return YieldGenerator.getIterator(e);
	}
}
