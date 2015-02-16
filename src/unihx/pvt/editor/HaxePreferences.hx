package unihx.pvt.editor;
import unihx.inspector.*;
import unityengine.*;
import unityeditor.*;

class HaxePreferences implements InspectorBuild
{
	private static var current = new HaxePreferences().reload();

	@:meta(UnityEditor.PreferenceItem("Haxe Preferences"))
	public static function PreferencesGUI()
	{
		var lastS = [ for (v in current.haxeCompilers) v.selected ];
		var lastP = [ for (v in current.haxeCompilers) v.path ];
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

			//check paths' validity

			EditorPrefs.SetString("Unihx_Haxe_Compilers", haxe.Serializer.run(current.haxeCompilers));
		}
	}

	/**
		Adds and selects the haxe compiler path to be used
	 **/
	public var haxeCompilers:Array<{ path:DirPath, selected:Bool }>;

	/**
		If an embedded Haxe compiler is found in the project, use it instead of the system compiler
		@label Use embedded compiler if found
	 **/
	public var useEmbedded:Bool = true;

	public function new()
	{
	}

	public function reload():HaxePreferences
	{
		if (EditorPrefs.HasKey("Unihx_Haxe_Compilers"))
			this.haxeCompilers = haxe.Unserializer.run(EditorPrefs.GetString("Unihx_Haxe_Compilers"));
		else
			this.haxeCompilers = defaultCompiler();
		this.useEmbedded

		return this;
	}

	private static function defaultCompiler()
	{
		var ret = [];

		var paths = if (Sys.systemName() == "Windows")
				Sys.getEnv("PATH").split(';');
			else
				Sys.getEnv("PATH").split(':');

		for (p in paths)
		{
		}
		return ret;
	}
}
