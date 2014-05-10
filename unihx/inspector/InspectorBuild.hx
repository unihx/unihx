package unihx.inspector;

@:autoBuild(unihx.inspector.Macro.build())
interface InspectorBuild
{
	function OnGUI():Void;
}
