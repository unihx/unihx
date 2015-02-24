package unityengine;

@:forward abstract Quaternion(Data) from Data to Data
{
#if !macro
	@:extern inline public function new(x:Single,y:Single,z:Single,w:Single)
	{
		this = new Data(x,y,z,w);
	}

	@:extern inline public static function fromData(data:Data):Quaternion
	{
		return data;
	}

	@:op(A*B) @:extern inline public static function mul(a:Quaternion, b:Quaternion):Quaternion
	{
		return Data.op_Multiply(a,b);
	}

	@:op(A*B) @:extern inline public function rotate(point:Vector3):Vector3
	{
		return Data.op_Multiply(this,point);
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
		return unihx.pvt.macros.StructHelper.with(['x','y','z','w'], macro : unityengine.Quaternion, ethis, obj);
	}
}

private typedef Data =
#if macro
	Void
#else
	QuaternionData
#end;

