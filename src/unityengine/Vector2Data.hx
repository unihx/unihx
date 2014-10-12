package unityengine;

@:struct @:final @:csNative @:native("UnityEngine.Vector2") extern class Vector2Data extends cs.system.ValueType
{
	var magnitude(get,never) : Single;
	var normalized(get,never) : Vector2;
	var sqrMagnitude(get,never) : Single;
	var x : Single;
	var y : Single;
	@:final @:overload function new(x : Single, y : Single) : Void;
	@:final @:overload function Normalize() : Void;
	@:final @:overload function Scale(scale : Vector2) : Void;
	@:final @:overload function Set(new_x : Single, new_y : Single) : Void;
	@:final @:overload function SqrMagnitude() : Single;
	@:final @:overload function get_Item(index : Int) : Single;
	@:final @:overload private function get_magnitude() : Single;
	@:final @:overload private function get_normalized() : Vector2;
	@:final @:overload private function get_sqrMagnitude() : Single;
	@:final @:overload function set_Item(index : Int, value : Single) : Void;
	static var kEpsilon(default,never) : Single;
	static var one(get,never) : Vector2;
	static var right(get,never) : Vector2;
	static var up(get,never) : Vector2;
	static var zero(get,never) : Vector2;
	@:final @:overload static function Angle(from : Vector2, to : Vector2) : Single;
	@:final @:overload static function ClampMagnitude(vector : Vector2, maxLength : Single) : Vector2;
	@:final @:overload static function Distance(a : Vector2, b : Vector2) : Single;
	@:final @:overload static function Dot(lhs : Vector2, rhs : Vector2) : Single;
	@:final @:overload static function Lerp(from : Vector2, to : Vector2, t : Single) : Vector2;
	@:final @:overload static function Max(lhs : Vector2, rhs : Vector2) : Vector2;
	@:final @:overload static function Min(lhs : Vector2, rhs : Vector2) : Vector2;
	@:final @:overload static function MoveTowards(current : Vector2, target : Vector2, maxDistanceDelta : Single) : Vector2;
	@:native("Scale") @:final @:overload static function _Scale(a : Vector2, b : Vector2) : Vector2;
	@:native("SqrMagnitude") @:final @:overload static function _SqrMagnitude(a : Vector2) : Single;
	@:final @:overload static private function get_one() : Vector2;
	@:final @:overload static private function get_right() : Vector2;
	@:final @:overload static private function get_up() : Vector2;
	@:final @:overload static private function get_zero() : Vector2;
	@:final @:overload static function op_Addition(a : Vector2, b : Vector2) : Vector2;
	@:final @:overload static function op_Division(a : Vector2, d : Single) : Vector2;
	@:final @:overload static function op_Equality(lhs : Vector2, rhs : Vector2) : Bool;
	@:final @:overload static function op_Implicit(v : Vector3) : Vector2;
	@:final @:overload static function op_Implicit(v : Vector2) : Vector3;
	@:final @:overload static function op_Inequality(lhs : Vector2, rhs : Vector2) : Bool;
	@:final @:overload static function op_Multiply(a : Vector2, d : Single) : Vector2;
	@:final @:overload static function op_Multiply(d : Single, a : Vector2) : Vector2;
	@:final @:overload static function op_Subtraction(a : Vector2, b : Vector2) : Vector2;
	@:final @:overload static function op_UnaryNegation(a : Vector2) : Vector2;
}
