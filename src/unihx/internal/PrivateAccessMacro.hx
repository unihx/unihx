package unihx.internal;
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
		switch (Context.getLocalType()) {
			case TInst(_, params):
				var module = getConst(params.shift(),1),
						typeName = getConst(params.shift(),2);

				var mod = getModule(module);
				for (m in mod) {
					switch(m) {
						case TInst(c,_):
							if (c.get().name == typeName)
								return TInst(c,params);
						case TEnum(c,_):
							if (c.get().name == typeName)
								return TEnum(c,params);
						case TType(c,_):
							if (c.get().name == typeName)
								return TType(c,params);
						case TAbstract(c,_):
							if (c.get().name == typeName)
								return TAbstract(c,params);
						case _:
					}
				}
				throw new Error('Private type "${typeName}" cannot be found on "$module"',currentPos());
			case _:
				throw "assert";
		}
	}

	private static function getConst(t:Type, n:Int):String
	{
		switch (t) {
			case TInst(x,_):
				var name = x.get().name;
				if (!name.startsWith('S'))
					throw new Error('PrivateTypeAccess must have the parameter number $n as a String', currentPos());
				return name.substr(1);
			case _:
				throw new Error('PrivateTypeAccess must have the parameter number $n as a String', currentPos());
		}
	}
#end
}
