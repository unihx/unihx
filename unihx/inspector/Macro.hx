package unihx.inspector;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context.*;
using haxe.macro.Tools;
using StringTools;

class Macro
{
	public static function build():Array<Field>
	{
		var fields = getBuildFields();
		switch ComplexType.TAnonymous(fields).toType() {
			case TAnonymous(f):
				var f = f.get();
				var allfields = [],
						ethis = macro this;
				var fs = [ for (f in f.fields) f.name => f ];
				for (cf in fields)
				{
					var expr = exprFromType(ethis, fs[cf.name]);
					changePos(expr,cf.pos);
					if (expr != null)
						allfields.push(expr);
				}
				var block = { expr:EBlock(allfields), pos:currentPos() };
				var td = macro class { public function OnGUI() $block; };
				fields.push(td.fields[0]);
			case _: throw "assert";
		}
		return fields;
	}

	public static function changePos(e:Expr,p)
	{
		function iter(e:Expr)
		{
			e.pos = p;
			e.iter(iter);
		}
		iter(e);
	}

	public static function exprFromType(ethis:Expr, field:ClassField):Expr
	{
		var pos = field.pos;
		var type = follow(field.type),
				pack = null,
				name = null,
				params = null;
		switch type {
			case TMono(_) | TDynamic(_):
				// pack = []; name = "Dynamic"; params = [];
				// throw new Error('Unsupported Dynamic',pos);
				return null;
			case TEnum(e,p):
				var e = e.get();
				pack = e.pack; name = e.name; params = p;
			case TInst(c,p):
				var c = c.get();
				pack = c.pack; name = c.name; params = p;
			case TAnonymous(a):
				var a = a.get();
				var arr = [];
				for (cf in a.fields)
				{
					arr.push( exprFromType(ethis,cf) );
				}
				return { expr: EBlock(arr), pos: pos };
			case TFun(_,_):
				// throw new Error('Unsupported function',pos);
				return null;

			case TAbstract(t,p):
				var t = t.get();
				pack = t.pack; name = t.name; params = p;
			case _:
				return null;
			// case _: throw new Error('assert',pos);
		}

		var ethis = { expr:EField(ethis, field.name), pos:pos };

		var unity = false,
				inspector = false;
		switch pack {
			case ['unityengine']:
				unity = true;
			case ['unihx','inspector']:
				inspector = true;
			case _:
		}

		var docs = field.doc != null ? [ for (c in parseComments(field.doc)) (c.tag == null ? "" : c.tag.trim()) => c.contents.trim() ] : new Map();

		var label = docs.get('label');
		if (label == null)
			label = toSep(field.name, ' '.code);
		var tooltip = docs[''];
		var guiContent = if (tooltip == null)
		{
			macro $v{label};
		} else {
			macro new unityengine.GUIContent($v{label}, $v{tooltip});
		}

		var opts = field.doc == null ? macro null : nativeArray(getOptions(docs, field.pos), pos);

		switch name {
			case 'Vector2' if (unity):
				return macro $ethis = unityeditor.EditorGUILayout.Vector2Field($guiContent, $ethis, $opts);
			case 'Vector3' if (unity):
				return macro $ethis = unityeditor.EditorGUILayout.Vector3Field($guiContent, $ethis, $opts);
			case 'Vector4' if (unity):
				return macro $ethis = unityeditor.EditorGUILayout.Vector4Field($guiContent, $ethis, $opts);
			case 'AnimationCurve' if (unity):
				var range = parseRect(docs['range']),
						color = parseColor(docs['color']);
				if (color == null)
					color = parseColor('green');
				if (range == null)
					return macro $ethis = unityeditor.EditorGUILayout.CurveField($guiContent, $ethis, $opts);
				else
					return macro $ethis = unityeditor.EditorGUILayout.CurveField($guiContent, $ethis, $color, $range, $opts);
			case 'Color' if (unity):
				return macro $ethis = unityeditor.EditorGUILayout.ColorField($guiContent, $ethis, $opts);
			case 'Int' if (pack.length == 0):
				return macro $ethis = unityeditor.EditorGUILayout.IntField($guiContent, $ethis, $opts);
			case 'Slider' if (inspector):
				switch params {
					case [ _.follow() => TAbstract(_.get() => { pack:[], name:name },_) ]: switch name {
						case "Int":
							return macro $ethis.value = unityeditor.EditorGUILayout.IntSlider($guiContent, $ethis.value, $ethis.minLimit, $ethis.maxLimit, $opts);
						case "Float" | "Single":
							return macro $ethis.value = unityeditor.EditorGUILayout.Slider($guiContent, $ethis.value, $ethis.minLimit, $ethis.maxLimit, $opts);
						case _:
							throw new Error("Invalid parameter for Slider: " + name, pos);
					}
					case _:
						throw new Error("Invalid parameter for Slider", pos);
				}
			case _:
				return null;
		}
	}

	public static function nativeArray(arr:Array<Expr>,pos:Position):Expr
	{
		if (arr == null || arr.length == 0)
			return macro null;
		var ret = [];
		ret.push(macro var opts = new cs.NativeArray($v{arr.length}));
		for (i in 0...arr.length)
		{
			ret.push(macro opts[$v{i}] = ${arr[i]});
		}
		ret.push(macro opts);
		return { expr:EBlock(ret), pos:pos };
	}

	public static function getOptions(opts:Map<String,String>,pos:Position):Array<Expr>
	{
		var ret = [];
		var width = parseFloat(opts['width']),
				expandHeight = parseBool(opts['expand-height']),
				expandWidth = parseBool(opts['expand-width']),
				height = parseFloat(opts['height']),
				maxWidth = parseFloat(opts['max-width']),
				minWidth = parseFloat(opts['min-width']),
				maxHeight = parseFloat(opts['max-height']),
				minHeight = parseFloat(opts['min-height']);

		if (minHeight != null)
			ret.push(macro unityengine.GUILayout.MinHeight($v{minHeight}));
		if (maxHeight != null)
			ret.push(macro unityengine.GUILayout.MaxHeight($v{maxHeight}));
		if (minWidth != null)
			ret.push(macro unityengine.GUILayout.MinWidth($v{minWidth}));
		if (maxWidth != null)
			ret.push(macro unityengine.GUILayout.MaxWidth($v{maxWidth}));
		if (height != null)
			ret.push(macro unityengine.GUILayout.Height($v{height}));
		if (expandWidth != null)
			ret.push(macro unityengine.GUILayout.ExpandWidth($v{expandWidth}));
		if (expandHeight != null)
			ret.push(macro unityengine.GUILayout.ExpandHeight($v{expandHeight}));
		if (width != null)
			ret.push(macro unityengine.GUILayout.Width($v{width}));

		return ret;
	}

	private static function parseFloat(str:String):Null<Float>
	{
		if (str == null)
			return null;
		var ret = Std.parseFloat(str);
		if (Math.isNaN(ret))
			return null;
		return ret;
	}

	private static function parseBool(str:String):Null<Bool>
	{
		return switch str {
			case null:
				null;
			case 'YES' | 'yes' | 'true':
				true;
			case 'NO' | 'no' | 'false':
				false;
			case _:
				null;
		}
	}

	private static function parseRect(str:String):Null<Expr>
	{
		if (str == null)
			return null;
		var arr = str.trim().split(',').map(Std.parseFloat);
		return macro new unityengine.Rect($v{arr[0]},$v{arr[1]},$v{arr[2]},$v{arr[3]});
	}

	private static function parseColor(str:String):Null<Expr>
	{
		if (str == null)
			return null;

		var rgba = switch str.trim() {
			case 'black':
				0x000000ff;
			case 'blue':
				0x0000ffff;
			case 'clear':
				0x0;
			case 'cyan':
				0x00FFFFFF;
			case 'gray':
				0x808080ff;
			case 'magenta':
				0xff00ffff;
			case 'red':
				0xff0000ff;
			case 'white':
				0xffffffff;
			case 'yellow':
				0xffea04ff;
			case s if (s.charCodeAt(0) == '#'.code):
				s = s.substr(1);
				switch s.length {
					case 3:
						Std.parseInt('0x' + s.charAt(0) + s.charAt(0) + s.charAt(1) + s.charAt(1) + s.charAt(2) + s.charAt(2) + 'ff');
					case 4:
						Std.parseInt('0x' + s.charAt(0) + s.charAt(0) + s.charAt(1) + s.charAt(1) + s.charAt(2) + s.charAt(2) + s.charAt(3) + s.charAt(3));
					case 6:
						Std.parseInt('0x' + s + "ff");
					case 8:
						Std.parseInt('0x' + s);
					default:
						return null;
				}
			case _:
				return null;
		}
		var r = (rgba >>> 24) & 0xFF,
				g = (rgba >>> 16) & 0xFF,
				b = (rgba >>> 8) & 0xFF,
				a = rgba & 0xff;
		return macro new unityengine.Color($v{r / 0xff}, $v{g / 0xff}, $v{b / 0xff}, $v{a / 0xff});
	}

	public static function parseComments(c:String):Array<{ tag:Null<String>, contents:String }>
	{
		var ret = [];
		var curTag = null;
		var txt = new StringBuf();
		for (ln in c.split("\n"))
		{
			var i = 0, len = ln.length;
			while (i < len)
			{
				switch(ln.fastCodeAt(i))
				{
				case ' '.code, '\t'.code, '*'.code: i++;
				case '@'.code: //found a tag
					var t = txt.toString();
					txt = new StringBuf();
					if (curTag != null || t.length > 0)
					{
						ret.push({ tag:curTag, contents:t });
					}
					var begin = ++i;
					while(i < len)
					{
						switch(ln.fastCodeAt(i))
						{
							case ' '.code, '\t'.code:
								break;
							default: i++;
						}
					}
					curTag = ln.substr(begin, i - begin);
					break;
				default: break;
				}
			}
			if (i < len)
			{
				txt.add(ln.substr(i).replace("\r", "").trim());
				txt.addChar(' '.code);
			}
			txt.addChar('\n'.code);
		}

		var t = txt.toString().trim();
		if (curTag != null || t.length > 0)
			ret.push({ tag:curTag, contents: t });

		return ret;
	}

	public static function toSep(s:String,sep:Int):String
	{
		if (s.length <= 1) return s; //allow upper-case aliases
		var buf = new StringBuf();
		var first = true;
		for (i in 0...s.length)
		{
			var chr = s.charCodeAt(i);
			if (chr >= 'A'.code && chr <= 'Z'.code)
			{
				if (!first)
					buf.addChar(sep);
				buf.addChar( chr - ('A'.code - 'a'.code) );
				first = true;
			} else {
				buf.addChar(chr);
				first = false;
			}
		}

		return buf.toString();
	}
}
