package unihx._internal.editor;
import unityengine.*;
import unityeditor.*;
using StringTools;

@:meta(UnityEditor.InitializeOnLoad)
@:nativeGen @:keep class ExampleIconChange
{
	static function __init__()
	{
		trace('working 2');
		unityeditor.EditorApplication.projectWindowItemOnGUI += function(s:String, r:Rect) {
			var file = AssetDatabase.GUIDToAssetPath(s);
			switch(file.split('.').pop())
			{
				case 'hx' | 'hxml':
					var rmin = r.width < r.height ? r.width : r.height;
					var width = .0, height = .0;
					if (r.width < r.height)
					{
						width = r.width;
						height = r.width * (28 / 24);
					} else {
						height = r.height;
						width = r.height * (24 / 28);
					}

					var rect = if (r.width < r.height) {
						rmin -= 5;
						var iconHeight = r.width * 1;
						if (iconHeight > r.height)
							iconHeight = r.height;

						var centerx = r.x + r.width / 2,
								centery = r.y + iconHeight / 2;
						if (rmin >= 64) {
							// icon can be bigger than the default icon
							rmin = 64;
							new Rect(centerx - rmin / 2, centery - rmin/2, rmin, rmin);
						} else {
							// make icon inside the default icon
							rmin = 24;
							new Rect(centerx - rmin / 2, centery - rmin/2, rmin, rmin);
						}
					} else {
						// icon in list
						new Rect(r.x,r.y,rmin,rmin);
					}

					var tex = (file.endsWith('.hx')) ? 'unihx_logo_64.png' : 'unihx_config_logo_64.png';
					GUI.DrawTexture(rect, cast AssetDatabase.LoadAssetAtPath( 'Assets/Editor Default Resources/unihx/$tex', cs.Lib.toNativeType(Texture2D)));
			}
		};
	}
}
