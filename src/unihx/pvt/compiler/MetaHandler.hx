package unihx.pvt.compiler;
import sys.FileSystem.*;
import sys.io.File;
using StringTools;
using Lambda;

class MetaHandler
{
	public var basePath(default,null):String;
	public var metaFolder(default,null):String;
	var passes:CompPasses;
	var paths:Map<String, CompPasses>;

	public function new(passes:CompPasses)
	{
		this.basePath = passes.basePath;
		this.metaFolder = '$basePath/../Unihx/Metas';
		if (!exists(metaFolder))
			createDirectory(metaFolder);

		this.paths = [ for (p in passes) fullPath(p.getCompilePath() + '/src').toLowerCase() => p ];
	}

	public function checkAll()
	{
		for (pass in passes)
		{
			var name = pass.name;
			var path = basePath + '/' + passes.getCompilePath() + '/src';
			if (exists(path))
				recurse(pass,path,'');
		}
	}

	function recurse(pass:Pass, base:String, part:String)
	{
		var path = base + part;
		for (file in readDirectory(path))
		{
			var path = '$path/$file';
			if (file.endsWith('.meta'))
			{
				var to = '$metaFolder/${pass.name}/$part/${file}hx';
				if (!exists(to))
				{
					var ppart = '$metaFolder/${pass.name}/$part';
					if (!exists(ppart)) createDirectory(ppart);
					File.copy(path,to);
				} else if (File.getContent(to) != File.getContent(path)) {
					File.copy(path,to);
				}
			} else  if (isDirectory(path)) {
				recurse(pass, base, '$part/$file');
			}
		}
	}

	public function addCsFile(csFile:String):Void
	{
		var meta = csFile.substr(0,csFile.length-2) + 'meta';
		if (!exists(meta))
		{
			trace('META DOES NOT EXIST!!!');
			return;
		}

		var full = fullPath(csFile),
		    lower = full.toLowerCase();
		for (path in paths.keys())
		{
			if (lower.startsWith(path))
			{
				var pass = paths[path];
				var actual = full.substr(path.length);
				while(true) switch (actual.charCodeAt(0))
				{
					case '/'.code | '\\'.code:
						actual = actual.substr(1);
					case _:
						break;
				}

				var to = '$metaFolder/${pass.name}/${actual}hx';
				var dir = haxe.io.Path.directory(to);
				if (!exists(dir))
					createDirectory(dir);

				File.copy(full,to);
			}
		}
	}

	public function removeCsFile(csFile:String):Void
	{
	}

	public function checkHxFile(hxFile:String):Void
	{
	}
}
