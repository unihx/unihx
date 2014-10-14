package unihx.inspector;

@:autoBuild(unihx.pvt.macros.InspectorMacro.build("OnGUI"))
interface InspectorBuild
{
#if cs
	function OnGUI():Void;
#end
}
