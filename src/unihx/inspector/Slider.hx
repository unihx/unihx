package unihx.inspector;

/**
	A special slider the user can use to specify a value between a min and a max.
**/
@:nativeGen @:struct class Slider<T>
{
	public var minLimit:T;
	public var maxLimit:T;
	public var value:T;

	public function new(min,max,?value)
	{
		this.minLimit = min;
		this.maxLimit = max;
		this.value = value == null ? minLimit : value;
	}
}
