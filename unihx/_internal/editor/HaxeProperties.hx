package unihx._internal.editor;
import unityengine.*;
import unityeditor.*;
import unihx.inspector.*;

class HaxeProperties implements unihx.inspector.InspectorBuild extends EditorWindow
{
	/**
		Here's a cool description
		@label Some Cool Label
	**/
	public var vec2:Vector2;

	/**
		Cool animation curve description!
	**/
	public var curve:AnimationCurve = new AnimationCurve();

	public var t:Toggle;

	/**
		A Slider
	**/
	public var slider:Slider<Int> = new Slider(1,10,5);

	public var obj:Object;

	public var test:{
		/**
			some property here
		**/
		var someProp:String;
		var cc:Int;
	} = cast {};

	// public var cooler:unityengine.Color;

	@:meta(UnityEditor.MenuItem("Window/Haxe Properties"))
	public static function showWindow()
	{
		EditorWindow.GetWindow(cs.Lib.toNativeType(HaxeProperties));
	}

	public function OnGUI()
	{
		Macro.prop(this, vec2);
		Macro.prop(this, curve);
		Macro.prop(this,t);
		if (t)
		{
			Macro.prop(this,slider);
			Macro.prop(this,obj);
			// Macro.prop(this,cooler);
			Macro.prop(this,test);
		}

	}
}
