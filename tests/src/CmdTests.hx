import unihx.tests.*;
import unihx.tests.cases.*;

class CmdTests
{
	static function main()
	{
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
