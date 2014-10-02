import unihx.tests.*;
import unihx.tests.cases.*;
import unityengine.*;

class UnityTests extends MonoBehaviour
{
	static var runner:Runner;
	static function runTests(onEnd:cs.system.Action_1<Bool>)
	{
		runner = new Runner();
		runner.addCase( new YieldTests() );
		runner.run();

		runner.showTests();

		if (runner.hasErrors())
			Sys.exit(1);
		else
			Sys.exit(0);

		(new GameObject('Tests').AddComponent() : UnityTests);
	}

	function Update()
	{
		if (runner.hasFinished())
		{
			var file = sys.io.File.write('testResult.txt');
			var printer = new Printer();
			printer.print = function(s:String)
			{
				file.writeString(s);
				file.writeString('\n');
			};
			runner.showTests(printer);
			file.close();
			if (!runner.hasErrors())
				sys.io.File.saveContent('.noErrors',"no errors");
			unityengine.Application.Quit();
		}
	}
}
