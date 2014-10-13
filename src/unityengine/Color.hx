package unityengine;

@:forward abstract Color(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(r:Single,g:Single,b:Single,a:Single=1.0)
	{
		this = new Data(r,g,b,a);
	}

	@:extern inline public static function fromData(data:Data):Color
	{
		return data;
	}

	@:op(A+B) @:extern inline public static function add(a:Color, b:Color):Color
	{
		return Data.op_Addition(a,b);
	}

	@:op(A/B) @:extern inline public static function div(a:Color, b:Single):Color
	{
		return Data.op_Division(a,b);
	}

	@:from @:extern inline public static function fromVec4(vec:Vector4):Color
	{
		return new Color(vec.x, vec.y, vec.z, vec.w);
	}

	@:to @:extern inline public function toVec4():Vector4
	{
		return new Vector4(this.r, this.g, this.b, this.a);
	}

	@:op(A*B) @:extern inline public static function mul(a:Color, b:Color):Color
	{
		return Data.op_Multiply(a,b);
	}

	@:op(A*B) @:extern @:commutative inline public static function mulSingle(a:Color, b:Single):Color
	{
		return Data.op_Multiply(a,b);
	}

	@:op(A-B) @:extern inline public static function sub(a:Color, b:Color):Color
	{
		return Data.op_Subtraction(a,b);
	}

	@:arrayAccess @:extern inline public function get_Item(index:Int):Single
	{
		return this.get_Item(index);
	}

	@:arrayAccess @:extern inline public function set_Item(index:Int, val:Single):Single
	{
		this.set_Item(index,val);
		return val;
	}
#end

	macro public function with(ethis:haxe.macro.Expr, obj:haxe.macro.Expr):haxe.macro.Expr
	{
		return unihx.internal.StructHelper.with(['r','g','b','a'], macro : unityengine.Color, ethis, obj);
	}
}

private typedef Data =
#if macro
	Void
#else
	ColorData
#end;

