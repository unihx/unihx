package unihx.utils;

class Yield
{
	macro public static function make(e:haxe.macro.Expr):haxe.macro.Expr
	{
		var c2 = haxe.macro.Context.getLocalClass().get(),
		    pack = c2.pack;
		return unihx.pvt.macros.YieldGenerator.make(pack,e);
	}
}
