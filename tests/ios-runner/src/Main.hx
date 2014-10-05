import sys.net.*;
import haxe.io.*;

class Main
{
	static var timeout_secs = 5 * 60;

	static function main()
	{
		var proto = new Protocol(Bytes.ofString('teste')),
				sock = new Socket();
		sock.setTimeout(5);
		sock.bind(new Host('0.0.0.0'), 6969);
		sock.listen(5);

		var i = 0;
		while (true)
		{
			var s2 = sock.accept();
			try
			{
				s2.waitForRead();
				s2.setTimeout(timeout_secs);

				var filename = '/tmp/' + DateTools.format(Date.now(), '%Y%m%d %H%M%S${i++}.tgz');
				var ret = proto.fromClient(s2.input, sys.io.File.write(filename));
				trace(ret);
			}
			catch(e:Dynamic)
			{
				trace('error',e);
				trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
				s2.close();
			}
		}
		// External.mainLaunchApp(Sys.args()[0], false);
	}
}
