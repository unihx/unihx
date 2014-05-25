package unihx._internal.editor;
import unityengine.*;
import unityeditor.*;
import unihx.inspector.*;
import cs.system.net.sockets.*;
import cs.system.net.*;
import sys.FileSystem.*;

using StringTools;

@:native('HaxeProperties')
class HaxeProperties extends EditorWindow
{
	public var scroll:Vector2;
	@:meta(UnityEditor.MenuItem("Window/Haxe Properties"))
	public static function showWindow()
	{
		EditorWindow.GetWindow(cs.Lib.toNativeType(HaxeProperties));
	}

	function OnEnable()
	{
		props();
	}

	function OnDisable()
	{
		props().close();
	}

	function OnGUI()
	{
		var arr = new cs.NativeArray(1);
		arr[0] = GUILayout.MaxHeight(300);
		// arr[1] = GUILayout.MaxWidth(300);
		GUILayout.BeginVertical(arr);
		scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
		props().OnGUI();
		GUILayout.EndScrollView();
		if (GUILayout.Button("Save",null))
		{
			props().save();
		}
		if (GUILayout.Button("Reload",null))
		{
			props().reload();
		}
		if (GUILayout.Button("Force recompile",null))
		{
			props().compile(['--cwd',Sys.getCwd() + '/Assets','build.hxml','--macro','unihx._internal.Compiler.compile()']);
			unityeditor.AssetDatabase.Refresh();
		}
		GUILayout.EndVertical();
	}

	public static function props():HaxePropertiesData
	{
		return HaxePropertiesData.get();
	}
}

class HaxePropertiesData implements InspectorBuild
{
	/**
		Choose how will Haxe classes be compiled
	**/
	public var compilation:Comp;

	public var _:Space;

	public var verbose:Bool;

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

	private var compiler:HaxeCompiler;

	private static var current:HaxePropertiesData;

	public static function get()
	{
		if (current == null)
			return current = new HaxePropertiesData().reload();
		return current;
	}

	public function reload():HaxePropertiesData
	{
		if (exists('Assets/build.hxml'))
		{
			reloadFrom( sys.io.File.read('Assets/build.hxml') );
		} else { //create
			save();
		}
		return this;
	}

	public function compile(args)
	{
		if (compiler == null)
			reload();
		if (compiler == null)
			compiler = new HaxeCompiler(compilation);

		return compiler.compile(args);
	}

	public function close()
	{
		current = null;
		if (compiler != null)
			compiler.close();
		compiler = null;
	}

	private function getSaveContents()
	{
		var b = new StringBuf();
		if (extraParams == null || extraParams == "")
			b.add("# Add your own compiler parameters here\n\n");
		switch(compilation)
		{
			case CompilationServer(p):
				if (p < 1024)
					p = availablePort();
				b.add('build.hxml\n#--connect $p\n');
			case Compile:
				b.add('build.hxml\n');
			case DontCompile:
		}
		if (verbose)
			b.add('#verbose\n');
		b.add('\n');
		if (extraParams != null)
			b.add(extraParams);
		return b.toString();
	}

	public function save()
	{
		var w = sys.io.File.write('Assets/build.hxml');
		w.writeString(getSaveContents());
		w.close();

		if (this.compiler == null || !Type.enumEq(this.compiler.props, this.compilation))
		{
			if (this.compiler != null)
				this.compiler.close();
			this.compiler = new HaxeCompiler(this.compilation);
		}
	}

	private function reloadFrom(i:haxe.io.Input)
	{
		var comp = DontCompile,
				buf = new StringBuf();
		verbose = false;
		try
		{
			var regex = ~/[ \t]+/g;
			while(true)
			{
				var ln = i.readLine().trim();
				var cmd = regex.split(ln);
				switch (cmd[0])
				{
					case '--connect' | '#--connect':
						var portCmd = cmd[1].split(":");
						var port = if (portCmd.length == 1)
							Std.parseInt(portCmd[0]);
						else
							Std.parseInt(portCmd[1]);
						comp = CompilationServer(port);
					case '#verbose':
						verbose = true;
					case 'params.hxml':
						if (comp == DontCompile)
							comp = Compile;
					default:
						buf.add(ln);
						buf.add("\n");
				}
			}
		}
		catch(e:haxe.io.Eof) {}
		if (this.compilation == null || !Type.enumEq(this.compilation,comp))
		{
			if (this.compiler != null)
				this.compiler.close();
			this.compiler = new HaxeCompiler(comp);
		}

		this.compilation = comp;
		this.extraParams = buf.toString().trim();
	}

	function new()
	{
	}

	private static function availablePort()
	{
		var l = new TcpListener(IPAddress.Loopback,0);
		l.Start();
		var port = cast(l.LocalEndpoint, IPEndPoint).Port;
		l.Stop();
		return port;
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
