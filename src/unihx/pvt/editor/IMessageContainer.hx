package unihx.pvt.editor;

interface IMessageContainer
{
	function getMessages():Array<Message>;
}

typedef Message = { msg:String, kind:MessageKind, pos:Null<{ file:String, line:Int, column:Int, ?rest:String }> };

enum MessageKind
{
	Error;
	Warning;
	CompilerError;
}
