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
		var cl2 = cl.get();
		if (cl2.isExtern)
		{
			if (force)
				return fields.concat((macro class {
					public function OnAfterDeserialize() {}
					public function OnBeforeSerialize() {}
				}).fields);
			else
				return null;
		}

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
						typedFields.push(f.name);
						if (f.meta == null)
							f.meta = [];
						f.meta.push({ name:':meta', params: [macro System.NonSerialized], pos:f.pos });
					}
				case _:
			}
		}
		// check if the super types either need serialization or already implemented the ISerializationCallbackReceiver interface
		var sup = cl2.superClass;
		if (sup != null)
		{
			if (!TInst(sup.t,sup.params).unify(getType('unityengine.ISerializationCallbackReceiver')))
			{
				while (sup != null)
				{
					var c = sup.t.get();
					if (c.isExtern && !c.meta.has(':hxGen'))
						break;

					for (field in c.fields.get())
					{
						var isVar = field.meta.has(':isVar');
						switch [ field.kind, isVar ]
						{
							case [ FVar(AccNormal | AccNo,_), _ ],
							     [ FVar(_, AccNormal | AccNo), _ ],
							     [ FVar(_,_), true ] if (needsSerialization(field.type, field.pos)):
								typedFields.push(field.name);
								field.meta.add(':meta', [ macro System.NonSerialized ], field.pos );
							case _:
						}
					}
				}
			}
		}

		// if we don't need any special serialization, just return the objects
		if (typedFields.length == 0)
		{
			if (force)
				return fields.concat((macro class {
					public function OnAfterDeserialize() {}
					public function OnBeforeSerialize() {}
				}).fields);
			else
				return null;
		}

		var pos = currentPos();
		// otherwise create OnBeforeSerialize / OnAfterSerialize
		var decl = { expr:EObjectDecl([ for(field in typedFields) { field: field, expr: macro this.$field } ]), pos: pos };
		var block = [ for (field in typedFields) macri this.$field = obj.$field ];

		var serFields = macro class {
			var __hx_serialize_string:String;
			var __hx_serialize_objects:cs.NativeArray<unityengine.Object>;

			public function OnBeforeSerialize()
			{
				var o = $decl;
				var res = unihx.utils.UnitySerializer.run(o);
				this.__hx_serialize_string = res.toString();
				this.__hx_serialize_objects = res.getObjects();
			}

			public function OnAfterDeserialize()
			{
				if (this.__hx_serialize_string != null)
				{
					var obj = unihx.utils.UnityUnserializer.run(this.__hx_serialize_string, this.__hx_serialize_objects);
					$b{block};
				}
			}
		};

		return fields.concat(serFields.field);
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
