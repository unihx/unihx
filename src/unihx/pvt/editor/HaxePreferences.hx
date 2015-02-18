package unihx.pvt.editor;
import unihx.inspector.*;
import unityengine.*;
import unityeditor.*;
import sys.FileSystem.*;

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

				// handle selected
				var v1 = cur.selected, v2 = lastS[i];
				if (v1 && !v2)
					for (v in val)
						if (v != cur) v.selected = false;

			}

			//check paths' validity
			var name = Sys.systemName() == 'Windows' ? 'haxe.exe' : 'haxe';
			current.haxeCompilers = current.haxeCompilers.filter(function(c)
				return if (c != null && c.path != null && !exists('${c.path}/$name'))
				{
					EditorUtility.DisplayDialog('Haxe Compiler not found','No haxe compiler executable ($name) was found at ${c.path}', 'OK');
					false;
				} else true
			);

			EditorPrefs.SetString("Unihx_Haxe_Compilers", haxe.Serializer.run(current.haxeCompilers));
			EditorPrefs.SetBool("Unihx_Use_Embedded", current.useEmbedded);
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

		if (this.haxeCompilers == null || this.haxeCompilers.length == 0)
		{
			this.haxeCompilers = defaultCompiler();
			EditorPrefs.SetString("Unihx_Haxe_Compilers", haxe.Serializer.run(this.haxeCompilers));
		}
		this.useEmbedded = EditorPrefs.GetBool("Unihx_Use_Embedded",true);

		return this;
	}

	private static function defaultCompiler()
	{
		var ret = [];
		var paths, file;

		if (Sys.systemName() == "Windows")
		{
			paths = Sys.getEnv("PATH").split(';');
			file = 'haxe.exe';
		} else {
			paths = Sys.getEnv("PATH").split(':');
			file = 'haxe';
		}

		var first = true;
		for (p in paths)
		{
			if (exists('$p/$file'))
			{
				ret.push({ path: p, selected: first });
				first = false;
			}
		}

		return ret;
	}
}
