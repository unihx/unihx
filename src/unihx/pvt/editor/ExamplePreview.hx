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

	private function OnEnable()
	{
		Repaint();
	}

	@:overload override public function OnInspectorGUI()
	{
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
