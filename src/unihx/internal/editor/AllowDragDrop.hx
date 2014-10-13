package unihx.internal.editor;
import unityengine.*;
import unityeditor.*;
import haxe.ds.Vector;
using StringTools;

@:meta(UnityEditor.CustomEditor(typeof(UnityEngine.Transform)))
@:meta(UnityEditor.CanEditMultipleObjects)
@:nativeGen
@:native('AllowDragDrop')
class AllowDragDrop extends Editor
{
	private var _target(get,never):Transform;

	private function OnEnable()
	{
		Repaint();
	}

	inline private function get__target():Transform
	{
		return cast this.target;
	}

	@:overload override public function OnInspectorGUI()
	{
		var obj = DragAndDrop.objectReferences;
		if (obj == null || obj.Length == 0)
		{
			super.OnInspectorGUI();
			return;
		}
		switch(Event.current.type)
		{
			case DragUpdated | DragExited if (AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]).endsWith('.hx')):
				DragAndDrop.visualMode = Generic;
				Event.current.Use();
			case DragPerform if (AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]).endsWith('.hx')):
				DragAndDrop.visualMode = Generic;
				DragAndDrop.AcceptDrag();
				Event.current.Use();
				var ret = _target.gameObject.AddComponent(DragAndDrop.objectReferences[0].name);
				if (ret == null)
					EditorUtility.DisplayDialog('Can\'t add script','Can\'t add script behaviour "${DragAndDrop.objectReferences[0].name}"',"OK");
			case _:
				super.OnInspectorGUI();
		}
	}
}
