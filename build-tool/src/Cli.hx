import mcli.*;
import sys.FileSystem.*;

class Cli extends CommandLine
{
	/**
		Show this message.
	**/
	public function help()
	{
		Sys.println(this.showUsage());
		Sys.exit(0);
	}

	private function err(msg:String)
	{
		Sys.stderr().writeString(msg + "\n");
		Sys.exit(1);
	}

	private function haxe(args:Array<String>)
	{
		var ret = Sys.command('haxe',args);
		if (ret != 0)
			Sys.exit(ret);
	}

	public static function main()
	{
		var args = Sys.args();
		if (Sys.getEnv('HAXELIB_RUN') == "1")
		{
			var curpath = args.pop();
			Sys.setCwd(curpath);
		}
		new mcli.Dispatch(args).dispatch(new Helper());
	}
}

/**
	unihx helper tool
**/
class Helper extends Cli
{
	/**
		Initializes the target Unity project to use unihx
	**/
	public function init(d:Dispatch)
	{
		d.dispatch(new InitCmd());
	}
}

/**
	unihx init [target-dir] : initializes the target Unity project to use unihx.
**/
class InitCmd extends Cli
{
	/**
		If set, creates a separate assembly with the whole Haxe standard library, allowing to have multiple hxml build files. This will disable DCE for the standard library.
	**/
	public var createStd:Bool = false;

	public function runDefault(targetDir=".")
	{
		if (!exists(targetDir))
		{
			err('"$targetDir" does not exist');
		}

		// look for 'Assets' folder
		var assets = getAssets(targetDir);
		if (assets == null)
		{
			err('Cannot find the Assets folder at "$targetDir"');
		}

		if (createStd)
		{
			var stdDir = assets + '/Standard Assets/Haxe-Std';
			createDirectory(stdDir);
			haxe(['-lib','unihx','--macro',"unihx._internal.Compiler.compilestd\\(\\)",'-cs',stdDir,'-D','no-compilation']);
		}
	}

	private function getAssets(dir:String):Null<String>
	{
		var full = fullPath(dir).split('\\').join('/').split('/');
		while (full[full.length-1] == "")
			full.pop();

		while (full.length > 1)
		{
			var dir = full.join('/');
			for (file in readDirectory(dir))
			{
				if (file == "Assets")
					return dir + '/Assets';
			}
			full.pop();
		}
		return null;
	}

}
