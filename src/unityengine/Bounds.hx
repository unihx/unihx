package unityengine;

private typedef Data =
#if macro
	Void
#else
	BoundsData
#end;

@:forward abstract Bounds(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(center:Vector3,size:Vector3)
	{
		this = new BoundsData(center,size);
	}
	@:extern inline public static function fromData(data:BoundsData):Bounds
	{
		return data;
	}
#end

	macro public function with(ethis:haxe.macro.Expr, obj:haxe.macro.Expr):haxe.macro.Expr
	{
		return unihx.internal.StructHelper.with(['center','size'], macro : unityengine.Bounds, ethis, obj);
	}
}
