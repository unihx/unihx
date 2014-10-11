package unihx.inspector;

@:autoBuild(unihx.inspector.Macro.build("OnGUI"))
interface InspectorBuild
{
	function OnGUI():Void;
}
