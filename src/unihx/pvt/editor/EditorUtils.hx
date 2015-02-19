package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;

class EditorUtils
{
	public static function runNextFrame(fn:Void->Void)
	{
		var cb:EditorApplication.EditorApplication_CallbackFunction = null;
		cb = function () {
			EditorApplication.update -= cb;
			fn();
		};
		EditorApplication.update += cb;
	}
}
