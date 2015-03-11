package unihx.pvt.compiler;
import haxe.io.Path;
import sys.FileSystem.*;
import sys.io.File;
import unihx.pvt.compiler.CompPasses;
using StringTools;
using Lambda;

class MetaHandler
{
	public var basePath(default,null):String;
	public var metaFolder(default,null):String;
	var passes:CompPasses;
	var paths:Map<String, Pass>;

	public function new(passes:CompPasses)
	{
		this.basePath = passes.basePath;
		this.passes = passes;
		this.metaFolder = '$basePath/../Unihx/Metas';
		if (!exists(metaFolder))
			createDirectory(metaFolder);

		this.paths = [ for (p in passes) fullPath(basePath + '/' + p.getCompilePath() + '/src').toLowerCase() => p ];
	}

	public function moveHxSource(from:String, to:String)
	{
		var fromPass = passes.getPass(from),
		    toPass = passes.getPass(to);
		if (fromPass == null || toPass == null) return;
		var fullFrom = fullPath(from),
		    fullTo = fullPath(to);
		var oldModule = fromPass.fileMap[fullFrom],
		    newModule = HaxeServices.getModule(to);
		var fromMetaPath = metaFolder + '/' + fromPass.name + '/' + oldModule.replace('.','/') + '.cs.metahx';
		if (exists(fromMetaPath))
		{
			var toMetaPath = metaFolder + '/' + toPass.name + '/' + newModule.replace('.','/') + '.cs.metahx';
			if (fromMetaPath != toMetaPath)
			{
				copy(fromMetaPath,toMetaPath);
				deleteFile(fromMetaPath);
			}
		}
	}

	public function checkAll():Bool
	{
		var anyChange = false;
		for (pass in passes)
		{
			anyChange = check(pass) || anyChange;
		}
		return anyChange;
	}

	public function check(pass:Pass):Bool
	{
		var name = pass.name;
		var path = basePath + '/' + pass.getCompilePath() + '/src';
		if (exists(path))
			return recurse(pass,path,'');
		return false;
	}

	function copy(from:String,to:String)
	{
		sys.io.File.saveBytes(to,sys.io.File.getBytes(from));
	}

	function recurse(pass:Pass, base:String, part:String)
	{
		var path = base + part;
		var anyChange = false;

		for (file in readDirectory(path))
		{
			var path = '$path/$file';
			if (file.endsWith('.meta'))
			{
				var to = '$metaFolder/${pass.name}/$part/${file}hx';
				if (!exists(to))
				{
					var ppart = '$metaFolder/${pass.name}/$part';
					if (!exists(ppart))
					createDirectory(ppart);
					copy(path,to);
				} else {
					anyChange = checkGuid(path, to) || anyChange;
				}
			} else if (isDirectory(path)) {
				anyChange = recurse(pass, base, '$part/$file') || anyChange;
			} else if (file.endsWith('.cs') && !exists(path + '.meta')) {
				// copy the hxmeta here
				var hxmeta = '$metaFolder/${pass.name}/$part/$file.metahx';
				if (exists(hxmeta))
				{
					copy(hxmeta,path + '.meta');
					anyChange = true;
				}
			}
		}
		return anyChange;
	}

	private function checkGuid(origMetaPath:String, hxMetaPath:String):Bool
	{
		var oc = File.getContent(origMetaPath),
		    hxc = File.getContent(hxMetaPath);
		var og = getGuid(oc), hxg = getGuid(hxc);
		if (og == null)
		{
			trace('Meta format not identified for path $origMetaPath. Please report a bug on unihx with an example meta file');
		} else if (og != hxg) {
			// we'll always assume that the hxMeta GUID will be the correct one
			copy(hxMetaPath,origMetaPath);
			return true;
		} else if (oc != hxc) {
			//same GUID, but different contents: it can happen if the meta contents were updated
			//in this case, copy the original meta to hxmeta
			copy(origMetaPath,hxMetaPath);
		}
		// otherwise the values are the same and guid are the same. All is well.
		return false;
	}

	private function getGuid(contents:String):Null<String>
	{
		for (line in contents.split('\n'))
		{
			var line = line.trim().toLowerCase();
			if (line.startsWith('guid: '))
				return line.substr('guid: '.length);
		}
		return null;
	}

	public function addCsFile(csFile:String):Bool
	{
		var meta = csFile + '.meta';
		if (!exists(meta))
		{
			trace("Sanity check error: A .cs file exists but no associated .meta file was found. This shouldn't happen. Please submit a bug report. .cs file path: " + csFile);
			return false;
		}

		var path = getPassPath(csFile),
		    full = fullPath(csFile);
		if (path != null)
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

			var to = '$metaFolder/${pass.name}/${actual}.metahx';
			var dir = haxe.io.Path.directory(to);
			if (!exists(dir))
				createDirectory(dir);

			if (!exists(to))
				copy(meta,to);
			else
				return checkGuid(meta,to);
		} else {
			trace('not found path',csFile);
		}

		return false;
	}

	private function getPassPath(file:String):String
	{
		var lower = fullPath(file).toLowerCase();
		for (path in paths.keys())
		{
			if (lower.startsWith(path))
			{
				return path;
			}
		}
		return null;
	}

	public function removeCsFile(csFile:String):Void
	{
		var path = getPassPath(csFile);
		if (path != null)
		{
			var pass = paths[path];
			var full = fullPath(csFile);
			var actual = full.substr(path.length);
			while(true) switch (actual.charCodeAt(0))
			{
				case '/'.code | '\\'.code:
					actual = actual.substr(1);
				case _:
					break;
			}

			var to = '$metaFolder/${pass.name}/${Path.withoutExtension(actual)}hx';
			if (exists(to))
				deleteFile(to);
		} else {
			trace('not found path',csFile);
		}
	}

	public function checkPass(p:Pass):Void
	{
		var path = p.getCompilePath();
	}
}
