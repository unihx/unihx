package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;

@:nativeGen @:native("HaxeBuild") class HaxeBuild extends EditorWindow
{
	@:meta(UnityEditor.MenuItem("Window/Haxe Build Properties"))
	static function init()
	{
		var window:HaxeBuild = ScriptableObject.CreateInstance();
		window.Show();
	}

	function OnGUI()
	{
		HxInspector.HxmlOnGUI(Globals.chain.hxml);
	}
}
