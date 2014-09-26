package unihx._internal;
import haxe.macro.Expr;
import haxe.macro.Context.*;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.TypedExprTools;
using Lambda;
using StringTools;

class PrivateAccessMacro
{
#if macro
	public static function build():Type
	{
		trace("AAAAAAAAAAAAAAAAAAAA");
		return switch (Context.getLocalType()) {
			case TInst(_, params):
				var type = params.shift();
				trace(type);
				// var real = Context.getType(type);
				switch (type) {
					case TInst(x,_):
						trace(x);
					case _:
				}
				throw "assert";
				t;
			case _:
				throw "assert";
		}
	}
#end
}
