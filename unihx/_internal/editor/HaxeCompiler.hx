package unihx._internal.editor;
import unihx._internal.editor.HaxeProperties;
import sys.io.Process;

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

	public function compile(args:Array<String>):Null<sys.io.Process>
	{
		switch(props)
		{
			case DontCompile:
				return null;
			case Compile:
				trace('compile',args);
				return new Process("haxe",args);
			case CompilationServer(port):
				if (process == null || ( untyped process.native : cs.system.diagnostics.Process ).HasExited )
					newProcess(port);
				args = args.copy();
				args.push('--connect'); args.push(port+"");
				trace('compile',args);
				return new Process('haxe',args);
		}
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
}
