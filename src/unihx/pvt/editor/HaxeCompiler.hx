package unihx.pvt.editor;
import sys.io.Process;
import unityengine.*;
import Std.*;
import unihx.pvt.editor.IMessageContainer;

using StringTools;

class HaxeCompiler implements IMessageContainer
{
	public static var current(default,null):HaxeCompiler = new HaxeCompiler(['--cwd','./Assets','build.hxml','--macro','unihx.pvt.macros.Compile.compile()']);
	var process:Process;
	var messages:Array<Message>;
	var args:Array<String>;

	public function new(args:Array<String>)
	{
		this.args = args;
		messages = [];
		if (current == null) StickyMessage.addContainer(this);
	}

	public function getMessages()
	{
		return messages;
	}

	private function messages_push(m:Message)
	{
		StickyMessage.showMessage(m);
		messages.push(m);
	}

	private function error(msg:String, ?pos):Void
	{
		if (pos == null)
			messages_push({ msg:msg, pos:pos, kind:Error });
		else
			messages_push({ msg:msg, pos:pos, kind:CompilerError });
	}

	private function warn(msg:String, ?pos):Void
	{
		messages_push({ msg:msg, pos:pos, kind:Warning });
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

	public function compile(verbose=false):Bool
	{
		if (messages.length != 0)
			StickyMessage.clearConsole();
		messages = [];
		var cmd = new Process('haxe',args);

		var ret = true;
		if (cmd != null)
		{
			var sw = new cs.system.diagnostics.Stopwatch();
			sw.Start();
			if (cmd.exitCode() != 0)
			{
				ret = false;
				error('Haxe compilation failed');
			}
			sw.Stop();
			if (verbose)
			{
				Debug.Log('Compilation ended (' + sw.Elapsed.Seconds + "." + sw.Elapsed.Milliseconds + ")" );
			}
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
				var pos = null,
						message = ln;
				if (errRegex.match(ln))
				{
					var file = errRegex.matched(1),
							line = errRegex.matched(2);
					message = errRegex.matchedRight().trim();
					var other = errRegex.matched(3);
					var path = cs.system.io.Path.GetFullPath(cs.system.io.Path.Combine("Assets",file));
					var col = 0;
					if (colRegex.match(other))
						col = Std.parseInt(colRegex.matched(1));
					pos = { file:path, line:Std.parseInt(line), column:col, rest:other };
				}
				if (ln.startsWith('Warning'))
					warn(message, pos);
				else
					error(message, pos);
			}
		}
		return ret;
	}

	static var errRegex = ~/(.*):(\d+): ((?:line|character)[^:]*):/;
	static var colRegex = ~/character[s]? (\d+)/;

	public function close()
	{
		if (process != null)
		{
			try { process.kill(); } catch(e:Dynamic) {}
			try { process.close(); } catch(e:Dynamic) {}
			process = null;
		}
	}
}
