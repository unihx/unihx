package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;

@:nativeGen class HaxeBuild extends EditorWindow
{
	@:meta(UnityEditor.MenuItem("Window/Haxe Build Properties %&h"))
	static function init()
	{
		var window:HaxeBuild = cast EditorWindow.GetWindow( cs.Lib.toNativeType(HaxeBuild), false, "build.hxml", true );
	}

	function OnGUI()
	{
		HxInspector.HxmlOnGUI(Globals.chain.hxml);
	}
}
