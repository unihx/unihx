package unityengine;
import cs.StdTypes;

@:forward abstract Color32(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(r:UInt8,g:UInt8,b:UInt8,a:UInt8=0xff)
	{
		this = new Data(r,g,b,a);
	}

	@:extern inline public static function fromData(data:Data):Color32
	{
		return data;
	}

	@:from @:extern inline public static function fromColor(c:Color):Color32
	{
		return new Color32(Std.int(c.r * 0xff), Std.int(c.g * 0xff), Std.int(c.b * 0xff), Std.int(c.a * 0xff));
	}

	@:to @:extern inline public function toColor():Color
	{
		return new Color(this.r / 0xff, this.g / 0xff, this.b / 0xff, this.a / 0xff);
	}
#end

	macro public function with(ethis:haxe.macro.Expr, obj:haxe.macro.Expr):haxe.macro.Expr
	{
		return unihx.compiler.StructHelper.with(['r','g','b','a'], macro : unityengine.Color32, ethis, obj);
	}
}

private typedef Data =
#if macro
	Void
#else
	Color32Data
#end;


