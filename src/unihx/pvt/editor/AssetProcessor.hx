package unihx.pvt.editor;
import unihx.pvt.*;
import haxe.ds.Vector;
import sys.FileSystem.*;
import haxe.io.Path;
import unityengine.*;
import Std.*;
import cs.system.reflection.BindingFlags;

using StringTools;

@:nativeGen @:keep class AssetProcessor extends unityeditor.AssetPostprocessor
{
	static var passes = new unihx.pvt.CompPasses('Assets');

	static function OnPostprocessAllAssets(
			importedAssets:Vector<String>,
			deletedAssets:Vector<String>,
			movedAssets:Vector<String>,
			movedFromAssetPaths:Vector<String>)
	{
		var sources = [],
				deleted = [],
				refresh = false;
		for (str in importedAssets)
		{
			if (str.endsWith(".hx"))
				sources.push(str);
		}
		for (str in movedAssets)
		{
			if (str.endsWith(".hx"))
				sources.push(str);
		}

		for (d in movedFromAssetPaths)
		{
			if (d.endsWith(".hx"))
			{
				deleted.push(d);
			}
		}
		for (d in deletedAssets)
		{
			if (d.endsWith(".hx"))
			{
				deleted.push(d);
			}
		}

		for (d in deleted)
		{
			//delete also .cs file
			var path = Path.directory(d) + '/hx-compiled/' + Path.withoutDirectory(d).substr(0,-2) + "cs";
			if (exists( path ))
			{
				deleteFile(path);
				if (exists( path + '.meta' ))
					deleteFile( path + '.meta' );
				if (readDirectory( Path.directory(d) + '/hx-compiled' ).length == 0)
					deleteDirectory( Path.directory(d) + '/hx-compiled' );
				refresh = true;
			}
		}
		if (sources.length > 0)
		{
			refresh = true;
			HaxeCompiler.current.compile(HxmlProps.get().advanced.verbose);
		}
		if (refresh)
		{
			unityeditor.AssetDatabase.Refresh();
		}
	}
}
