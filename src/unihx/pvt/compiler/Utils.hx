package unihx.pvt.compiler;
#if neko
import neko.vm.*;
#elseif cpp
import cpp.vm.*;
#elseif java
import java.vm.*;
#end

class Utils
{
	public static function runProcess(name:String, args:Array<String>):{ exit:Int, out:String, err:String }
	{
		var proc = new sys.io.Process(name,args);
		var err = null;
#if cs
		new cs.system.threading.Thread(function() err = proc.stderr.readAll().toString()).Start();
#else
		Thread.create(function() err = proc.stderr.readAll().toString());
#end
		var out = proc.stdout.readAll().toString();
		var exit = proc.exitCode();
		return { exit:exit, out:out, err:err };
	}
}
