package unihx.pvt.compiler;
import sys.FileSystem.*;

@:allow(unihx.pvt.compiler) class Haxelib
{
	var libPath:Null<String>;
	var compiler:HaxeCompiler;

	public function new(comp)
	{
		this.compiler = comp;
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

	public function list():Array<{ lib:String }>
	{
		var list = run(['list']);
		if (list.exit == 0)
		{
			return list.out.split('\n').map(function(v) return { lib: v.split(':')[0] } );
		}

		return [];
	}

	public function install(libname:String)
	{
		var ret = run(['install',libname]);
		if (ret != 0)
		{
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
