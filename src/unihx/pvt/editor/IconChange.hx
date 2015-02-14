package unihx.pvt.editor;
import unityengine.*;
import unityeditor.*;
import sys.FileSystem.*;
using StringTools;

@:meta(UnityEditor.InitializeOnLoad)
@:nativeGen @:keep class IconChange
{
	static function __init__()
	{
		var dir = 'Assets/Editor Default Resources/Unihx';
		if (exists(dir))
		{
			var next:unityeditor.EditorApplication.EditorApplication_CallbackFunction = null;
			next = function()
			{
				for (file in readDirectory(dir)) if (file.endsWith('.png'))
				{
					var importer:TextureImporter = cast AssetImporter.GetAtPath('$dir/$file');
					importer.textureFormat = TextureImporterFormat.ARGB32;
					importer.alphaIsTransparency = true;
					importer.mipmapEnabled = true;
					importer.filterMode = FilterMode.Trilinear;
					AssetDatabase.ImportAsset('$dir/$file');
				}
				unityeditor.EditorApplication.update -= next;
			};
			unityeditor.EditorApplication.update += next;
		}

		unityeditor.EditorApplication.projectWindowItemOnGUI += function(s:String, r:Rect) {
			var file = AssetDatabase.GUIDToAssetPath(s);
			var size = 64;
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
							centery -= rmin/2;
							centery += 2;
							new Rect(centerx - rmin / 2, centery, rmin, rmin);
						}
					} else {
						if (rmin <= 16)
							size = 16;
						// icon in list
						new Rect(r.x,r.y,rmin,rmin);
					}

					var tex = (file.endsWith('.hx')) ? 'unihx_logo_$size.png' : 'unihx_config_logo_$size.png';
					GUI.DrawTexture(rect, cast AssetDatabase.LoadAssetAtPath( 'Assets/Editor Default Resources/Unihx/$tex', cs.Lib.toNativeType(Texture2D)));

					// show extension
					// if (r.height > 20)
					// {
					// 	var ext = new GUIContent(file.split('.').pop());
					// 	var labelStyle = new GUIStyle( EditorStyles.label );
					// 	var size = labelStyle.CalcSize(ext);
					// 	var extRect = r.with({ x:r.x + r.width - size.x, width: size.x, height: size.y });
					// 	GUI.Label(extRect, ext, labelStyle);
					// }
			}
		};
	}
}
