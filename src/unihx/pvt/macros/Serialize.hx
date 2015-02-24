package unihx.pvt.macros;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context.*;
import sys.FileSystem.*;

using haxe.macro.Tools;
using StringTools;
using Lambda;

class Serialize
{
	public static function build()
	{
		return addSerIfNeeded(getBuildFields(), getLocalClass(),true);
	}

	/**
		Adds serialization in case any Haxe class is used.
		The `force` flag will force it to add - even if it is not needed
	 **/
	public static function addSerIfNeeded(fields:Array<Field>, cl:Ref<ClassType>, force=false):Null<Array<Field>>
	{
		// check if any of the fields' types need serialization
		var typedFields = [];
		for (f in fields)
		{
			if (f.meta.exists(function(m) return m.name == ":skip" || m.name == ":skipSerialization"))
				continue;

			var isVar = f.meta == null ? false : f.meta.exists(function(v) return v.name == ':isVar');
			switch [ f.kind, isVar ] {
				case [ FVar(e,t), _ ],
				     [ FProp(e,t,'default' | 'null',_), _ ],
					   [ FProp(e,t,_,'default' | 'null'), _ ],
					   [ FProp(e,t,_,_), true ]:
					var expr = if (e == null) macro @:pos(f.pos) cast null else e;
					var type = if (t == null) typeof(e); else typeof(macro @:pos(f.pos) ( $expr : $t ));
					if (needsSerialization(type,f.pos))
					{
						typedFields.push({ field:f.name, type:type });
						if (f.meta == null)
							f.meta = [];
						f.meta.push({ name:':meta', params: [macro System.NonSerialized], pos:f.pos });
					}
				case _:
			}
		}
		// check if the super types either need serialization or already implemented the ISerializationCallbackReceiver interface

		// if we don't need any special serialization, just return the objects
		// otherwise create OnBeforeSerialize / OnAfterSerialize
	}

	private static function needsSerialization(type:Type, pos:Position)
	{
		return switch(follow(type))
		{
			case TDynamic(_) | TMono(_):
				true; //all dynamics need to be serialized
			case TEnum(_) | TAnonymous(_):
				true;
			case TFun(_,_):
				warning('A function can never be serialized. Please add `@:skip` or `@:skipSerialization` to eliminate this warning', pos);
				false;
			case TAbstract(a,tl) if (a.get().meta.exists(function(m) return m.name == ':coreType')):
				// all core types can be handled correctly by the unity serializer
				false;
			case TAbstract(a,tl):
				var a = a.get();
				needsSerialization(type.applyTypeParameters(a.params, tl), pos);
			case type = TInst( cl, p ):
				var cl = cl.get();
				switch (cl.pack)
				{
					case ['unityengine' | 'unityeditor']:
						false;
					case ['cs'] if (cl.name == 'NativeArray'):
						false;
					case _:
						var obj = getType('unityengine.Object');
						!type.unify(obj);
				}
			case _:
				throw 'assert';
		}
	}
}
