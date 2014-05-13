package unihx._internal.editor;
import haxe.ds.Vector;
import sys.FileSystem.*;
import haxe.io.Path;

using StringTools;

@:nativeGen @:keep class AssetProcessor extends unityeditor.AssetPostprocessor
{
	static function OnPostprocessAllAssets(
			importedAssets:Vector<String>,
			deletedAssets:Vector<String>,
			movedAssets:Vector<String>,
			movedFromAssetPaths:Vector<String>)
	{
		var sources = [],
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
		}
		for (d in deletedAssets)
		{
			if (d.endsWith(".hx"))
			{
				//delete also .cs file
				var path = Path.directory(d) + '/hx-compiled/' + Path.withoutDirectory(d).substr(0,-2) + "cs";
				if (exists( path ))
				{
					deleteFile(path);
					if (exists( path + '.meta' ))
						deleteFile( path + '.meta' );
					trace( readDirectory( Path.directory(d) + '/hx-compiled' ) );
					if (readDirectory( Path.directory(d) + '/hx-compiled' ).length == 0)
						deleteDirectory( Path.directory(d) + '/hx-compiled' );
					refresh = true;
				}
			}
		}
		if (sources.length > 0)
		{
			trace("calling");
			refresh = true;
			var cmd = new sys.io.Process('haxe',['--cwd',Sys.getCwd() + '/Assets','classpaths.hxml','params.hxml','--macro','unihx._internal.Compiler.compile()']);
			trace(cmd.exitCode());
			trace(cmd.stdout.readAll());
			trace(cmd.stderr.readAll());
			// var r = Sys.command('haxe',['--cwd','Assets','classpaths.hxml','params.hxml','--macro','unihx._internal.Compiler.compile\\(\\)']);
			// trace(r);
		}
		if (refresh)
		{
			unityeditor.AssetDatabase.Refresh();
		}
	}
}
