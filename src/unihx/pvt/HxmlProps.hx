package unihx.pvt;
import unityengine.*;
import unityeditor.*;
import haxe.ds.Vector;
import unihx.inspector.*;
using StringTools;
import sys.FileSystem.*;

class HxmlProps implements InspectorBuild
{
	private static var _cur:HxmlProps = null;
	public static function get()
	{
		if (_cur == null)
		{
			_cur = new HxmlProps();
			_cur.reload();
		}
		return _cur;
	}

	private var file:String;
	public function new(file="Assets/build.hxml")
	{
		this.file = file;
	}

	public var libraries:Array<String>;

	/**
		Advanced options
		@label Advanced Options
	**/
	public var advanced:Fold<{
		/**
			Should be verbose?
			@label Verbose
		**/
		public var verbose:Bool = false;

		/**
			Compile Haxe root packages into the `haxe.root` package
			@label No root packages
		**/
		public var noRoot:Bool = true;

	}>;

	/**
		Extra Haxe parameters from build.hxml
		@label Extra parameters
	**/
	public var _:ConstLabel;

	/**
		Extra Haxe parameters from build.hxml
		@min-height 200
	**/
	public var extraParams:TextArea;

	private var warnings:Array<{ msg:String, line:Int }>;

	private function getSaveContents()
	{
		var b = new StringBuf();
		b.add('# options\n');
		if (advanced != null)
		{
			if (advanced.contents.verbose)
				b.add('#verbose\n');
			if (advanced.contents.noRoot)
				b.add('-D no-root\n');
		}
		b.add('\n# required\n');
		b.add('classpaths.hxml\n');
		b.add('-lib unihx\n');
		b.add('-cs hx-compiled\n');
		b.add('-D unity_std_target=Standard Assets\n');
		b.add('\n');
		b.add("# Add your own compiler parameters after this line: \n\n");
		if (extraParams != null)
			b.add(extraParams);
		return b.toString();
	}

	public function save()
	{
		var w = sys.io.File.write(file);
		w.writeString(getSaveContents());
		w.close();
	}

	public function reload()
	{
		if (sys.FileSystem.exists(this.file))
		{
			var i = sys.io.File.read(this.file);
			reloadFrom(i);
			i.close();
		} else {
			reloadFrom( new haxe.io.StringInput("") );
		}
	}

	public function getWarnings()
	{
		if (warnings == null)
			return [];
		else
			return warnings.copy();
	}

	private function reloadFrom(i:haxe.io.Input)
	{
		this.warnings = [];
		var buf = new StringBuf();
		if (advanced == null) advanced = new Fold(cast {});
		advanced.contents.verbose = false;
		advanced.contents.noRoot = false;
		var lineNum = 0;
		try
		{
			var regex = ~/[ \t]+/g;
			while(true)
			{
				lineNum++;
				var ln = i.readLine().trim();
				var cmd = regex.split(ln);
				switch [cmd[0].trim(), cmd[1]]
				{
					case ['#verbose',_]:
						advanced.contents.verbose = true;
					case ['-D','no-root']:
						advanced.contents.noRoot = true;
					case ['params.hxml',_]:
						warnings.push({
							msg: 'It seems that you were running an older version of unihx already. `params.hxml` is now deprecated and can be delted',
							line:lineNum });

					case ['',null]:
					case ['#', _] if (ln == '# Add your own compiler parameters after this line:'):
					case ['classpaths.hxml',_]
					   | ['-lib','unihx']
						 | ['#', 'options']
						 | ['#','required']
						 | ['-cs',_]:
						// do nothing - it will be added every save
					case ['-D',t] if (t.startsWith('unity_std_target=')):
						// do nothing - it will be added every save

					default:
						buf.add(ln);
						buf.add("\n");
				}
			}
		}
		catch(e:haxe.io.Eof) {}
		this.extraParams = buf.toString().trim();
	}
}
