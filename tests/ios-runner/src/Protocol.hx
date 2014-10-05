import haxe.io.*;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.*;

using Protocol;

class Protocol
{
	private var secret:Bytes;
	private var hmac:Hmac;
	private var bufSize:Int;
	public function new(secret:Bytes, bufSize=32768)
	{
		this.secret = secret;
		this.hmac = new Hmac(SHA256);
		this.bufSize =bufSize;
	}

	public function toServer(out:Output, meta:InServerMeta, filepath:String):Void
	{
		out.writeString("IOSTEST"); //greeting
		out.writeByte(0x1); //other modes are reserved

		meta.stamp = Std.int( Date.now().getTime() / 15000 );
		var ser = Bytes.ofString(Serializer.run(meta));
		// compute signature
		var sig = sign(ser);
		out.sendBytes(ser);
		out.sendBytes(sig);

		var size = sys.FileSystem.stat(filepath).size,
				inp = sys.io.File.read(filepath);
		out.writeInt32(size);
		out.writeInput(inp,bufSize);
		out.writeByte(0xf5);
		out.flush();
	}

	public function fromClient(i:Input, outFile:Output):InServerMeta
	{
		if (i.readString("IOSTEST".length) != "IOSTEST")
			throw "Invalid greeting";
		trace('greetok');
		if (i.readByte() != 0x1) throw "Unknown mode";
		trace('mode');

		var ser = i.rcvBytes(),
				sig = i.rcvBytes();
		//check signature
		var uns:InServerMeta = Unserializer.run(ser.toString());
		trace(uns);
		checkSign(ser, uns.stamp, sig);
		trace('sign ok');

		var size = i.readInt32();
		trace(size);
		var buf = Bytes.alloc(bufSize);
		while( size > 0 ) {
			var len = i.readBytes(buf,0,size < bufSize ? size : bufSize);
			trace(len,size);
			if( len == 0 )
				throw Error.Blocked;
			outFile.writeFullBytes(buf,0,len);
			size -= len;
		}
		outFile.close();
		trace('ok');

		if (i.readByte() != 0xf5) throw "Invalid eof byte";
		return uns;
	}

	inline private static function sendBytes(out:Output, str:Bytes)
	{
		out.writeInt16(str.length);
		var ret = out.writeBytes(str,0,str.length);
		if (ret == 0)
			throw Error.Blocked;
	}
	inline private static function rcvBytes(i:Input)
	{
		var len = i.readInt16(),
				ret = Bytes.alloc(len);
		i.readFullBytes(ret,0,len);
		return ret;
	}

	inline private function sign(data:Bytes):Bytes
	{
		return hmac.make(secret,data);
	}

	private function checkSign(data:Bytes, stamp:Int, signature:Bytes):Bool
	{
		// check timeout
		var current = Std.int( Date.now().getTime() / 15000 );
		if (Math.abs(current - stamp) > 4) // 1 minute
		{
			throw 'Old timestamp: Current ${Date.now()}; Sent ${Date.fromTime(stamp * 15000.0)}';
		}

		return hmac.make(secret,data).compare(signature) == 0;
	}
}

typedef InServerMeta =
{
	setupShell:Null<String>,
	mainApp:AppType,
	cleanupShell:Null<String>,

	listenFileEnd:String,
	listenFolder:String,
	maxSecsTimeout:Float,

	?stamp:Int
}

enum AppType {
	GUI(appId:String);
	CMD(appPath:String);
}

enum OutServer
{
	Data(data:OutServerData);
	OpenError(msg:String);
	OtherError(msg:String);
}

typedef OutServerData =
{
	results:Array<{ filename:String, contents:Bytes }>,
	didEnd:Bool
}
