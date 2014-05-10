package unihx._internal.editor;
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
		switch(Event.current.type)
		{
			case DragUpdated | DragExited if (AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]).endsWith('.hx')):
				DragAndDrop.visualMode = Link;
				Event.current.Use();
			case DragPerform if (AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]).endsWith('.hx')):
				DragAndDrop.visualMode = Link;
				DragAndDrop.AcceptDrag();
				Event.current.Use();
				_target.gameObject.AddComponent(DragAndDrop.objectReferences[0].name);
			case _:
				super.OnInspectorGUI();
		}
	}
}
