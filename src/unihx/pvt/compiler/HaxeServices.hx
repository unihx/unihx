package unihx.pvt.compiler;

class HaxeServices
{
	public static function getModule(path:String)
	{
		var name = haxe.io.Path.withoutDirectory(path).substr(0,-3);
		var pack = getPackage(path);
		if (pack == '')
			return name;
		else
			return pack + '.' + name;
	}

	public static function getPackage(path:String)
	{
		var file = sys.io.File.read(path);
		var next:Null<Int> = null;

		inline function ident()
		{
			var r = new StringBuf();
			while(true)
			{
				var chr = file.readByte();
				switch(chr)
				{
					case ' '.code | '\n'.code | '\r'.code | '\t'.code | ';'.code | '/'.code:
						next = chr;
						break;
					case _:
						r.addChar(chr);
				}
			}
			return r.toString();
		}
		var pack = '';
		try
		{
			while(true)
			{
				var n = next;
				next = null;

				switch(n != null ? n : file.readByte())
				{
					case '/'.code:
						switch file.readByte()
						{
							case '/'.code:
								while (true)
								{
									switch(file.readByte())
									{
										case '\n'.code | '\r'.code:
											break;
										case _:
									}
								}
							case '*'.code:
								while(true)
								{
									var n = next;
									next = null;

									switch(n != null ? n : file.readByte())
									{
										case '*'.code if ((next = file.readByte()) == '/'.code):
											break;
										case _:
									}
								}
						}
					case ' '.code | '\t'.code | '\n'.code | '\r'.code:
					case 'i'.code if (ident() == 'mport'):
						while (next != ';'.code)
							ident();
					case 'p'.code if (ident() == 'ackage'):
						while (next != ';'.code)
							pack += ident();
						break;
					case 'u'.code if (ident() == 'sing'):
						while (next != ';'.code)
							ident();
					// case 'c'.code if (ident() == 'lass'):
					// 	break;
					// case 't'.code if (ident() == 'ypedef'):
					// 	break;
					// case 'e'.code if (ident() == 'num'):
					// 	break;
					// case 'a'.code if (ident() == 'bstract'):
					// 	break;
					case _:
						break;
				}
			}
		}
		catch(e:haxe.io.Eof) {}
		file.close();
		return pack;
	}
}
