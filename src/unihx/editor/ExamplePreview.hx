package unihx.editor;
import unityengine.*;
import unityeditor.*;
import haxe.ds.Vector;
import unihx.inspector.*;
using StringTools;
import sys.FileSystem.*;

@:meta(UnityEditor.CustomEditor(typeof(UnityEngine.Object)))
@:nativeGen
@:native('ExamplePreview')
class ExamplePreview extends Editor
{
	private var prop:HxmlProps;
	private var scroll:Vector2;

	private function OnEnable()
	{
		Repaint();
	}

	@:overload override public function OnInspectorGUI()
	{
		var path = AssetDatabase.GetAssetPath(target);
		switch (path.split('.').pop())
		{
			case 'hxml' if (path.endsWith('build.hxml')):
				if (this.prop == null)
				{
					this.prop = new HxmlProps(path);
					this.prop.reload();
				}
				GUI.enabled = true;
				// scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
				prop.OnGUI();
				// GUILayout.EndScrollView();

				GUILayout.Space(5);
				var buttonLayout = new cs.NativeArray(1);
				buttonLayout[0] = GUILayout.MinHeight(33);
				if (GUILayout.Button("Save",buttonLayout))
				{
					prop.save();
				}
				GUILayout.Space(5);
				if (GUILayout.Button("Reload",buttonLayout))
				{
					prop.reload();
				}
				GUILayout.Space(5);
				if (GUILayout.Button("Force Recompilation",buttonLayout))
				{
					// prop.compile(['--cwd','./Assets','params.hxml','--macro','unihx._internal.Compiler.compile()']);
					unityeditor.AssetDatabase.Refresh();
				}
				Repaint();

			case 'hx' | 'hxml':
				GUI.enabled = true;
				scroll = GUILayout.BeginScrollView(scroll, new cs.NativeArray(0));
				GUI.enabled = false;
				GUILayout.Label(sys.io.File.getContent( AssetDatabase.GetAssetPath(target) ), null);
				GUILayout.EndScrollView();

			case _:
				super.OnInspectorGUI();
		}
	}
}

class HxmlProps implements InspectorBuild
{
	private var file:String;
	public function new(file:String)
	{
		this.file = file;
	}

	/**
		Choose how will Haxe classes be compiled
	**/
	public var compilation:Comp;

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

	private function getSaveContents()
	{
		var b = new StringBuf();
		if (extraParams == null || extraParams == "")
			b.add("# Add your own compiler parameters here\n\n");
		switch(compilation)
		{
			case CompilationServer(p):
				b.add('params.hxml\n#--connect $p\n');
			case Compile:
				b.add('params.hxml\n');
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
		this.compilation = comp;
		this.extraParams = buf.toString().trim();
	}

	function new()
	{
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
