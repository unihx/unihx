package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;

@:nativeGen class MenuItems
{
	@:meta(UnityEditor.MenuItem("Window/Unihx/Haxe Build Properties %&h"))
	static function init()
	{
		var window:HaxeBuild = cast EditorWindow.GetWindow( cs.Lib.toNativeType(HaxeBuild), false, "build.hxml", true );
	}

	@:meta(UnityEditor.MenuItem("Window/Unihx/Force Recompilation %F5"))
	static function recompile()
	{
		trace("Recompiling Haxe...");
		Globals.chain.compile(true);
		AssetDatabase.Refresh();
	}
}


@:nativeGen class HaxeBuild extends EditorWindow
{
	function OnGUI()
	{
		HxInspector.HxmlOnGUI(Globals.chain.hxml);
	}
}
