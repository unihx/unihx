import sys.net.*;
import haxe.io.*;

class Client
{
	static var timeout_secs = 6 * 60;

	static function main()
	{
		var proto = new Protocol(Bytes.ofString('teste')),
				sock = new Socket();
		sock.setTimeout(timeout_secs);
		{
			sock.connect(new Host("192.168.1.66"),6969);
			proto.toServer(sock.output, {
				setupShell:null,
				mainApp:null,
				cleanupShell:null,

				listenFileEnd:"file",
				listenFolder:'folder',
				maxSecsTimeout:timeout_secs
			}, Sys.args()[0]);

			trace(sock.input.readAll());
		}
	}
}

