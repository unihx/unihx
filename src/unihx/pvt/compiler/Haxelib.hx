package unihx.pvt.compiler;
import sys.FileSystem.*;

using StringTools;

@:allow(unihx.pvt.compiler) class Haxelib
{
	var libPath:Null<String>;
	var compiler:HaxeCompiler;

	public function new(comp)
	{
		this.compiler = comp;
	}

	dynamic public function warn(str:String)
	{
		haxe.Log.trace(str,null);
	}

	function setLibPath(path)
	{
		this.libPath = path;
		if (path != null && !exists(path))
		{
			createDirectory(path);
		}
		Sys.putEnv('HAXELIB_PATH',path);
	}

	public function list():Array<{ lib:String, ver:String }>
	{
		var ret = run(['list']);
		if (ret.exit == 0)
		{
			var regex = ~/\[([^\]]+)\]/;
			return ret.out.trim().split('\n').map(function(v:String) {
				var s = v.split(':');
				var lib = s.shift().trim(),
				    vers = s.join(':');
				var ver = regex.match(vers) ? regex.matched(1) : vers;
				return { lib: lib, ver:ver };
			});
		}

		warn('Haxelib operation failed: ${ret.out +'\n' + ret.err}');
		return [];
	}

	public function install(libname:String)
	{
		var ret = run(['install',libname]);
		if (ret.exit != 0)
		{
			warn('install failed: ${ret.out +'\n' + ret.err}');
		}
	}

	public function remove(libname:String)
	{
		var ret = run(['remove',libname]);
		if (ret.exit != 0)
		{
			warn('remove failed: ${ret.out + '\n' + ret.err}');
		}
	}

	public function run(args:Array<String>):{ exit:Int, out:String, err:String }
	{
		var compilerPath = compiler.compilerPath,
		    proc = 'haxelib';
		if (compilerPath != null)
		{
			if (Sys.systemName() == "Windows")
			{
				proc = '$compilerPath/haxelib.exe';
				if (!exists(proc))
					proc = '$compilerPath/haxelib.bat';
			} else {
				proc = '$compilerPath/haxelib';
			}
			if (!exists(proc))
			{
				proc = 'haxelib';
			}
		}

		return Utils.runProcess(proc,args);
	}
}
