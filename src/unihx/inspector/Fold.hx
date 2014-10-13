package unihx.inspector;

typedef Fold<T> = FoldData<T>;

@:nativeGen @:struct private class FoldData<T>
{
	public var folded:Bool = false;
	public var contents:T;

	public function new(contents)
	{
		this.contents = contents;
	}
}
