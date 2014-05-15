package unihx._internal.editor;
import haxe.ds.Vector;
import sys.FileSystem.*;
import haxe.io.Path;
import unityengine.*;
import Std.*;
import cs.system.reflection.BindingFlags;

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
			var cmd = comp.compile(['--cwd',Sys.getCwd() + '/Assets','params.hxml','--macro','unihx._internal.Compiler.compile()']);
			if (cmd != null)
			{
				var sw = new cs.system.diagnostics.Stopwatch();
				sw.Start();
				if (cmd.exitCode() != 0)
					Debug.LogError("Haxe compilation failed.");
				sw.Stop();
				if (comp.verbose)
					Debug.Log('Compilation ended (' + sw.Elapsed + ")" );
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
						reportError(ln);
						// Debug.LogError(ln);
				}
			}
		}
		if (refresh)
		{
			unityeditor.AssetDatabase.Refresh();
		}
	}

	public static function reportError(line:String)
	{
		var ln = line.split(':');
		ln.reverse();
		var file = ln.pop(),
				lineno = parseInt(ln.pop()),
				other = ln.pop(),
				rest = ln.join(":");

		var fullp = cs.system.io.Path.GetFullPath(cs.system.io.Path.Combine("Assets",file));
		var debug = cs.Lib.toNativeType(Debug);
		try
		{
			Debug.LogException(new HaxeError(line,fullp,lineno));
		}
		catch(e:Dynamic)
		{
			Debug.LogError(line);
		}
	}
}

@:nativeGen class HaxeError extends cs.system.Exception
{
	var file:String;
	var line:Int;
	var msg:String;
	public function new(msg:String,file:String,line:Int)
	{
		super(msg);
		this.msg = msg;
		this.file = file;
		this.line = line;
	}

	@:overload override private function get_Message():String
	{
		return msg;
	}

	@:overload override private function get_StackTrace():String
	{
		return "(at " + file + ":" + line + ")";
	}
}
