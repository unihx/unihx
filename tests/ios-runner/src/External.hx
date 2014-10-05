@:headerNamespaceCode('
	extern "C" {
		char *mainLaunchApplication(const char *name, int suspended);
	}
')
class External
{
	public static function mainLaunchApp(name:String, suspended:Bool):Null<String>
	{
		var ret:String = null;
		untyped __cpp__('char *r2 = mainLaunchApplication( {0}.__CStr(), suspended );\nif (NULL != r2) {{ {1} = String(r2,strlen(r2)).dup(); free(r2); }} r2 = NULL',name,ret);
		return ret;
	}
}
