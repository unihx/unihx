package unihx._internal.editor;
import unityengine.*;
import unityeditor.*;
import unihx.inspector.*;

class HaxeProperties implements unihx.inspector.InspectorBuild extends EditorWindow
{
	/**
		Here's a cool description
		@label Some Cool Label
		@width 10
	**/
	public var vec2:Vector2;

	/**
		Cool animation curve description!
		@range 10,20,30,40
		@color #f0f0f0cc
	**/
	public var curve:AnimationCurve;

	public var slider:Slider<Int>;

}
