package unityengine;

// @:autoBuild(unihx.pvt.macros.HaxeBehaviourBuild.build())
@:nativeChildren class HaxeBehaviour extends MonoBehaviour implements ISerializationCallbackReceiver
{
	@:protected var __hx_serialize_string:String;
	@:protected var __hx_serialize_objects:cs.NativeArray<unityengine.Object>;

	@:overload public function OnBeforeSerialize()
	{
	}

	@:overload public function OnAfterDeserialize()
	{
	}
}
