package unihx.core;

using Lambda;

class UnitySerializer extends haxe.Serializer {
	var unityObjects:Array<unityengine.Object>;
	public function new() {
		unityObjects = [];
		super();
	}

	public override function serializeFields(v) {
		var flds = Reflect.fields(v);
		if (flds.length == 0) flds = Type.getInstanceFields(Type.getClass(v));

		//FIXME: This is serializing functions as well.
		for (f in flds) {
			serializeString(f);

			var val:Dynamic = Reflect.field(v, f);

			serialize(val);
		}
		buf.add("g");
	}

	public override function serialize(v:Dynamic) {
		if (Std.is(v, unityengine.Object)) {
			var idx =
				if (unityObjects.has(v)) unityObjects.indexOf(v);
				else { unityObjects.push(v); unityObjects.length -1; }
			buf.add("U");
			buf.add(idx);
		} else if (Std.is(v, Single)) {
			serialize((v:Float));
		} else {
			try super.serialize(v)
					catch(e:Dynamic) {}
		}
	}

	public static function run(v:Dynamic) {
		var s = new UnitySerializer();
		s.serialize(v);
		return { str : s.toString()
			   , objs: cs.Lib.nativeArray(s.unityObjects, true)
			   }
	}
}