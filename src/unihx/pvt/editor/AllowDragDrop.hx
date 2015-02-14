package unihx.pvt.editor;
import unihx.pvt.compiler.*;
import unityengine.*;
import unityeditor.*;
import haxe.ds.Vector;
using StringTools;

@:meta(UnityEditor.CustomEditor(typeof(UnityEngine.Transform)))
@:meta(UnityEditor.CanEditMultipleObjects)
@:meta(UnityEditor.InitializeOnLoad)
@:nativeGen
@:native('AllowDragDrop')
class AllowDragDrop extends Editor
{
	private var _target(get,never):Transform;

	static function __init__()
	{
		unityeditor.EditorApplication.hierarchyWindowItemOnGUI += function(instanceId:Int, r:Rect) {
			var obj = DragAndDrop.objectReferences;
			if (obj == null || obj.Length == 0 || !r.Contains(Event.current.mousePosition))
			{
				return;
			}

			var _target = EditorUtility.InstanceIDToObject(instanceId);
			if (!Std.is(_target,GameObject))
			{
				return;
			}

			var path = AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]);
			if (path.endsWith('.hx'))
			{
				var last = GUI.color;
				GUI.color = new Color(164 / 255, 211 / 255, 237 / 255, 0.5);
				GUI.Box(r,"");

				handleDragDrop(cast _target);
			}
		};
	}

	private function OnEnable()
	{
		Repaint();
	}

	inline private function get__target():Transform
	{
		return cast this.target;
	}

	public static function handleDragDrop(target:GameObject):Bool
	{
		if (DragAndDrop.objectReferences.Length > 0)
		{
			var path = AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]);
			if (path.endsWith('.hx'))
			{
				switch(Event.current.type)
				{
					case DragUpdated | DragExited | DragPerform:
					case _:
						return false;
				}

				var module = HaxeServices.getModule(path);
				var as = haxe.ds.Vector.fromData(cs.system.AppDomain.CurrentDomain.GetAssemblies());
				for (assembly in as)
				{
					var t = assembly.GetType(module);
					if (t != null)
					{
						var sup = t,
						    isComponent = false;
						while (sup != null)
						{
							if (sup.ToString() == "UnityEngine.Component")
							{
								isComponent = true;
								break;
							}
							sup = sup.BaseType;
						}
						if (isComponent)
						{
							switch(Event.current.type)
							{
								case DragUpdated | DragExited:
									DragAndDrop.visualMode = Generic;
									Event.current.Use();
								case DragPerform:
									DragAndDrop.visualMode = Generic;
									DragAndDrop.AcceptDrag();
									Event.current.Use();
									var ret = target.AddComponent(DragAndDrop.objectReferences[0].name);
									if (ret == null)
										EditorUtility.DisplayDialog('Can\'t add script','Can\'t add script behaviour "${DragAndDrop.objectReferences[0].name}"',"OK");
								case _:
									throw 'assert';
							}
							return true;
						} else {
							if (Event.current.type == DragExited)
								EditorUtility.DisplayDialog('Cannot add script', 'Cannot add script $module: It does not derive from unityengine.Component','OK');
						}
						return false;
					}
				}
				if (Event.current.type == DragExited)
					EditorUtility.DisplayDialog('Cannot add script', 'Cannot add script: No class with module "$module" was found. Please make sure the class matches the file name', 'OK');
			}
		}
		return false;
	}

	@:overload override public function OnInspectorGUI()
	{
		var obj = DragAndDrop.objectReferences;
		if (obj == null || obj.Length == 0)
		{
			super.OnInspectorGUI();
			return;
		}
		if (!handleDragDrop(_target.gameObject))
			super.OnInspectorGUI();
	}
}
