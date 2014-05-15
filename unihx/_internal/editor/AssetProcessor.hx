package unihx._internal.editor;
import haxe.ds.Vector;
import sys.FileSystem.*;
import haxe.io.Path;
import unityengine.*;

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
			var comp = HaxeProperties.props();
			var sw = new cs.system.diagnostics.Stopwatch();
			sw.Start();
			var cmd = comp.compile(['--cwd',Sys.getCwd() + '/Assets','params.hxml','--macro','unihx._internal.Compiler.compile()']);
			if (cmd != null)
			{
				if (cmd.exitCode() != 0)
					Debug.LogError("Haxe compilation failed.");
				for (ln in cmd.stdout.readAll().toString().trim().split('\n'))
				{
					var ln = ln.trim();
					if (ln != "")
						Debug.Log(ln);
				}
				for (ln in cmd.stderr.readAll().toString().trim().split('\n'))
				{
					var ln = ln.trim();
					if (ln == "") continue;
					if (ln.startsWith('Warning'))
						Debug.LogWarning(ln);
					else
						Debug.LogError(ln);
				}
			}
			sw.Stop();
			if (comp.verbose)
				Debug.Log('Compilation ended (' + sw.Elapsed + ")" );
		}
		if (refresh)
		{
			unityeditor.AssetDatabase.Refresh();
		}
	}
}
