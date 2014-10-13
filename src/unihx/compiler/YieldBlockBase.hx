package unihx.compiler;

class YieldBlockBase
	#if cs implements cs.system.collections.IEnumerator #end
{
	@:property public var Current(get,never):Dynamic;
	private var eip:Int = 0;
	private var value:Dynamic;
	private var exc:Dynamic;

	public function MoveNext():Bool
	{
		return false;
	}

	inline public function get_Current():Dynamic
	{
		return value;
	}

	inline public function hasNext():Bool
	{
		return MoveNext();
	}

	inline public function next():Dynamic
	{
		return value;
	}

	/**
		This function will be called internally by the handler to see if an exception
		can be handled. It will work like a MoveNext() call.

		If the handler returns false, the enumerator will be in a 'errored' state and will not return any more values
	**/
	public function handleError(exc:Dynamic):Bool
	{
		this.eip = -1; //error state
		return false;
	}

	public function Reset():Void
	{
		this.eip = 0;
	}
}
