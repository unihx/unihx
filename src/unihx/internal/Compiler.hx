package unihx.internal;
import haxe.macro.*;
import sys.FileSystem.*;
using StringTools;

class Compiler
{
	public static function compile():Void
	{
		var cwd = normalize(Sys.getCwd());
		var asm = '../Library/ScriptAssemblies';
		if (exists(asm))
		{
			for (file in readDirectory(asm))
			{
				if (file.endsWith('.dll'))
					haxe.macro.Compiler.addNativeLib('$asm/$file');
			}
		}
		// var files = [];
		var paths = [ for (p in Context.getClassPath()) if (normalize(p) != null) normalize(p) ];
		for (i in 0...paths.length)
		{
			var cp = paths[i];
			if (cp.startsWith(cwd))
			{
				collect(paths,i);
			}
		}
		haxe.macro.Compiler.include('unihx.internal.editor');
	}

	private static function normalize(path:String)
	{
		if (path == "")
			path = ".";
		if (!exists(path))
			return null;
		try
		{
			var ret = fullPath(haxe.io.Path.removeTrailingSlashes(path));
			switch (Sys.systemName())
			{
				case "Windows" | "Mac":
					ret = ret.toLowerCase();
				case _:
			}
			return ret;
		}
		catch(e:Dynamic)
		{
			return null;
		}
	}

	private static function collect(cps:Array<String>, index:Int, ?pack)
	{
		var cp = cps[index];
		var slash = "/",
				dot = '.';
		if (pack == null)
		{
			slash = "";
			pack = [];
			dot = '';
		}
		var path = cp + slash + pack.join('/');
		for (file in readDirectory(path))
		{
			var path = path + "/" + file;
			if (isDirectory(path))
			{
				var p = normalize(path),
						found = false;
				for (j in 0...cps.length)
				{
					if (j != index && cps[j] == p)
					{
						found = true;
						break;
					}
				}
				if (!found)
				{
					pack.push(file);
					collect(cps,index,pack);
					pack.pop();
				}
			} else if (file.endsWith('.hx')) {
				Context.getModule(pack.join('.') + dot + file.substr(0,-3));
			}
		}
	}

	private static function getStdDir()
	{
		for (cp in Context.getClassPath())
		{
			var cp = haxe.io.Path.removeTrailingSlashes(cp);
			if (exists(cp) && !cp.endsWith('_std') && cp.endsWith('std'))
			{
				return cp;
			}
		}
		return null;
	}
}
