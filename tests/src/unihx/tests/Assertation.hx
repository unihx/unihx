package unihx.tests;

import haxe.PosInfos;
import haxe.CallStack;

enum Assertation {
	Success(pos : PosInfos);
	Failure(msg : String, pos : PosInfos);
	Error(e : Dynamic, stack : Array<StackItem>);
	TimeoutFailure(pos:PosInfos);
	AsyncError(e : Dynamic, stack : Array<StackItem>);
	Warning(msg : String);
}
