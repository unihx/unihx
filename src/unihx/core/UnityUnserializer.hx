package unihx.core;

class UnityUnserializer extends haxe.Unserializer {
	var unityObjects:Array<unityengine.Object>;
	public function new(str:String, unityObjects:cs.NativeArray<unityengine.Object>) {
		this.unityObjects = cs.Lib.array(unityObjects);
		super(str);
	}

	public override function unserializeObject(o) {
		while( true ) {
			if( pos >= length )
				throw "Invalid object";
			if( get(pos) == "g".code )
				break;
			var k = unserialize();
			if( !Std.is(k,String) )
				throw "Invalid object key";
			try {
				var v = unserialize();
				Reflect.setField(o,k,v);
			} catch(e:Dynamic) {
				//FIXME: Debug this
			}
		}
		pos++;
	}

	public override function unserialize() : Dynamic {
		return switch(get(pos)) {
		case "U".code:
			pos++;
			var idx = readDigits();
			unityObjects[idx];
		case _:
			super.unserialize();
		}
	}

	public static function run(str:String, objs:cs.NativeArray<unityengine.Object>) {
		return new UnityUnserializer(str, objs).unserialize();
	}

}