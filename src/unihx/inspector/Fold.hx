package unihx.inspector;

typedef Fold<T> = FoldData;

@:nativeGen @:struct private class FoldData
{
	public var folded:Bool = false;
	public var contents:Dynamic;

	public function new(contents)
	{
		this.contents = contents;
	}
}
