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
		if (i.readByte() != 0x1) throw "Unknown mode";

		var ser = i.rcvBytes(),
				sig = i.rcvBytes();
		//check signature
		var uns:InServerMeta = Unserializer.run(ser.toString());
		checkSign(ser, uns.stamp, sig);

		readToFile(i, outFile);

		if (i.readByte() != 0xf5) throw "Invalid eof byte";
		return uns;
	}

	function readToFile(i:Input, outFile:Output)
	{
		var size = i.readInt32();
		var buf = Bytes.alloc(bufSize);
		while( size > 0 ) {
			var len = i.readBytes(buf,0,size < bufSize ? size : bufSize);
			if( len == 0 )
				throw Error.Blocked;
			outFile.writeFullBytes(buf,0,len);
			size -= len;
		}
		outFile.close();
	}

	public function toClient(out:Output, meta:OutServerMeta, filepath:Null<String>):Void
	{
		out.writeByte(0xca);
		sendBytes(out, Bytes.ofString( Serializer.run(meta) ));
		if (filepath != null && sys.FileSystem.exists(filepath))
		{
			out.writeByte(0x7c);
			var size = sys.FileSystem.stat(filepath).size,
					inp = sys.io.File.read(filepath);
			out.writeInt32(size);
			out.writeInput(inp,bufSize);
		} else {
			out.writeByte(0x4a);
		}

		out.writeByte(0xf5);
	}

	public function fromServer(i:Input, outFile:Output):OutServerMeta
	{
		if (i.readByte() != 0xca) throw "Unknown response";
		var ret = Unserializer.run( rcvBytes(i).toString() );
		switch (i.readByte()) {
			case 0x7c:
				readToFile(i,outFile);
			case 0x4a:
				outFile.close();
			case b:
				throw "Unknown reponse: " + b;
		}
		if (i.readByte() != 0xf5) throw "Unknown end response";

		return ret;
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
	setup:Array<ShellCmd>,
	mainAppGui:{ appId:String, listenFileEnd:ShellEcho },
	mainAppShell:Array<ShellCmd>,
	cleanup:Array<ShellCmd>,

	sendFile:Null<ShellEcho>,

	?stamp:Int
}

enum AppType {
	GUI(appId:String, listenFileEnd:String);
	SHELL(shell:Array<CmdRet>);
}

enum OutServer
{
	Data(data:OutServerMeta);
	OpenError;
	OtherError;
}

typedef OutServerMeta =
{
	setup:Array<CmdRet>,
	mainAppGui:Null<CmdRet>,
	mainAppShell:Array<CmdRet>,
	cleanup:Array<CmdRet>,
}

typedef ShellCmd = String;
typedef CmdRet = { out:String, exit:Int };
typedef ShellEcho = String;
