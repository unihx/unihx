package unityengine;

@:forward abstract Vector2(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(x:Single=.0,y:Single=.0)
	{
		this = new Data(x,y);
	}

	@:extern inline public static function fromData(data:Data):Vector2
	{
		return data;
	}

	@:op(A+B) @:extern inline public static function add(a:Vector2, b:Vector2):Vector2
	{
		return Data.op_Addition(a,b);
	}

	@:op(A/B) @:extern inline public static function div(a:Vector2, b:Single):Vector2
	{
		return Data.op_Division(a,b);
	}

	@:from @:extern inline public static function fromVec2(v:Vector2):Vector2
	{
		return new Vector2(v.x,v.y,0);
	}

	@:to @:extern inline public function toVec3():Vector3
	{
		return new Vector3(this.x,this.y);
	}

	@:to @:extern inline public function toVec4():Vector4
	{
		return new Vector4(this.x,this.y);
	}

	@:op(A*B) @:extern @:commutative inline public static function mul(a:Vector2, b:Single):Vector2
	{
		return Data.op_Multiply(a,b);
	}

	@:op(A-B) @:extern inline public static function sub(a:Vector2, b:Vector2):Vector2
	{
		return Data.op_Subtraction(a,b);
	}

	@:op(-A) @:extern inline public function negate():Vector2
	{
		return Data.op_UnaryNegation(this);
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
		return unihx._internal.StructHelper.with(['x','y'], macro : unityengine.Vector2, ethis, obj);
	}
}

private typedef Data =
#if macro
	Void
#else
	Vector2Data
#end;
