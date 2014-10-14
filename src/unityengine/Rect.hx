package unityengine;

@:forward abstract Rect(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(left:Single,top:Single,width:Single,height:Single)
	{
		this = new Data(left,top,width,height);
	}

	@:extern inline public static function fromData(data:Data):Rect
	{
		return data;
	}

#end

	macro public function with(ethis:haxe.macro.Expr, obj:haxe.macro.Expr):haxe.macro.Expr
	{
		return unihx.compiler.StructHelper.with(['x','y','width','height'], macro : unityengine.Rect, ethis, obj);
	}
}

private typedef Data =
#if macro
	Void
#else
	RectData
#end;



