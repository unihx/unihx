package unihx.pvt.editor;
import unihx.pvt.*;
import haxe.ds.Vector;
import sys.FileSystem.*;
import haxe.io.Path;
import unityengine.*;
import Std.*;
import cs.system.reflection.BindingFlags;

using StringTools;

@:nativeGen @:keep class AssetProcessor extends unityeditor.AssetPostprocessor
{
	static function OnPostprocessAllAssets(
			importedAssets:Vector<String>,
			deletedAssets:Vector<String>,
			movedAssets:Vector<String>,
			movedFromAssetPaths:Vector<String>)
	{
		var chain = Globals.chain;
		var passes = chain.passes;

		for (str in importedAssets)
		{
			if (str.endsWith(".hx"))
				passes.addSource(str);
			else if (str.endsWith(".dll"))
				passes.addDll(str);
		}

		for (str in movedAssets)
		{
			if (str.endsWith(".hx"))
				passes.addSource(str);
			else if (str.endsWith(".dll"))
				passes.addDll(str);
		}

		for (d in movedFromAssetPaths)
		{
			if (d.endsWith(".hx"))
				passes.deleteSource(d);
			else if (d.endsWith(".dll"))
				passes.deleteDll(d);
		}

		for (d in deletedAssets)
		{
			if (d.endsWith(".hx"))
				passes.deleteSource(d);
			else if (d.endsWith(".dll"))
				passes.deleteDll(d);
		}

		if (chain.compile())
		{
			unityeditor.AssetDatabase.Refresh();
		}
	}
}
