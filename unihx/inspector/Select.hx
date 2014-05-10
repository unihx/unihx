package unihx.inspector;

/**
	A generic popup selection field.

	The following options can be used:
**/
//Popup / IntPopup
abstract Select<Key,Value>({ options:Map<Key,Value>, selected:Null<Key> })
{
	@:extern inline public function new(?opts)
	{
		this = { options : opts == null ? new Map() : opts, selected: null };
	}

	@:extern inline public function add(key:Key, value:Value)
	{
		this.options.set(key,value);
	}

	@:extern inline public function options():Map<Key,Value>
	{
		return this.options;
	}

	@:extern inline public function remove(key:Key):Bool
	{
		return this.options.remove(key);
	}

	@:extern inline public function keys()
	{
		return this.options.keys();
	}

	@:to @:extern inline public function selected():Null<Key>
	{
		return this.selected;
	}

	@:from @:extern inline public static function fromMap(map)
	{
		return new Select(map);
	}
}


