package unihx._internal;
import haxe.macro.*;
import sys.FileSystem.*;
using StringTools;

class Compiler
{
	macro public static function compile():Void
	{
		var cwd = fullPath(haxe.io.Path.removeTrailingSlashes(Sys.getCwd()));
		trace(cwd);
		trace(Sys.systemName());
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
		for (cp in Context.getClassPath())
		{
			var cp = haxe.io.Path.removeTrailingSlashes(cp);
			if (cp == null || !exists(cp))
				continue;
			else if (cp == "")
				cp = ".";
			trace(cp);
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
				var r = sys.io.File.read(path);
				var hasPack = false;
				try
				{
					while(true)
					{
						var ln = r.readLine();
						var idx = ln.indexOf('package');
						if (idx >= 0)
						{
							hasPack = true;
							var p = ln.substring(idx + 7, ln.indexOf(';',idx)).trim();
							if (p == pack.join('.'))
								Context.getModule(p + dot + file.substr(0,-3));
							break;
						}
					}
				}
				catch(e:haxe.io.Eof) {}
				if (!hasPack && pack.length == 0)
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
