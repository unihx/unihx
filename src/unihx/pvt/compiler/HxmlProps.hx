package unihx.pvt.compiler;
import haxe.ds.Vector;
import sys.FileSystem.*;
import unihx.inspector.*;

using StringTools;

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

	@:skip public var file(default,null):String;
	public function new(file="Assets/build.hxml")
	{
		this.file = file;
	}

	/**
		External haxelibs used other than unihx
	 **/
	public var libraries:Array<String>;

	/**
		Additional defines
	**/
	public var defines:Array<{ key:String, value:String }>;

	/**
		@label Advanced Options
	**/
	public var advanced:Fold<{
		/**
			Should be verbose?
		**/
		public var verbose:Bool = false;

		/**
			Compile Haxe root packages into the `haxe.root` package
			@label No root packages
		**/
		public var noRoot:Bool = true;

		/**
			Detect and delete generated files that are no longer used
		**/
		public var deleteUnused:Bool = true;

		/**
			Make the generated code more version-control friendly
			@label Version-Control Friendly
		**/
		public var vcsFriendly:Bool = true;

		/**
			Determines how error positions are reported
		**/
		public var errorPositions:ErrorPositions = RelativePathsOnly;

		/**
			Determines when dead code elimination is performed.
		**/
		public var deadCodeElimination:Dce = DStd;
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
			if (advanced.verbose)
				b.add('#verbose\n');
			if (advanced.noRoot)
				b.add('-D no-root\n');
			if (!advanced.deleteUnused)
				b.add('#dont-delete-unused\n');
			if (!advanced.vcsFriendly)
				b.add('#');
			b.add('-D independent-fieldlookup\n');

			switch (advanced.deadCodeElimination)
			{
				case DNo:
					b.add('-dce no\n');
				case DStd:
				case DFull:
					b.add('-dce full\n');
			}

			switch (advanced.errorPositions)
			{
				case HaxePositions:
					b.add('#haxe-positions\n');
				case GeneratedPositions:
					b.add('-D real-position\n');
				case RelativePathsOnly:
					b.add('-D cs-force-relative-pos\n');
			}
		}
		for (lib in libraries)
		{
			if (lib != '' && lib != null)
				b.add('-lib $lib\n');
		}

		for (def in defines)
		{
			if(def != null && def.key != null)
			{
				b.add('-D ${def.key}');
				if (def.value != null && def.value != '')
					b.add('=${def.value}');
				b.add('\n');
			}
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
			return warnings;
	}

	private function reloadFrom(i:haxe.io.Input)
	{
		this.warnings = [];
		var buf = new StringBuf();
		if (advanced == null) advanced = cast {};
		advanced.verbose = false;
		advanced.noRoot = false;
		advanced.deadCodeElimination = DStd;
		advanced.errorPositions = RelativePathsOnly;
		advanced.deleteUnused = true;
		advanced.vcsFriendly = true;
		libraries = [];
		defines = [];
		var lineNum = 0;
		try
		{
			var regex = ~/[ \t]+/g;
			while(true)
			{
				lineNum++;
				var ln = i.readLine().trim();
				var cmd = regex.split(ln);
				var kind = cmd.shift().trim(),
						cmd = cmd.join(' ').trim();
				switch [kind, cmd]
				{
					case ['#verbose',_] | ['#', 'verbose']:
						advanced.verbose = true;
					case ['-D','no-root']:
						advanced.noRoot = true;
					case ['#dont-delete-unused',_]:
						advanced.deleteUnused = false;
					case ['#-D', 'independent-fieldlookup']:
						advanced.vcsFriendly = false;
					case ['-D', 'independent-fieldlookup']:
						advanced.vcsFriendly = true;

					case ['-dce', 'no']:
						advanced.deadCodeElimination = DNo;
					case ['-dce', 'std']:
						advanced.deadCodeElimination = DStd;
					case ['-dce', 'full']:
						advanced.deadCodeElimination = DFull;

					case ['-D', 'real-position']:
						advanced.errorPositions = GeneratedPositions;
					case ['#haxe-positions',_]:
						advanced.errorPositions = HaxePositions;
					case ['-D', 'cs-force-relative-pos']:
						advanced.errorPositions = RelativePathsOnly;

					case ['params.hxml',_]:
						warnings.push({
							msg: 'It seems that you were running an older version of unihx. `params.hxml` is now deprecated and can be deleted',
							line:lineNum });

					case ['',null]:
					case ['#', 'Add your own compiler parameters after this line:']:
					case ['classpaths.hxml',_]
					   | ['-lib','unihx']
						 | ['#','options']
						 | ['#','required']
						 | ['-cs',_]:
						// do nothing - it will be added every save
					case ['-D',t] if (t.startsWith('unity_std_target=')):
						// do nothing - it will be added every save
					case ['-lib', l]:
						 if (l != '')
							 libraries.push(l);
					case ['-D', key]:
						 var sp = key.trim().split('=');
						 var key = sp.shift().trim(),
								 val = sp.join('=').trim();
						 defines.push({ key:key, value:val });

					default:
						buf.add(ln);
						buf.add("\n");
				}
			}
		}
		catch(e:haxe.io.Eof) {}
		if (advanced.vcsFriendly && advanced.errorPositions == HaxePositions)
		{
			warnings.push({
				msg: 'You\'ve selected version control friendly, but error positions is set to "Haxe Positions". This option will not generate VC-friendly files. See the advanced tab to change this.',
				line: -1
			});
		}
		this.extraParams = buf.toString().trim();
	}
}

enum ErrorPositions
{
	/**
		The position indicators will be related to the Haxe sources that generated them
	**/
	HaxePositions;
	/**
		The position indicators will be related to the generated C# files.
	**/
	GeneratedPositions;
	/**
		The position indicators will still be related to the Haxe sources that generated them.
		Files that were generated by Haxe positions inside the Assets folder will remain unchanged;
		Other paths - that would be otherwise absolute - will be set in relation to a fake `/absolute` path,
		so the path remains unchanged in different environments.

		This option is recommended for projects that must work over version control.
	**/
	RelativePathsOnly;
}

enum Dce
{
	/**
		Do not perform dead code elimination
		@label No DCE
	**/
	DNo;
	/**
		Only perform dead code elimination on the standard library
		@label Standard Library
	**/
	DStd;
	/**
		Perform full dead code elimination
		@label Full
	**/
	DFull;
}
