import sys.net.*;
import haxe.io.*;
import sys.FileSystem.*;

import Protocol;
using StringTools;

class Client
{
	static var timeout_secs = 10 * 60;

	static function main()
	{
		new mcli.Dispatch(Sys.args()).dispatch(new ClientCmd());
	}

	public static function run(cmd:ClientCmd, host:String, port:Int)
	{
		var proto = new Protocol(Bytes.ofString(cmd.secret)),
				sock = new Socket();
		sock.setTimeout(timeout_secs);
		sock.connect(new Host(host), port);
		var config = haxe.Json.parse( sys.io.File.getContent( cmd.config ) );
		trace('sending...');
		proto.toServer(sock.output, config, cmd.sendFile);
		trace('sent. waiting reponse');
		var ret = proto.fromServer(sock.input, sys.io.File.write( cmd.out ));
		var allOk = true;
		for (r in ret.setup)
			allOk = printRet(r) && allOk;
		if (ret.mainAppGui != null)
			allOk = printRet(ret.mainAppGui) && allOk;
		for (r in ret.mainAppShell)
			allOk = printRet(r) && allOk;
		for (r in ret.cleanup)
			allOk = printRet(r) && allOk;

		Sys.exit(allOk ? 0 : 1);
	}

	private static function printRet(ret:CmdRet):Bool
	{
		if (ret.out.trim().length > 0)
			Sys.println(ret.out);
		if (ret.exit != 0)
		{
			Sys.stderr().writeString('Command returned: ${ret.exit}\n');
			return false;
		}
		return true;
	}
}

/**
	iOs test runner client. Connect to a test host and run the tests.
**/
class ClientCmd extends mcli.CommandLine
{
	/**
		The target file name
		@alias o
	**/
	public var out:String = "out";

	/**
		Path to file to send to runner
		@alias f
	**/
	public var sendFile:String = "send-file";

	/**
		Sets the shared secret between peers
		@alias s
	**/
	public var secret:String = "notasecret";

	/**
		The json configuration file
		@alias c
	**/
	public var config:String = "iosrun.json";

	/**
		Show this message.
	**/
	public function help()
	{
		Sys.println(this.showUsage());
		Sys.exit(0);
	}

	/**
		Connects to the test runner
	**/
	public function connect(host:String, port:Int)
	{
		if (host == null || port == 0)
			throw 'You must enter a host and a port';
		if (sendFile == null)
			throw "You must enter a file to send";
		else if (!exists(sendFile))
			throw 'File $sendFile does not exist';
		if (!exists(config))
			throw 'File $config does not exist';

		Client.run(this, host, port);
	}
}
