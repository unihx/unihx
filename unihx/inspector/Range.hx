package unihx.inspector;

//@upper @lower / @min @max
//MinMax
/**
	A special slider the user can use to specify a range between a min and a max.
	Options:
		- upper / maxLimit : maximum limit
		- lower / minLimit : minimum limit
		- min / minValue : selected minimum value
		- max / maxValue : selected maximum value
**/
abstract Range(Vector4)
{
	public var minLimit(get,set):Single;
	public var maxLimit(get,set):Single;
	public var minValue(get,set):Single;
	public var maxValue(get,set):Single;

	@:extern inline public function new(minLimit,maxLimit, ?minValue,?maxValue)
	{
		this = new Vector4(minLimit, maxLimit, minValue == null ? minLimit : minValue, maxValue == null ? maxLimit : maxValue);
	}


	@:extern inline private function get_minLimit():Single
	{
		return this.x;
	}
	@:extern inline private function set_minLimit(v:Single):Single
	{
		return this.x = v;
	}
	@:extern inline private function get_maxLimit():Single
	{
		return this.y;
	}
	@:extern inline private function set_maxLimit(v:Single):Single
	{
		return this.y = v;
	}
	@:extern inline private function get_minValue():Single
	{
		return this.z;
	}
	@:extern inline private function set_minValue(v:Single):Single
	{
		return this.z = v;
	}
	@:extern inline private function get_maxValue():Single
	{
		return this.w;
	}
	@:extern inline private function set_maxValue(v:Single):Single
	{
		return this.w = v;
	}
}
