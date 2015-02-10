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

		var hxml = new HxmlProps();
		hxml.reload();
		chain = new CompileChain(hxml);

		StickyMessage.addContainer(chain.compiler);
		return chain;
	}
}
