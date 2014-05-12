import mcli.*;
import sys.FileSystem.*;

using StringTools;

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
		print( 'haxe ' + [for (arg in args) arg.split('"').join('\\\"') ].join(" ") );
		var ret = Sys.command('haxe ' + [for (arg in args) arg.split('"').join('\\\"') ].join(" "));
		if (ret != 0)
			Sys.exit(ret);
	}

	/**
		Force always to yes
	**/
	public var force:Bool = false;

	public var verbose:Bool = false;

	private function print(msg:String)
	{
		if (verbose) Sys.println(msg);
	}

	private function ask(msg:String, ?preSelect:Bool):Bool
	{
		if (force) return true;
		Sys.println(msg);
		var stdin = Sys.stdin();
		var str = "(" + (preSelect == true ? "Y" : "y") + "/" + (preSelect == false ? "N" : "n") + ") ";
		while (true)
		{
			Sys.print(str);
			var ln = stdin.readLine().trim().toLowerCase();
			if (ln == "" && preSelect != null)
				return preSelect;
			else if (ln == "y")
				return true;
			else if (ln == "n")
				return false;
		}
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
class Helper extends CommandLine
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
	public function runDefault(targetDir=".")
	{
		if (!exists(targetDir))
		{
			err('"$targetDir" does not exist');
		}

		if (targetDir == "")
			targetDir = ".";
		// look for 'Assets' folder
		var assets = getAssets(targetDir);
		if (assets == null)
		{
			err('Cannot find the Assets folder at "$targetDir"');
		}
		if (assets == "")
			assets = ".";

		if (!exists(assets + '/build.hxml') || ask('$targetDir/build.hxml already exists. Replace?',true))
		{
			sys.io.File.saveContent(assets + '/build.hxml', '-lib unihx\n-cs hx-compiled\n-D unity_std_target=Standard Assets');
			var old = Sys.getCwd();
			Sys.setCwd(assets);
			haxe(['build.hxml',"--macro","include\\(\"unihx._internal.editor\"\\)"]);
			Sys.setCwd(old);
		}
	}

	private function getAssets(dir:String):Null<String>
	{
		var full = fullPath(dir).split('\\').join('/').split('/');
		while (full[full.length-1] == "")
			full.pop();

		var buf = new StringBuf();
		buf.add(".");
		while (full.length > 1)
		{
			var dir = full.join('/');
			for (file in readDirectory(dir))
			{
				if (file == "Assets")
					return buf + '/Assets';
			}
			buf.add('/..');
			full.pop();
		}
		return null;
	}

}
