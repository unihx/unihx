import unihx.tests.*;
import unihx.tests.cases.*;
import unityengine.*;

class UnityTests extends MonoBehaviour
{
	static var runner:Runner;

	static function runTests(onEnd:cs.system.Action_1<Bool>)
	{
		runner = new Runner();
		runner.addCase( new GlobalCase() );
		runner.addCase( new YieldTests() );
		runner.run();

		(new GameObject('Tests').AddComponent() : UnityTests);
	}

	function Update()
	{
		try
		{
			if (runner.hasFinished())
			{
				var tmp = null;
				if (Sys.systemName() == "Windows")
				{
					tmp = Sys.getEnv('TEMP');
					if (tmp == null)
						tmp = "C:";
				} else {
					tmp = "/tmp";
				}

				var file = sys.io.File.write('$tmp/unity_test_result.txt');
				var printer = new Printer();
				printer.print = function(s:String)
				{
					file.writeString(s);
					file.writeString('\n');
				};
				runner.showTests(printer);
				file.close();
				if (!runner.hasErrors())
					sys.io.File.saveContent('$tmp/.unity_no_errors',"no errors");
				unityengine.Application.Quit();
			}
		}
		catch(e:Dynamic)
		{
			trace(e);
			trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			unityengine.Application.Quit();
		}
	}
}
