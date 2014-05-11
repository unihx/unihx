package unihx._internal;
import haxe.macro.*;
import sys.FileSystem.*;
using StringTools;

class Compiler
{
	macro public static function compilestd():Void
	{
		var std = getStdDir();
		if (std == null)
			throw "Cannot find std dir";

		trace(std);
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
