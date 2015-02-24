package unihx.pvt.macros;
import haxe.macro.Context;
import haxe.macro.Context.*;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;

class HaxeBehaviourBuild
{
	public static function build()
	{
		var fields = getBuildFields(),
		    cl = getLocalClass();
#if editor
		// build inspector if -D editor
		InspectorMacro.createInspectorIfNeeded(fields,cl);
#end
		// add default values if needed
		var def = DefaultValues.defaultValues(fields, false);
		if (def != null) fields = def;

		// build serializer if needed
		// build yield fields if needed

		return null;
	}
}
