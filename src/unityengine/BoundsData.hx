package unityengine;

@:struct @:final @:csNative @:native("UnityEngine.Bounds") extern class BoundsData extends cs.system.ValueType
{
	var center(get,set) : Vector3;
	var extents(get,set) : Vector3;
	var max(get,set) : Vector3;
	var min(get,set) : Vector3;
	var size(get,set) : Vector3;
	@:final @:overload function new(center : Vector3, size : Vector3) : Void;
	@:final @:overload function Contains(point : Vector3) : Bool;
	@:final @:overload function Encapsulate(point : Vector3) : Void;
	@:final @:overload function Encapsulate(bounds : Bounds) : Void;
	@:final @:overload function Expand(amount : Single) : Void;
	@:final @:overload function Expand(amount : Vector3) : Void;
	@:final @:overload function IntersectRay(ray : Ray) : Bool;
	@:final @:overload function IntersectRay(ray : Ray, distance : cs.Ref<Single>) : Bool;
	@:final @:overload function Intersects(bounds : Bounds) : Bool;
	@:final @:overload function SetMinMax(min : Vector3, max : Vector3) : Void;
	@:final @:overload function SqrDistance(point : Vector3) : Single;
	@:final @:overload private function get_center() : Vector3;
	@:final @:overload private function get_extents() : Vector3;
	@:final @:overload private function get_max() : Vector3;
	@:final @:overload private function get_min() : Vector3;
	@:final @:overload private function get_size() : Vector3;
	@:final @:overload private function set_center(value : Vector3) : Vector3;
	@:final @:overload private function set_extents(value : Vector3) : Vector3;
	@:final @:overload private function set_max(value : Vector3) : Vector3;
	@:final @:overload private function set_min(value : Vector3) : Vector3;
	@:final @:overload private function set_size(value : Vector3) : Vector3;
	@:final @:overload static function op_Equality(lhs : Bounds, rhs : Bounds) : Bool;
	@:final @:overload static function op_Inequality(lhs : Bounds, rhs : Bounds) : Bool;
}
