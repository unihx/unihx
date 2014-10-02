import unihx.tests.*;
import unihx.tests.cases.*;

class CmdTests
{
	static function main()
	{
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
			cs.system.Console.WriteLine(str);
		};
		var runner = new Runner();
		runner.addCase( new YieldTests() );
		runner.run();

		runner.showTests();

		if (runner.hasErrors())
			Sys.exit(1);
		else
			Sys.exit(0);
	}
}
