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
	private function OnEnable()
	{
		Repaint();
	}

	inline private function tgt():Transform
	{
		return cast this.target;
	}

	@:overload override public function OnInspectorGUI()
	{
		switch(Event.current.type)
		{
			case DragUpdated | DragExited:
				var paths = DragAndDrop.paths,
						objs = DragAndDrop.objectReferences,
						found = false;
				for (i in 0...paths.Length)
				{
					var path = paths[i];
					trace(path);
					if (path.endsWith(".hx"))
					{
						found = true;
						// paths[i] = AssetDatabase.GetAssetPath( Component.GetComponent( DragAndDrop.objectReferences[i].name ) );
						paths[i] = path.split(".hx").join(".cs");
						objs[i] = AssetDatabase.LoadMainAssetAtPath( paths[i] );
					}
				}
				trace(found);
				if (found)
				{
					var ev2 = new Event();
					ev2.type = MouseDrag;
					var lastEv = Event.current;
					// var lastType = Event.current.type;
					Event.current = ev2;
					DragAndDrop.PrepareStartDrag();
					DragAndDrop.paths = paths;
					DragAndDrop.objectReferences = objs;
					DragAndDrop.StartDrag("Title");
					DragAndDrop.AcceptDrag();
					Event.current = lastEv;
					// Event.current.Use();
				} else {
					super.OnInspectorGUI();
				}
			// case DragUpdated | DragExited if (AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]).endsWith('.hx')):
			// 	trace("HIEAR");
			// 	trace(DragAndDrop.objectReferences[0]);
			// 	trace(DragAndDrop.paths[0]);
			// 	DragAndDrop.visualMode = Link;
			// 	Event.current.Use();

			// case DragPerform if (AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]).endsWith('.hx')):
			// 	DragAndDrop.visualMode = Link;
			// 	DragAndDrop.AcceptDrag();
			// 	Event.current.Use();
			// 	tgt().gameObject.AddComponent(DragAndDrop.objectReferences[0].name);
			// 	trace("adding ",DragAndDrop.objectReferences[0].name);
			case _:
				super.OnInspectorGUI();
				trace(Event.current.type);
		}
	}
}
