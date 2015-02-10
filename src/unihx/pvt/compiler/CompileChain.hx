package unihx.pvt.compiler;

class CompileChain
{
	public var basePath(default,null):String;

	public var hxml(default,null):HxmlProps;
	public var compiler(default,null):HaxeCompiler;
	public var passes(default,null):CompPasses;

	public function new(hxml:HxmlProps)
	{
		this.hxml = hxml;
		this.basePath = haxe.io.Path.directory(hxml.file);
		this.compiler = new HaxeCompiler();
		this.passes = new CompPasses(basePath);
	}

	public function compile():Bool
	{
		return passes.compile(compiler,hxml);
	}
}
