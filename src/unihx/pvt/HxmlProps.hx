package unihx.internal.editor;
import unityengine.*;
import unityeditor.*;
import haxe.ds.Vector;
import unihx.inspector.*;
using StringTools;
import sys.FileSystem.*;

class HxmlProps implements InspectorBuild
{
	private static var _cur:HxmlProps = null;
	public static function get()
	{
		if (_cur == null)
		{
			_cur = new HxmlProps();
			_cur.reload();
		}
		return _cur;
	}

	private var file:String;
	public function new(file="Assets/build.hxml")
	{
		this.file = file;
	}

	/**
		Choose how will Haxe classes be compiled
		@label Compilation
	**/
	public var compilation:Comp;

	/**
		Advanced options
		@label Advanced Options
	**/
	public var advanced:Fold<{
		/**
			Should be verbose?
			@label Verbose
		**/
		public var verbose:Bool = false;

		/**
			Compile Haxe root packages into the `haxe.root` package
			@label No root packages
		**/
		public var noRoot:Bool = true;

	}>;

	/**
		Extra Haxe parameters from build.hxml
		@label Extra parameters
	**/
	public var _:ConstLabel;

	/**
		Extra Haxe parameters from build.hxml
		@min-height 200
	**/
	public var extraParams:TextArea;

	private function getSaveContents()
	{
		var b = new StringBuf();
		b.add('# options\n');
		switch(compilation)
		{
			case CompilationServer(p):
				b.add('--connect $p\n');
				b.add('--macro unihx.internal.macrorunner.Compile.compile()\n');
			case Compile:
				b.add('--macro unihx.internal.macrorunner.Compile.compile()\n');
			case DontCompile:
		}
		if (advanced != null)
		{
			if (advanced.contents.verbose)
				b.add('#verbose\n');
			if (advanced.contents.noRoot)
				b.add('-D no-root\n');
		}
		b.add('\n# required\n');
		b.add('classpaths.hxml\n');
		b.add('-lib unihx\n');
		b.add('-cs hx-compiled\n');
		b.add('-D unity_std_target=Standard Assets\n');
		b.add('\n');
		b.add("# Add your own compiler parameters after this line: \n\n");
		if (extraParams != null)
			b.add(extraParams);
		return b.toString();
	}

	public function save()
	{
		var w = sys.io.File.write(file);
		w.writeString(getSaveContents());
		w.close();
	}

	public function reload()
	{
		var i = sys.io.File.read(this.file);
		reloadFrom(i);
		i.close();
	}

	private function reloadFrom(i:haxe.io.Input)
	{
		var comp = DontCompile,
				buf = new StringBuf();
		if (advanced == null) advanced = new Fold(cast {});
		advanced.contents.verbose = false;
		advanced.contents.noRoot = false;
		try
		{
			var regex = ~/[ \t]+/g;
			while(true)
			{
				var ln = i.readLine().trim();
				var cmd = regex.split(ln);
				switch [cmd[0].trim(), cmd[1]]
				{
					case ['--connect',_] | ['#--connect',_]:
						var portCmd = cmd[1].split(":");
						var port = if (portCmd.length == 1)
							Std.parseInt(portCmd[0]);
						else
							Std.parseInt(portCmd[1]);
						comp = CompilationServer(port);
					case ['#verbose',_]:
						advanced.contents.verbose = true;
					case ['-D','no-root']:
						advanced.contents.noRoot = true;
					case ['--macro','unihx.internal.macrorunner.Compile.compile()']:
						if (comp == DontCompile)
							comp = Compile;

					case ['',null]:
					case ['#', _] if (ln == '# Add your own compiler parameters after this line:'):
					case ['classpaths.hxml',_]
					   | ['-lib','unihx']
						 | ['#', 'options']
						 | ['#','required']
						 | ['-cs',_]:
						// do nothing - it will be added every save
					case ['-D',t] if (t.startsWith('unity_std_target=')):
						// do nothing - it will be added every save

					default:
						 trace(ln,cmd[0],cmd[1]);
						buf.add(ln);
						buf.add("\n");
				}
			}
		}
		catch(e:haxe.io.Eof) {}
		this.compilation = comp;
		this.extraParams = buf.toString().trim();
	}
}

enum Comp
{
	/**
		@label Don't compile
	**/
	DontCompile;
	/**
		@label Use standard Haxe compiler
	**/
	Compile;
	/**
		@label Use compilation server
	**/
	CompilationServer(port:Int);
}
