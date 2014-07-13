package unityengine;

@:forward abstract Matrix4x4(Data) from Data to Data
{
#if !macro
	@:extern inline public static function fromData(data:Data):Matrix4x4
	{
		return data;
	}

	@:op(A*B) @:extern inline public static function mul(a:Matrix4x4, b:Matrix4x4):Matrix4x4
	{
		return Data.op_Multiply(a,b);
	}

	@:op(A*B) @:extern @:commutative inline public static function mulVector(a:Matrix4x4, b:Vector4):Vector4
	{
		return Data.op_Multiply(a,b);
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
}

private typedef Data =
#if macro
	Void
#else
	Matrix4x4Data
#end;

