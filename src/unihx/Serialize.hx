package unihx;

#if !macro
@:autoBuild(unihx.Serialize.SerializeMacro.build())
interface Serialize extends unityengine.ISerializationCallbackReceiver {

}
#end

#if macro 

import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Context;

class SerializeMacro {
	macro public function build():Array<Field> {
		var fields = Context.getBuildFields();

		var fieldsToSerialize = [];

		for (field in fields) {
			switch(field.kind) {
			case FVar(_, _)
				| FProp("default", "null", _, _):
				fieldsToSerialize.push(field.name);
				field.meta.push({pos: field.pos, params: [macro System.NonSerialized], name: ":meta"});
			case _:
			}

		}

		var setExprs = fieldsToSerialize.map(function(fld) return macro o.$fld = $i{fld});

		//Todo: Add checking for deserialization incompatibilities.
		var getExprs = fieldsToSerialize.map(function(fld) return macro $i{fld} = o.$fld);


		var serFields = macro class {

                                            var __hx_serialize_string:String;
                                            var __hx_serialize_objects:cs.NativeArray<unityengine.Object>;
			public function OnBeforeSerialize() {
                            trace("Serializing on: " + cs.system.threading.Thread.CurrentThread.ManagedThreadId);
				var o:Dynamic = {};
				$b{setExprs};
				var res = unihx.core.UnitySerializer.run(o);
				__hx_serialize_string = res.str;
				__hx_serialize_objects = res.objs;
			}
			public function OnAfterDeserialize() {
				trace("Deserializing on: " + cs.system.threading.Thread.CurrentThread.ManagedThreadId);
				if (__hx_serialize_string != null) {
					var o:Dynamic = unihx.core.UnityUnserializer.run(__hx_serialize_string, __hx_serialize_objects);
					$b{getExprs};
				}
			}
		}

		return fields.concat(serFields.fields);
	}
}
#end