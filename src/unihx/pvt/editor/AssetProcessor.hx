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
	static var passes = new unihx.pvt.CompPasses(haxe.io.Path.directory( HxmlProps.get().file ));

	static function OnPostprocessAllAssets(
			importedAssets:Vector<String>,
			deletedAssets:Vector<String>,
			movedAssets:Vector<String>,
			movedFromAssetPaths:Vector<String>)
	{
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

		if (passes.compile( HaxeCompiler.current, HxmlProps.get() ))
		{
			unityeditor.AssetDatabase.Refresh();
		}
		// if (sources.length > 0)
		// {
		// 	refresh = true;
		// 	HaxeCompiler.current.compile(HxmlProps.get().advanced.verbose);
		// }
		// if (refresh)
		// {
		// 	unityeditor.AssetDatabase.Refresh();
		// }
	}
}
