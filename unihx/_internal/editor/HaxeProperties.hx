package unihx._internal.editor;
import unityengine.*;
import unityeditor.*;
import unihx.inspector.*;
import cs.system.net.sockets.*;
import cs.system.net.*;

class HaxeProperties implements unihx.inspector.InspectorBuild extends EditorWindow
{
	public var serializable:HaxePropertiesData = new HaxePropertiesData();

	@:meta(UnityEditor.MenuItem("Window/Haxe Properties"))
	public static function showWindow()
	{
		EditorWindow.GetWindow(cs.Lib.toNativeType(HaxeProperties));
	}

	function OnEnable()
	{
		var s = EditorPrefs.GetString('HaxeProps');
		if (s != null && s != "")
		{
			try
			{
				var ser = haxe.Unserializer.run(s);
				this.serializable = ser;
			}
			catch(e:Dynamic)
			{
				Debug.LogError('Failed while opening saved HaxeProps. Resetting to defaults');
				Debug.LogError(e);
			}
		}
	}

	function OnDisable()
	{
		EditorPrefs.SetString("HaxeProps",haxe.Serializer.run(this.serializable));
	}
}

class HaxePropertiesData implements InspectorBuild
{
	/**
		Choose how will Haxe classes be compiled
	**/
	@:isVar public var compilation(get,set):Comp = CompilationServer(availablePort());
	@:skip var compiler:HaxeCompiler;

	public function new()
	{
	}

	private function get_compilation():Comp
	{
		return compilation;
	}

	private function set_compilation(v:Comp):Comp
	{
		if (!v.equals(compilation))
		{
			update();
		}
		return compilation = v;
	}

	private function update()
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
