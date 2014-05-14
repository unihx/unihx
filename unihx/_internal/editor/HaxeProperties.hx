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
		trace('enable');
		props().reload();
	}

	function OnDisable()
	{
	}

	function OnGUI()
	{
		var arr = new cs.NativeArray(1);
		arr[0] = GUILayout.MaxHeight(300);
		GUILayout.BeginVertical(arr);
		scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
		props().OnGUI();
		GUILayout.EndScrollView();
		if (GUILayout.Button("Save",null))
		{
			props().save();
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
	@:isVar public var compilation:Comp = CompilationServer(availablePort());

	public var _:Space;

	/**
		@label Extra parameters
	**/
	public var _:ConstLabel;

	/**
		Extra Haxe parameters from build.hxml
		@min-height 200
	**/
	public var extraParams:TextArea;


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

	public function save()
	{
		var w = sys.io.File.write('Assets/build.hxml');
		switch(compilation)
		{
			case CompilationServer(p):
				if (p < 1024)
					p = availablePort();
				w.writeString('#--connect $p\nparams.hxml\n');
			case Compile:
				w.writeString('params.hxml\n');
			case DontCompile:
		}
		if (extraParams != null)
			w.writeString(extraParams);
		w.close();
	}

	private function reloadFrom(i:haxe.io.Input)
	{
		var comp = DontCompile,
				buf = new StringBuf();
		try
		{
			var regex = ~/[ \t]+/g;
			while(true)
			{
				var ln = i.readLine().trim();
				if (!ln.startsWith("#--connect"))
				{
					var idx = ln.indexOf('#');
					if (idx >= 0)
						ln = ln.substr(0,idx - 1);
				}
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
		this.compilation = comp;
		this.extraParams = buf.toString();
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
