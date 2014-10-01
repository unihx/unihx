import unihx.tests.*;
import unihx.tests.cases.*;

class CmdTests
{
	static function main()
	{
		// var ret = sys.io.File.write('test.txt');
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			var str:String = null;
			if (infos != null) {
				str = infos.fileName + ":" + infos.lineNumber + ": " + v;
				if (infos.customParams != null)
				{
					str += "," + infos.customParams.join(",");
				}
			} else {
				str = v;
			}
			// ret.writeString(str);
			// ret.writeString('\n');
			cs.system.Console.WriteLine(str);
		};

		var tests:Array<{ var assert(default,null):Assert; }> = [ new YieldTests() ];
		for (t in tests)
		{
			trace(t.assert.getResults().toString());
		}

		// ret.close();
	}
}
