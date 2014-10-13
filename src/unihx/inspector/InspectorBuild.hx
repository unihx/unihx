package unihx.inspector;

@:autoBuild(unihx.compiler._internal.InspectorMacro.build("OnGUI"))
interface InspectorBuild
{
	function OnGUI():Void;
}
