package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;
import haxe.ds.Vector;
import unihx.inspector.*;
using StringTools;
import sys.FileSystem.*;

@:meta(UnityEditor.CustomEditor(typeof(UnityEngine.Object)))
@:nativeGen
@:native('ExamplePreview')
class ExamplePreview extends Editor
{
	private var prop:HxmlProps;
	private var scroll:Vector2;

	static var s_helpBox:GUIStyle;
	static var s_entryWarn:GUIStyle;
	static var s_txtWarn:GUIStyle;

	private function OnEnable()
	{
		Repaint();
	}

	@:overload override public function OnInspectorGUI()
	{
		if (s_helpBox == null)
		{
			s_helpBox = new GUIStyle(untyped 'HelpBox');
			s_helpBox.padding = new RectOffset(10,10,10,10);
			s_entryWarn = untyped 'CN EntryWarn';
			s_txtWarn = new GUIStyle(untyped 'CN StatusWarn');
			s_txtWarn.wordWrap = true;
			s_txtWarn.alignment = MiddleLeft;
			s_txtWarn.stretchWidth = true;
		}

		var path = AssetDatabase.GetAssetPath(target);
		switch (path.split('.').pop())
		{
			case 'hxml' if (path == 'Assets/build.hxml'):
				if (this.prop == null)
				{
					this.prop = HxmlProps.get();
				}
				GUI.enabled = true;
				// scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
				prop.OnGUI();
				// GUILayout.EndScrollView();

				GUILayout.Space(3);
				var buttonLayout = new cs.NativeArray(1);
				buttonLayout[0] = GUILayout.MinHeight(33);
				if (GUILayout.Button("Save",buttonLayout))
				{
					prop.save();
				}
				GUILayout.Space(3);
				if (GUILayout.Button("Reload",buttonLayout))
				{
					prop.reload();
				}
				GUILayout.Space(3);
				if (GUILayout.Button("Force Recompilation",buttonLayout))
				{
					// prop.compile(['--cwd','./Assets','params.hxml','--macro','unihx.pvt.Compiler.compile()']);
					unityeditor.AssetDatabase.Refresh();
				}

				var warns = this.prop.getWarnings();
				if (warns.length > 0)
				{
					GUILayout.Space(15);
					for (w in warns)
					{
						GUILayout.BeginHorizontal(s_helpBox, new cs.NativeArray(0));
						GUILayout.Label('', s_entryWarn, new cs.NativeArray(0));
						GUILayout.Label(w.msg, s_txtWarn, new cs.NativeArray(0));
						GUILayout.EndHorizontal();
					}
				}
				Repaint();

			case 'hx' | 'hxml':
				var last = GUI.enabled;
				GUI.enabled = true;
				scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
				GUI.enabled = false;
				GUILayout.Label(sys.io.File.getContent( AssetDatabase.GetAssetPath(target) ), null);
				GUI.enabled = true;
				GUILayout.EndScrollView();
				GUI.enabled = last;

			case _:
				super.OnInspectorGUI();
		}
	}
}
