package unihx.pvt.compiler;
import sys.FileSystem.*;

class CompileChain
{
	public var basePath(default,null):String;

	public var hxml(default,null):HxmlProps;
	public var compiler(default,null):HaxeCompiler;
	public var passes(default,null):CompPasses;
	public var metas(default,null):MetaHandler;
	public var haxelib(default,null):Haxelib;

	var useEmbedded:Bool = true;
	var haxePath:String = null;

	public function new(hxml:HxmlProps)
	{
		this.hxml = hxml;
		this.basePath = haxe.io.Path.directory(hxml.file);
		this.compiler = new HaxeCompiler();
		this.passes = new CompPasses(basePath);
		this.metas = new MetaHandler(passes);
		this.haxelib = new Haxelib(compiler);
	}

	public function setUseEmbedded(b:Bool)
	{
		this.useEmbedded = b;
		setPaths();
	}

	public function setHaxePath(str:String)
	{
		this.haxePath = str;
		setPaths();
	}

	public function setPaths()
	{
		var used = false;
		if (useEmbedded)
		{
			// se if there is an embedded compiler
			var file = Sys.systemName() == "Windows" ? 'haxe.exe' : 'haxe';
			if (exists('$basePath/../Unihx/haxe/$file'))
			{
				used = true;
				compiler.setCompilerPath('$basePath/../Unihx/haxe');
				haxelib.setLibPath('$basePath/../Unihx/lib');
			}
		}
		if (!used)
		{
			compiler.setCompilerPath(haxePath);
			haxelib.setLibPath(null);
		}
	}

	public function compile(forced:Bool):Bool
	{
		return passes.compile(forced,compiler,hxml);
	}
}
