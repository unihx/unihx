package unihx.inspector;

//@upper @lower / @min @max
//MinMax
/**
	A special slider the user can use to specify a range between a min and a max.
**/
@:struct class Range
{
	public var minLimit:Single;
	public var maxLimit:Single;
	public var minValue:Single;
	public var maxValue:Single;

	public function new(minLimit,maxLimit, ?minValue,?maxValue)
	{
		this.minLimit = minLimit;
		this.maxLimit = maxLimit;
		this.minValue = minValue == null ? minLimit : minValue;
		this.maxValue == null ? maxLimit : maxValue;
	}
}
