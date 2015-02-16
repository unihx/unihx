package unihx.pvt.editor;
import unihx.inspector.*;
import unityengine.*;
import unityeditor.*;

class HaxePreferences implements InspectorBuild
{
	private static var current = new HaxePreferences().reload();
	private static var last:Array<Bool>;

	@:meta(UnityEditor.PreferenceItem("Haxe Preferences"))
	public static function PreferencesGUI()
	{
		if (last == null) last = [ for (v in current.haxeCompilers) v.selected ];
		current.OnGUI();

		if (GUI.changed)
		{
			var val = current.haxeCompilers;
			for (i in 0...val.length)
			{
				var cur = val[i];
				if (cur == null) break;

				var v1 = cur.selected, v2 = last[i];
				if (v1 && !v2)
					for (v in val)
						if (v != cur) v.selected = false;
			}

			last = [ for (v in current.haxeCompilers) v.selected ];
		}
	}

	/**
		Selects what kind of data
	 **/
	public var haxeCompilers:Array<{ path:DirPath, selected:Bool }>;

	public function new()
	{
	}

	public function reload():HaxePreferences
	{
		return this;
	}
}
