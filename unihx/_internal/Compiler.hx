package unihx._internal;
import haxe.macro.*;
import sys.FileSystem.*;
using StringTools;

class Compiler
{
	macro public static function compile():Void
	{
		var cwd = fullPath(haxe.io.Path.removeTrailingSlashes(Sys.getCwd()));
		// var files = [];
		for (cp in Context.getClassPath())
		{
			var cp = haxe.io.Path.removeTrailingSlashes(cp);
			if (cp == null)
				continue;
			else if (cp == "")
				cp = ".";
			cp = fullPath(cp);
			if (cp.startsWith(cwd))
			{
				collect(cp);
			}
		}
		haxe.macro.Compiler.include('unihx._internal.editor');
	}

	private static function collect(cp:String,?pack)
	{
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
				pack.push(file);
				collect(cp,pack);
				pack.pop();
			} else if (file.endsWith('.hx')) {
				// files.push(pack.join('.') + dot + file.substr(0,-3));
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
