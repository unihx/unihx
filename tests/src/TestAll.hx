import utest.Runner;
import utest.ui.Report;

class TestAll
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

		// runner.addCase(new tests.YieldTests());
		var x:unihx._internal.PrivateTypeAccess<"List","ListIterator",Int> = null;

		var report = new utest.ui.text.PrintReport(runner);
		runner.run();
	}
}
