package unihx.utils;
using Lambda;

class UnitySerializer extends haxe.Serializer {
	var unityObjects:Array<unityengine.Object>;
	public function new() {
		unityObjects = [];
		super();
	}

	public function getObjects():cs.NativeArray<unityengine.Object> {
		return cs.Lib.nativeArray(unityObjects,false);
	}

	public override function serialize(v:Dynamic) {
		if (v != null && Std.is(v, unityengine.Object)) {
			var idx =
				if (unityObjects.has(v)) unityObjects.indexOf(v);
				else { unityObjects.push(v) - 1; }
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
