package unihx.pvt.editor;
import unihx.pvt.compiler.*;
import unityengine.*;
import unityeditor.*;

@:nativeGen class MenuItems
{
	@:meta(UnityEditor.MenuItem("Window/Unihx/Haxe Build Properties %&h"))
	static function init()
	{
		var window:HaxeBuild = cast EditorWindow.GetWindow( cs.Lib.toNativeType(HaxeBuild), false, "build.hxml", true );
	}

	@:meta(UnityEditor.MenuItem("Window/Unihx/Haxelib Properties"))
	static function lib()
	{
		var window:HaxelibProps = cast EditorWindow.GetWindow( cs.Lib.toNativeType(HaxelibProps), false, "haxelib", true );
	}

	@:meta(UnityEditor.MenuItem("Window/Unihx/Force Recompilation %F5"))
	static function recompile()
	{
		trace("Recompiling Haxe...");
		Globals.chain.compile(true);
		AssetDatabase.Refresh();
	}

	@:meta(UnityEditor.MenuItem("Assets/Create/Haxe Script"))
	static function createScript()
	{
		var path = AssetDatabase.GetAssetPath(Selection.activeObject);
		if (path == '' || path == null)
			path = 'Assets';

		var tex = cast AssetDatabase.LoadAssetAtPath( 'Assets/Editor Default Resources/Unihx/unihx_logo_64.png', cs.Lib.toNativeType(Texture2D));
		ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, (ScriptableObject.CreateInstance() : CreateHaxeEditor), '$path/MyHaxeBehaviour.hx', tex, '');
	}
}


@:nativeGen class HaxeBuild extends EditorWindow
{
	function OnGUI()
	{
		HxInspector.HxmlOnGUI(Globals.chain.hxml);
	}
}

@:nativeGen private class CreateHaxeEditor extends unityeditor.projectwindowcallback.EndNameEditAction
{
	@:overload override public function Action(instanceId:Int, pathName:String, resourceFile:String)
	{
		var name = new haxe.io.Path(pathName).file;
		name = name.charAt(0).toUpperCase() + name.substr(1);
		sys.io.File.saveContent(pathName,
'import unityengine.*;

class $name extends HaxeBehaviour
{
	// Use this for initialization
	function Start()
	{
	}

	// Update is called once per frame
	function Update()
	{
	}
}');

		AssetDatabase.ImportAsset(pathName);
		var o:Object = AssetDatabase.LoadAssetAtPath(pathName, cs.Lib.toNativeType(Object));
		ProjectWindowUtil.ShowCreatedAsset(o);
	}
}
