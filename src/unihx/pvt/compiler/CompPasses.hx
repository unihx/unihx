package unihx.pvt.compiler;
import sys.FileSystem.*;
import sys.FileSystem;
using StringTools;
using Lambda;

class CompPasses
{
	public var basePath(default,null):String;

	var fstPass:{ editor:Pass, files:Pass };
	var sndPass:{ editor:Pass, files:Pass };

	public function new(basePath)
	{
		this.fstPass = { editor:new Pass('fstpass-editor'), files:new Pass('fstpass') };
		this.sndPass = { editor:new Pass('sndpass-editor'), files:new Pass('sndpass') };
		this.basePath = fullPath(basePath);

		runPass('$basePath/Standard Assets', fstPass, true);
		runPass('$basePath/Pro Standard Assets', fstPass, true);
		runPass('$basePath/Plugins', fstPass, true);
		runPass(basePath, sndPass, false);

		// stash folder
		if (!FileSystem.exists('$basePath/../Temp/Unihx'))
			createDirectory('$basePath/../Temp/Unihx');
	}

	public function iterator()
	{
		return [fstPass.files, fstPass.editor, sndPass.files, sndPass.editor].iterator();
	}

	public function compile(forced:Bool, compiler:HaxeCompiler, hxml:HxmlProps):Bool
	{
		var args = ['--cwd',haxe.io.Path.directory(hxml.file),'-D','no-compilation'];
		// add the hxml arguments directly - don't use build.hxml
		hxml.getArguments(args);

		args.push('--each');

		var verbose = hxml.advanced.verbose;
		//TODO support compilation server here
		var hadErrors = compiler.getMessages().exists(function(v) return v.kind != Warning);

		// in the future we may support to build only what changed;
		// will need DCE off and a new way to deal with FieldLookup
		var compileOnlyChanges = false;
		var toRemoveFiles = [],
		    toRemoveEditor = [],
		    dlls = [];
		var first = true;

		if (!forced)
		{
			var skip = true;
			for (pass in this)
			{
				// trace(pass.changedFiles);
				if (pass.changedFiles.length != 0)
				{
					skip = false;
					break;
				}
			}
			// trace(skip);
			if (skip) return false;
		}

		for (pass in this)
		{
			var isEditor = pass.name.endsWith('editor');
			var toRemove = isEditor ? toRemoveEditor : toRemoveFiles;

			var curArgs = [];
			var changed = pass.changedFiles;
			if (changed.length > 0)
				pass.changedFiles = [];

			var canSkip = pass.fileCount == 0;
			for (dll in pass.dlls)
				dlls.push(dll);

			if (canSkip) continue;
			for (r in toRemoveFiles)
			{
				curArgs.push('--macro');
				curArgs.push('remove("$r")');
			}
			if (isEditor) for (r in toRemoveEditor)
			{
				curArgs.push('--macro');
				curArgs.push('remove("$r")');
			}

			if (changed.length == 0 && !hadErrors)
				canSkip = true;
			if (forced) canSkip = false;

			if (!forced && compileOnlyChanges)
			{
				for (c in changed)
				{
					var hxpath = pass.fileMap[c];
					if (hxpath == null) throw 'assert';
					if (!canSkip) curArgs.push(hxpath);
					toRemove.push(hxpath);
				}
			} else {
				for (hxpath in pass.fileMap)
				{
					if (!canSkip) curArgs.push(hxpath);
					toRemove.push(hxpath);
				}
			}

			if (canSkip) continue;
			if (first) first = false; else args.push('--next');
			for (dll in dlls)
			{
				args.push('-net-lib');
				args.push(dll);
			}
			args = args.concat(curArgs);

			//TODO add here support for compiling to a DLL using Temp/Unihx stash
			args.push('-cs');
			var dir = pass.getCompilePath();

			if (!FileSystem.exists('$basePath/$dir'))
				createDirectory('$basePath/$dir');
			args.push(dir);
		}

		if (first)
			return true; //nothing to compile

		return compiler.compile(args,verbose);
	}

	public function addSource(file:String)
	{
		getPass(file).addPath(file);
	}

	public function addDll(file:String)
	{
		getPass(file).addDll(file);
	}

	public function changedSource(file:String)
	{
		getPass(file).changePath(file);
	}

	public function deleteDll(file:String)
	{
		getPass(file).deleteDll(file);
	}

	public function deleteSource(file:String)
	{
		getPass(file).deletePath(file);
	}

	@:allow(unihx.pvt.compiler) private function getPass(path:String)
	{
		var fpath = fullPath(path);
		if (fpath.startsWith(basePath))
		{
			path = fpath.substr(basePath.length);
			while (true)
			{
				switch (path.charCodeAt(0))
				{
					case '/'.code | '\\'.code:
						path = path.substr(1);
					case _:
						break;
				}
			}
		} else {
			throw "TODO: " + fpath + " , " + basePath;
		}

		var p2 = path.toLowerCase().replace('\\','/');
		if (
			p2.startsWith('standard assets/editor') ||
			p2.startsWith('pro standard assets/editor') ||
			p2.startsWith('plugins/editor')
		)
		{
			return fstPass.editor;
		} else if (
			p2.startsWith('standard assets') ||
			p2.startsWith('pro standard assets') ||
			p2.startsWith('plugins')
		)
		{
			return fstPass.files;
		} else if (p2.indexOf('editor') >= 0) {
			return sndPass.editor;
		} else {
			return sndPass.files;
		}
	}

	private function runPass(path:String, pass:{ editor:Pass, files:Pass }, editorOnRoot:Bool)
	{
		if (FileSystem.exists(path) && isDirectory(path))
		{
			for (file in readDirectory(path))
			{
				var rpath = '$path/$file';
				if (isDirectory(rpath))
				{
					switch(file.toLowerCase())
					{
						case 'editor':
							collectFiles(rpath, pass.editor);
						case 'standard assets' | 'pro standard assets' | 'plugins' if (!editorOnRoot):
							continue;
						case _:
							if (editorOnRoot)
								collectFiles(rpath, pass.files);
							else
								runPass(rpath, pass, false);
					}
				} else {
					if (file.endsWith('.hx'))
						pass.files.addPath(rpath);
					else if (file.endsWith('.dll'))
						pass.files.addDll(rpath);
				}
			}
		}
	}

	private function collectFiles(path:String, pass:Pass)
	{
		for (file in readDirectory(path))
		{
			var rpath = '$path/$file';
			if (isDirectory(rpath))
			{
				collectFiles(rpath,pass);
			} else {
				if (file.endsWith('.hx'))
					pass.addPath(rpath);
				else if (file.endsWith('.dll'))
					pass.addDll(rpath);
			}
		}
	}
}

class Pass
{
	public var dlls:Array<String>;
	public var fileMap:Map<String, String>;
	public var fileCount:Int;

	public var changedFiles:Array<String>;
	public var dirty:Bool;

	public var name:String;

	public function new(name)
	{
		this.name = name;
		// this.files = [];
		this.dlls = [];
		this.fileMap = new Map();

		this.changedFiles = [];
		this.dirty = false;
		this.fileCount = 0;
	}

	public function addPath(path:String)
	{
		var full = fullPath(path);
		if (!fileMap.exists(full))
			fileCount++;
		fileMap[full] = HaxeServices.getModule(path);
		changedFiles.push(full);
	}

	public function getCompilePath()
	{
			return switch(name) {
				case 'fstpass-editor':
					'Standard Assets/Editor/Unihx/hx-compiled';
				case 'fstpass':
					'Standard Assets/Unihx/hx-compiled';
				case 'sndpass-editor':
					'Unihx/Editor/hx-compiled';
				case 'sndpass':
					'Unihx/hx-compiled';
				case _: throw 'assert';
			}
	}

	public function changePath(path:String)
	{
		var full = fullPath(path);
		fileMap[full] = HaxeServices.getModule(path);
		changedFiles.push(full);
	}

	public function deletePath(path:String)
	{
		var full = fullPath(path);
		if (fileMap.remove(full))
			fileCount--;
	}

	public function addDll(path:String)
	{
		var full = fullPath(path);
		dlls.push(full);

		this.dirty = true;
	}

	public function deleteDll(path:String)
	{
		var full = fullPath(path);
		dlls.remove(full);

		this.dirty = true;
	}
}

