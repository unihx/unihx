package unihx.pvt;
import sys.FileSystem.*;
using StringTools;

class CompPasses
{
	var fstPass:{ editor:Pass, files:Pass };
	var sndPass:{ editor:Pass, files:Pass };

	var basePath:String;

	public function new(basePath)
	{
		this.fstPass = { editor:new Pass(), files:new Pass() };
		this.sndPass = { editor:new Pass(), files:new Pass() };
		this.basePath = fullPath(basePath);

		runPass('$basePath/Standard Assets', fstPass, true);
		runPass('$basePath/Pro Standard Assets', fstPass, true);
		runPass('$basePath/Plugins', fstPass, true);
		runPass(basePath, sndPass, false);
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

	private function getPass(path:String)
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
		if (exists(path) && isDirectory(path))
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

private class Pass
{
	var dlls:Array<String>;
	var fileMap:Map<String, String>;

	var changedFiles:Array<String>;
	var dirty:Bool;

	public function new()
	{
		// this.files = [];
		this.dlls = [];
		this.fileMap = new Map();

		this.changedFiles = [];
		this.dirty = false;
	}

	public function addPath(path:String)
	{
		var full = fullPath(path);
		fileMap[full] = getModule(path);
		changedFiles.push(full);
	}

	private function getModule(path:String)
	{
		var name = haxe.io.Path.withoutDirectory(path).substr(0,-3);
		var pack = getPackage(path);
		if (pack == '')
			return name;
		else
			return pack + '.' + name;
	}

	private function getPackage(path:String)
	{
		var file = sys.io.File.read(path);
		var next:Null<Int> = null;

		inline function ident()
		{
			var r = new StringBuf();
			while(true)
			{
				var chr = file.readByte();
				switch(chr)
				{
					case ' '.code | '\n'.code | '\r'.code | '\t'.code | ';'.code | '/'.code:
						next = chr;
						break;
					case _:
						r.addChar(chr);
				}
			}
			return r.toString();
		}
		var pack = '';
		try
		{
			while(true)
			{
				var n = next;
				next = null;

				switch(n != null ? n : file.readByte())
				{
					case '/'.code:
						switch file.readByte()
						{
							case '/'.code:
								while (true)
								{
									switch(file.readByte())
									{
										case '\n'.code | '\r'.code:
											break;
										case _:
									}
								}
							case '*'.code:
								while(true)
								{
									var n = next;
									next = null;

									switch(n != null ? n : file.readByte())
									{
										case '*'.code if ((next = file.readByte()) == '/'.code):
											break;
										case _:
									}
								}
						}
					case ' '.code | '\t'.code | '\n'.code | '\r'.code:
					case 'i'.code if (ident() == 'mport'):
						while (next != ';'.code)
							ident();
					case 'p'.code if (ident() == 'ackage'):
						while (next != ';'.code)
							pack += ident();
						break;
					case 'u'.code if (ident() == 'sing'):
						while (next != ';'.code)
							ident();
					case _:
						break;
				}
			}
		}
		catch(e:haxe.io.Eof) {}
		file.close();
		return pack;
	}

	public function changePath(path:String)
	{
		var full = fullPath(path);
		fileMap[full] = getModule(path);
		changedFiles.push(full);
	}

	public function deletePath(path:String)
	{
		var full = fullPath(path);
		fileMap.remove(full);
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

