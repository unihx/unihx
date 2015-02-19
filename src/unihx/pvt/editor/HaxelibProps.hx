package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;

@:nativeGen class HaxelibProps extends EditorWindow
{
	var libs:Array<{ lib:String, ver:String }>;
	var installDialog = false;
	var runDialog = false;
	var lib:String;
	var cmd:String;
	var cmdShow:String;
	var scroll:Vector2;

	var installing = false;

	static var s_libs:GUIStyle;
	static var s_box:GUIStyle;

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

			s_box = new GUIStyle(untyped 'HelpBox');
			s_box.margin = new RectOffset(0,0,0,0);
			s_box.padding = new RectOffset(0,0,0,0);
			// s_libs.margin.top = 0;
			// trace(s_libs.margin);
		}

		scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
		GUILayout.Space(6);
		GUILayout.Label('Installed libraries:', new cs.NativeArray(0));
		EditorGUI.indentLevel++;
		GUILayout.BeginVertical(s_libs, new cs.NativeArray(0));
		if (libs != null) for (lib in libs)
		{
			EditorGUILayout.LabelField(lib.lib, lib.ver, new cs.NativeArray(0));
		}
		GUILayout.EndVertical();
		EditorGUI.indentLevel--;

		GUILayout.Space(3);
		var buttonLayout = new cs.NativeArray(1);
		buttonLayout[0] = GUILayout.MinHeight(33);

		var s_btn:GUIStyle = untyped "Button";

		GUILayout.BeginVertical(s_box, new cs.NativeArray(0));
		if (installDialog = GUILayout.Toggle(installDialog,"Install...",s_btn,buttonLayout))
		{
			EditorGUI.indentLevel++;
			lib = EditorGUILayout.TextField('Name',lib,new cs.NativeArray(0));
			var rect = GUILayoutUtility.GetRect(new GUIContent('OK'), s_btn);
			rect = rect.with({ x: rect.x + rect.width - 35, width: 35 });
			if (GUI.Button(rect, 'OK'))
			{

				EditorUtility.DisplayProgressBar('Installing $lib...','Installing $lib',0);
				if (Globals.chain.haxelib.runOrWarn(['install',lib]))
				{
					installDialog = false;
					lib = '';
					reload();
				}
				EditorUtility.ClearProgressBar();
			}
			EditorGUI.indentLevel--;
			GUILayout.Space(6);
		}
		GUILayout.EndVertical();

		GUILayout.Space(3);
		GUILayout.BeginVertical(s_box, new cs.NativeArray(0));
		if (runDialog = GUILayout.Toggle(runDialog,"Run Command...",s_btn,buttonLayout))
		{
			EditorGUI.indentLevel++;
			GUI.enabled = false;
			EditorGUILayout.TextArea(cmdShow, s_box, new cs.NativeArray(0));
			GUI.enabled = true;
			cmd = EditorGUILayout.TextField('haxelib',cmd,new cs.NativeArray(0));
			var rect = GUILayoutUtility.GetRect(new GUIContent('OK'), s_btn);
			rect = rect.with({ x: rect.x + rect.width - 35, width: 35 });
			if (GUI.Button(rect, 'OK'))
			{
				var c = Globals.chain.haxelib.run(cmd.split(' '));
				if (c.exit == 0)
				{
					cmd = '';
					cmdShow = c.err + "\n" + c.out;
				} else {
					cmdShow = "Command failed:\n" + c.err + "\n" + c.out;
				}
				EditorUtility.ClearProgressBar();
				reload();
			}
			if (GUI.Button(rect.with({ x: rect.x - 47, width: 45 }), 'Reset'))
			{
				cmdShow = '';
			}
			EditorGUI.indentLevel--;
			GUILayout.Space(6);

		} else {
			cmdShow = '';
		}

		GUILayout.EndVertical();

		// GUILayout.Space(3);
		// if (GUILayout.Button("Upgrade",buttonLayout))
		// {
		// 	Globals.chain.haxelib.runOrWarn(['upgrade']);
		// 	reload();
		// }

		GUILayout.Space(3);
		if (GUILayout.Button("Refresh",buttonLayout))
		{
			reload();
		}

		GUILayout.EndScrollView();
	}
}
