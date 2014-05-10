package unihx.inspector;
import cs.NativeArray;

/**
	A generic popup selection field.
**/
@:struct @:nativeGen class Select<T>
{
	public var options:NativeArray<String>;
	public var values:NativeArray<T>;
	public var selectedIndex:Int;

	public var selected(get,never):Null<T>;

	public function new(options:Array<String>,values:Array<T>,selected=-1)
	{
		this.options = cs.Lib.nativeArray(options,true);
		this.values = cs.Lib.nativeArray(values,true);
		this.selectedIndex = selected;
	}

	public static function fromOptions(options:Array<String>,selected=-1):Select<String>
	{
		return new Select(options,options,selected);
	}

	public static function fromMap<T>(map:Map<String,T>,?selected:String)
	{
		var arr = [ for (key in map.keys()) key ],
				vals = [ for (k in arr) map[k] ];
		var sel = if (selected == null)
			-1;
		else
			arr.indexOf(selected);
		return new Select(arr,vals,sel);
	}

	private function get_selected():Null<T>
	{
		return selectedIndex < 0 ? null : values[selectedIndex];
	}
}
