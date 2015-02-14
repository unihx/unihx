package unihx.pvt.editor;
import unihx.pvt.compiler.*;

/**
	All the global state inside unihx editor support will be contained within here.
 **/
class Globals
{
	public static var chain(get,null):CompileChain;

	private static function get_chain()
	{
		if (chain != null)
			return chain;

#if UNIHX_DEBUG_INIT
		// debug initialization problems with this
		var file = sys.io.File.write('traces.txt');
		haxe.Log.trace = function(v,?infos:haxe.PosInfos) {
			var str:String = null;
			if (infos != null) {
				str = infos.fileName + ":" + infos.lineNumber + ": " + v;
				if (infos.customParams != null)
				{
					str += "," + infos.customParams.join(",");
				}
			} else {
				str = v;
			}
			file.writeString(str + "\n");
			file.flush();
		};
#end

		var hxml = new HxmlProps();
		hxml.reload();
		chain = new CompileChain(hxml);
		chain.compiler.clearConsole = function() StickyMessage.clearConsole();
		chain.compiler.markDirty = function() StickyMessage.markDirty();

		if (chain.metas.checkAll())
			unityeditor.AssetDatabase.Refresh();

		StickyMessage.addContainer(chain.compiler);
		return chain;
	}
}
