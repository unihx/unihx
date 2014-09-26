package unihx._internal;

class YieldBase #if !macro implements cs.system.collections.IEnumerator #end
{
	@:property public var Current(get,never):Dynamic;
	private var eip:Int = 0;
	private var value:Dynamic;

	public function MoveNext():Bool
	{
		return false;
	}

	private function get_Current():Dynamic
	{
		return value;
	}

	public function hasNext():Bool
	{
		return MoveNext();
	}

	public function next():Dynamic
	{
		return value;
	}
}
