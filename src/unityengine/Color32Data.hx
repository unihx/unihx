package unityengine;

@:struct @:final @:csNative @:native("UnityEngine.Color32") extern class Color32Data extends cs.system.ValueType
{
	var a : cs.types.UInt8;
	var b : cs.types.UInt8;
	var g : cs.types.UInt8;
	var r : cs.types.UInt8;
	@:final @:overload function new(r : cs.types.UInt8, g : cs.types.UInt8, b : cs.types.UInt8, a : cs.types.UInt8) : Void;
	@:final @:overload static function Lerp(a : Color32, b : Color32, t : Single) : Color32;
	@:final @:overload static function op_Implicit(c : Color) : Color32;
	@:final @:overload static function op_Implicit(c : Color32) : Color;
}
