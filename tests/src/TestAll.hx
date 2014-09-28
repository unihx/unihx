import utest.Runner;
import utest.ui.Report;

class TestAll
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
		var runner = new Runner();

		runner.addCase(new tests.YieldTests());

		var report = new utest.ui.text.PrintReport(runner);
		runner.run();

		// ret.close();
	}
}
