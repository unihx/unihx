package unihx._internal.editor;
import unityengine.*;

@:meta(UnityEditor.InitializeOnLoad)
@:nativeGen @:keep class ExampleStickyWarning
{
	static var lastCount = -1;
	static function __init__()
	{
		trace('working');
		trace(getCount());

		unityeditor.EditorApplication.update += function() {
			var count = getCount();
			if (count < lastCount || count == 0)
				Debug.LogWarning('something');
			lastCount = count;
		};
	}

	static function getCount():Int
	{
		var assembly = cs.system.reflection.Assembly.GetAssembly(cs.Lib.toNativeType(unityeditor.Editor));
		if (assembly == null) return -1;
		var cls:Dynamic = assembly.GetType("UnityEditorInternal.LogEntries");
		if (cls == null) return -1;

		return cls.GetCount();
	}

	public static function start() {
		trace('hallo');
	}
}
