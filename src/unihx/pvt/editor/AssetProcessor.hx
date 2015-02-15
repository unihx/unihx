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
		var metas = chain.metas;
		var anyChange = false;

		for (str in importedAssets)
		{
			if (str.endsWith(".hx"))
				passes.addSource(str);
			else if (str.endsWith(".dll"))
				passes.addDll(str);
			else if (str.endsWith(".cs"))
				anyChange = metas.addCsFile(str) || anyChange;
		}

		var i = -1;
		for (str in movedAssets)
		{
			++i;
			if (str.endsWith(".hx")) {
				passes.addSource(str);
				metas.moveHxSource(movedFromAssetPaths[i], movedAssets[i]);
			} else if (str.endsWith(".dll"))
				passes.addDll(str);
			else if (str.endsWith(".cs"))
				anyChange = metas.addCsFile(str) || anyChange;
		}

		for (d in movedFromAssetPaths)
		{
			if (d.endsWith(".hx"))
				passes.deleteSource(d);
			else if (d.endsWith(".dll"))
				passes.deleteDll(d);
			else if (d.endsWith(".cs"))
				metas.removeCsFile(d);
		}

		for (d in deletedAssets)
		{
			if (d.endsWith(".hx"))
				passes.deleteSource(d);
			else if (d.endsWith(".dll"))
				passes.deleteDll(d);
			else if (d.endsWith(".cs"))
				metas.removeCsFile(d);
		}

		if (chain.compile(false) || anyChange)
		{
			unityeditor.AssetDatabase.Refresh();
		}
	}
}
