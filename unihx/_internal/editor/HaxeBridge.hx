package unihx._internal.editor;

@:meta(UnityEditor.InitializeOnLoad)
@:keep class HaxeBridge
{
	static function __init__()
	{
		unityeditor.EditorApplication.update += function() {};
	}
}
