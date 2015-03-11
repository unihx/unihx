package unihx.pvt.compiler;
import haxe.macro.Context;
import haxe.macro.Type;
using StringTools;

class Compiler
{
	@:access(haxe.macro.Compiler) public static function excludePacks(exclude:Array<String>)
	{
		trace('here',exclude);
		// var exclude = getData(excludeFile);
		if (Context.defined('editor'))
		{
			// eagerly exclude
			for (e in exclude)
			{
				for (t in Context.getModule(e))
				{
					var b:BaseType = null;
					switch(t)
					{
						case TInst(c,_):
							checkNative(c.get());
							haxe.macro.Compiler.excludeBaseType(c.get());
						case TEnum(e,_):
							haxe.macro.Compiler.excludeBaseType(e.get());
						case _:
					}
				}
			}
		} else {
			var map = [ for (e in exclude) e => true ];
			Context.onGenerate(function(types) {
				for( t in types ) {
					var b : BaseType, name;
					switch( t ) {
					case TInst(c, _):
						checkNative(c.get());
						name = c.toString();
						b = c.get();
					case TEnum(e, _):
						name = e.toString();
						b = e.get();
					default: continue;
					}
					var p = b.pack.join(".");
					if (p == "") p = name; else p = p + "." + name;

					if (map.exists(p))
						haxe.macro.Compiler.excludeBaseType(b);
				}
			});
		}
	}

	private static function checkNative(c:ClassType)
	{
		if (c.meta.has(':nativeGen') || c.meta.has(':hxGen') || c.meta.has(':nativeChildren'))
			return;
		var sup = c.superClass;
		while (sup != null)
		{
			var s = sup.t.get();
			if (s.meta.has(':nativeChildren'))
			{
				trace('here');
				c.meta.add(':nativeGen',[],c.pos);
				return;
			}
			sup = s.superClass;
		}
	}

	private static function getData(file:String)
	{
		return sys.io.File.getContent(file).trim().split('\n');
	}
}
