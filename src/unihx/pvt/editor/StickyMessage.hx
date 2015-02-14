package unihx.pvt.editor;
import unityengine.*;
import cs.system.reflection.*;
import unihx.pvt.IMessageContainer;

@:meta(UnityEditor.InitializeOnLoad)
@:nativeGen @:keep class StickyMessage
{
	static var containers:Array<IMessageContainer> = [];

	static var lastCount = -1;
	static var dirty = false;
	static function __init__()
	{
		unityeditor.EditorApplication.update += function() {
			update();
		};
	}

	public static function markDirty()
	{
		dirty = true;
	}

	public static function update()
	{
		var count = getCount();
		if (count < lastCount || count == 0 || dirty)
		{
			var showAll = count == 0;

			for (c in containers)
			{
				for (msg in c.getMessages())
				{
					if (showAll || !msg.shown)
						showMessage(msg);
					msg.shown = true;
				}
			}
		}
		lastCount = count;
		dirty = false;
	}

	public static function showMessage(msg:Message)
	{
		var contents = msg.msg,
				file = null,
				line = 0;
		if (msg.pos != null)
		{
			var pos = msg.pos;
			file = pos.file; line = pos.line;
			contents += '\nAt ${pos.file}:${pos.line}: col ${pos.column} ${pos.rest != null ? pos.rest : ""}';
		}
		switch (msg.kind)
		{
			case Error if (msg.pos != null):
				Debug.LogException(new Error(contents,file,line));
			case Error:
				Debug.LogError(contents);
			case Warning:
				Debug.LogWarning(contents);
			case CompilerError:
				buildError(msg.pos.file + ": " +contents, msg.pos.file, msg.pos.line, msg.pos.column);
		}
	}

	public static function clearConsole()
	{
		var assembly = cs.system.reflection.Assembly.GetAssembly(cs.Lib.toNativeType(unityeditor.Editor));
		if (assembly == null) return -1;
		var cls:Dynamic = assembly.GetType("UnityEditorInternal.LogEntries");
		if (cls == null) return -1;

		return cls.Clear();
	}

	static function getCount():Int
	{
		var assembly = cs.system.reflection.Assembly.GetAssembly(cs.Lib.toNativeType(unityeditor.Editor));
		if (assembly == null) return -1;
		var cls:Dynamic = assembly.GetType("UnityEditorInternal.LogEntries");
		if (cls == null) return -1;

		return cls.GetCount();
	}

	static function buildError(message:String, file:String, line:Int, column:Int):Void
	{
		var cls:cs.system.Type = cast Debug;
		var flags:Int = 0;
		flags |= cast BindingFlags.Static;
		flags |= cast BindingFlags.NonPublic;
		var flags:BindingFlags = cast flags;
		var ret = cls.GetMethod('LogPlayerBuildError',flags);

		// internal static extern void LogPlayerBuildError(string message, string file, int line, int column);
		ret.Invoke(null, haxe.ds.Vector.fromArrayCopy(untyped [message,file,line,column]).toData());
	}

	public static function addContainer(c:IMessageContainer)
	{
		if (containers.indexOf(c) < 0)
			containers.push(c);
	}

	public static function remove(c:IMessageContainer):Bool
	{
		return containers.remove(c);
	}
}

@:nativeGen class Error extends cs.system.Exception
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
		if (file != null)
			return "(at " + file + ":" + line + ")";
		return '';
	}
}
