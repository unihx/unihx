package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;

@:nativeGen class HaxelibProps extends EditorWindow
{
	var libs:Array<{ lib:String, ver:String }>;
	static var s_libs:GUIStyle;

	public function new()
	{
		super();
		reload();
	}

	public function reload()
	{
		this.libs = Globals.chain.haxelib.list();
	}

	public function OnGUI()
	{
		if (s_libs == null)
		{
			// s_libs = untyped "CN Box";
			s_libs = new GUIStyle(untyped 'HelpBox');
		}

		GUILayout.Space(6);
		GUILayout.Label('Installed libraries:', new cs.NativeArray(0));
		EditorGUI.indentLevel++;
		GUILayout.BeginVertical(s_libs, new cs.NativeArray(0));
		trace(libs);
		if (libs != null) for (lib in libs)
		{
			EditorGUILayout.LabelField(lib.lib, lib.ver, new cs.NativeArray(0));
		}
		GUILayout.EndVertical();
		EditorGUI.indentLevel--;

		GUILayout.Space(3);
		var buttonLayout = new cs.NativeArray(1);
		buttonLayout[0] = GUILayout.MinHeight(33);
		if (GUILayout.Button("Install...",buttonLayout))
		{
		}

		GUILayout.Space(3);
		if (GUILayout.Button("Upgrade",buttonLayout))
		{
		}

		GUILayout.Space(3);
		if (GUILayout.Button("Run command...",buttonLayout))
		{
		}

		GUILayout.Space(3);
		if (GUILayout.Button("Refresh",buttonLayout))
		{
			reload();
		}
	}
}
