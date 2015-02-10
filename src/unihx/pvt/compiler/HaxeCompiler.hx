package unihx.pvt.compiler;

import Std.*;
import sys.io.Process;
import unityengine.*;
import unihx.pvt.IMessageContainer;

using StringTools;

class HaxeCompiler implements IMessageContainer
{
	var port:Int;
	var process:Process;
	var messages:Array<Message>;

	public function new()
	{
		messages = [];
	}

	public function getMessages()
	{
		return messages;
	}

	private function messages_push(m:Message)
	{
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

	public function ensurePort(port:Int):Void
	{
		if (process == null || port != this.port)
		{
			this.port = port;
			newProcess(port);
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
		this.port = port;
	}

	public function compile(args:Array<String>, verbose=false):Bool
	{
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
