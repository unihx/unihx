package unihx.inspector;

abstract Layer(Int) from Int to Int
{
	@:extern inline public function toInt():Int
	{
		return this;
	}
}
