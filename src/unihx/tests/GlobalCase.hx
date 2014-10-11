package unihx.tests;
import unihx.tests.*;
import unityengine.*;

/**
	This test case is only available inside a Unity environment, and will
	fail if any unhandled exception is found
**/
class GlobalCase
{
	var assert = new Assert();

	public function new()
	{
		// make sure the assert doesn't fail with 'no assertations'
		assert.isTrue(true);
	}

	function globalExceptionHandler(name:String, stackTrace:String, logType:LogType)
	{
		try
		{
			switch (logType) {
				case Error | Exception:
					assert.fail('Unhandled exception: $name.\nStack trace: $stackTrace');
				case _:
			}
		} catch(e:Dynamic) {
			Application.Quit();
		}
	}

}
