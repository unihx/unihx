package unihx._internal.editor;
import unihx._internal.editor.HaxeProperties;
import sys.io.Process;
import unityengine.*;
import Std.*;

using StringTools;

class HaxeCompiler
{
	public var props(default,null):Comp;
	var process:Process;

	public function new(prop:Comp)
	{
		this.props = prop;
		switch(prop)
		{
			case CompilationServer(port):
				newProcess(port);
			case _:
		}
	}

	function newProcess(port:Int)
	{
		if (process != null)
		{
			try
			{
				process.kill();
				process.close();
			}
			catch(e:Dynamic) {}
		}
		process = null;
		process = new Process('haxe',['--wait',port + ""]);
	}

	public function compile(args:Array<String>, verbose=false):Bool
	{
		var cmd = switch(props)
		{
			case DontCompile:
				return true;
			case Compile:
				trace('compile',args);
				new Process("haxe",args);
			case CompilationServer(port):
				if (process == null || ( untyped process.native : cs.system.diagnostics.Process ).HasExited )
					newProcess(port);
				args = args.copy();
				args.push('--connect'); args.push(port+"");
				trace('compile',args);
				new Process('haxe',args);
		}

		var ret = true;
		if (cmd != null)
		{
			var sw = new cs.system.diagnostics.Stopwatch();
			sw.Start();
			if (cmd.exitCode() != 0)
			{
				ret = false;
				Debug.LogError("Haxe compilation failed.");
			}
			sw.Stop();
			if (verbose)
				Debug.Log('Compilation ended (' + sw.Elapsed + ")" );
			for (ln in cmd.stdout.readAll().toString().trim().split('\n'))
			{
				var ln = ln.trim();
				if (ln != "")
					Debug.Log(ln);
			}
			for (ln in cmd.stderr.readAll().toString().trim().split('\n'))
			{
				var ln = ln.trim();

				if (ln == "") continue;
				if (ln.startsWith('Warning'))
					Debug.LogWarning(ln);
				else
					reportError(ln);
			}
		}
		return ret;
	}

	public function close()
	{
		if (process != null)
		{
			process.kill();
			process.close();
			process = null;
		}
	}

	public static function reportError(line:String)
	{
		var ln = line.split(':');
		ln.reverse();
		var file = ln.pop(),
				lineno = parseInt(ln.pop()),
				other = ln.pop(),
				rest = ln.join(":");

		var fullp = cs.system.io.Path.GetFullPath(cs.system.io.Path.Combine("Assets",file));
		var debug = cs.Lib.toNativeType(Debug);
		try
		{
			Debug.LogException(new HaxeError(line,fullp,lineno));
		}
		catch(e:Dynamic)
		{
			Debug.LogError(line);
		}
	}
}

@:nativeGen class HaxeError extends cs.system.Exception
{
	var file:String;
	var line:Int;
	var msg:String;
	public function new(msg:String,file:String,line:Int)
	{
		super(msg);
		this.msg = msg;
		this.file = file;
		this.line = line;
	}

	@:overload override private function get_Message():String
	{
		return msg;
	}

	@:overload override private function get_StackTrace():String
	{
		return "(at " + file + ":" + line + ")";
	}
}
