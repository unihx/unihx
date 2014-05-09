package unihx._internal;

@:meta(UnityEditor.InitializeOnLoad)
@:native('HaxeBridge')
@:keep class HaxeBridge
{
	static function __init__()
	{
		unityeditor.EditorApplication.update += function() {};
	}
}
