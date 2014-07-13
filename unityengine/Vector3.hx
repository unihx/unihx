package unityengine;

@:forward abstract Vector3(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(x:Single=.0,y:Single=.0,z:Single=.0)
	{
		this = new Data(x,y,z);
	}

	@:extern inline public static function fromData(data:Data):Vector3
	{
		return data;
	}

	@:op(A+B) @:extern inline public static function add(a:Vector3, b:Vector3):Vector3
	{
		return Data.op_Addition(a,b);
	}

	@:op(A/B) @:extern inline public static function div(a:Vector3, b:Single):Vector3
	{
		return Data.op_Division(a,b);
	}

	@:from @:extern inline public static function fromVec2(v:Vector2):Vector3
	{
		return new Vector3(v.x,v.y,0);
	}

	@:to @:extern inline public function toVec2():Vector2
	{
		return new Vector2(this.x,this.y);
	}

	@:op(A*B) @:extern @:commutative inline public static function mul(a:Vector3, b:Single):Vector3
	{
		return Data.op_Multiply(a,b);
	}

	@:op(A-B) @:extern inline public static function sub(a:Vector3, b:Vector3):Vector3
	{
		return Data.op_Subtraction(a,b);
	}

	@:op(-A) @:extern inline public function negate():Vector3
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
		return unihx._internal.StructHelper.with(['x','y','z'], macro : unityengine.Vector3, ethis, obj);
	}
}

private typedef Data =
#if macro
	Void
#else
	Vector3Data
#end;
