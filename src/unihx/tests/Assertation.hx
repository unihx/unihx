package unihx.tests;

import haxe.PosInfos;
import haxe.CallStack;

enum Assertation {
	BeginField(f:String);
	ErrorField(f:String, message:String);
	BeginAsync(name:String, pos:PosInfos);
	EndFields;

	Success(pos : PosInfos);
	Failure(msg : String, pos : PosInfos);
	Warning(msg : String, pos : PosInfos);

	Error(e : Dynamic, stack : Array<StackItem>);
	SetupError(e : Dynamic, stack : Array<StackItem>);
	TeardownError(e : Dynamic, stack : Array<StackItem>);

	TimeoutFailure(msg : String, pos:PosInfos);
}
