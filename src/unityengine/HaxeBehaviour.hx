package unityengine;

@:autoBuild(unihx.pvt.macros.HaxeBehaviourBuild.build())
@:nativeChildren class HaxeBehaviour extends MonoBehaviour implements ISerializationCallbackReceiver
{
	@:protected @:noCompletion var __hx_serialize_string:String;
	@:protected @:noCompletion var __hx_serialize_objects:cs.NativeArray<unityengine.Object>;

	/**
		This function is implemented per ISerializationCallbackReceiver.
		It will be called before serialization, and will serialize all objects which
		can't be correctly handled by the native Unity serializer
	 **/
	@:overload public function OnBeforeSerialize()
	{
	}

	@:overload public function OnAfterDeserialize()
	{
	}
}
