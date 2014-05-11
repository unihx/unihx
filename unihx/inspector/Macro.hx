package unihx.inspector;
#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context.*;
using haxe.macro.Tools;
using StringTools;
using Lambda;
#end

class Macro
{
	macro public static function prop(ethis:Expr, efield:Expr)
	{
		var field = switch efield.expr {
			case EConst(CIdent(s)) | EConst(CString(s)):
				s;
			case _:
				throw new Error("This argument must either be a constant string or a constant identifier", efield.pos);
		};

		var cf = switch typeof(ethis).follow() {
			case TInst(_.get() => c,_):
				function loop(c:ClassType)
				{
					var f = c.fields.get().find(function (cf) return cf.name == field);
					if (f == null)
					{
						if (c.superClass == null)
							return null;
						return loop( c.superClass.t.get() );
					} else {
						return f;
					}
				}
				loop(c);
			case TAnonymous(_.get() => a):
				a.fields.find(function (cf) return cf.name == field);
			case t:
				throw new Error('Only class instances or anonymous types can be used, but the type was ' + t.toString(), ethis.pos);
		};

		if (cf == null)
			throw new Error('Field $field was not found at ${typeof(ethis).toString()}',currentPos());
		var ret = exprFromType(ethis,cf);
		if (ret == null)
			return macro null;
		else
			return ret;
	}

#if macro
	public static function build():Array<Field>
	{
		var fields = getBuildFields(),
				pos = currentPos();
		var addedFields = [];
		var ctorAdded = [],
				ctor = null;

		for (f in fields)
		{
			if (f.name == "new") ctor = f;
			if (f.access.has(AStatic))
				continue;
			switch f.kind {
				case FVar(t,e):
					if (!f.meta.exists(function(v) return v.name == ":skip"))
						addedFields.push(f);
					if (e != null)
					{
						var ethis = { expr: EField(macro this, f.name), pos:f.pos };
						ctorAdded.push(macro $ethis = $e);
						f.kind = FVar(t,null);
					}
				case _:
			}
		}

		if (fields.exists(function (cf) return cf.name == "OnGUI"))
		{
			if (ctorAdded.length == 0)
				return null;
		} else {
			switch ComplexType.TAnonymous(addedFields).toType() {
				case TAnonymous(f):
					var f = f.get();
					var allfields = [],
							ethis = macro this;
					var fs = [ for (f in f.fields) f.name => f ];
					for (cf in fields)
					{
						var expr = exprFromType(ethis, fs[cf.name]);
						if (expr == null)
							continue;

						changePos(expr,cf.pos);
						allfields.push(expr);
					}
					var block = { expr:EBlock(allfields), pos:pos };
					var td = macro class { public function OnGUI() $block; };
					fields.push(td.fields[0]);
				case _: throw "assert";
			}
		}

		if (ctorAdded.length > 0)
		{
			if (ctor == null)
			{
				var sup = getSuper(getLocalClass()),
						block = [],
						expr = { expr:EBlock(block), pos:pos };
				var kind = sup == null || sup.length == 0 ? FFun({ args:[], ret:null, expr:expr}) : FFun({ args:[ for (s in sup) { name:s.name, opt:s.opt, type:null } ], ret:null, expr:expr });
				if (sup != null)
				{
					block.push({ expr:ECall(macro super, [ for (s in sup) macro $i{s.name} ]), pos:pos });
				}

				ctor = { name: "new", access: [APublic], pos:pos, kind:kind };
				fields.push(ctor);
			}
			switch ctor.kind {
				case FFun(fn):
					var arr =  null;
					switch fn.expr {
						case { expr: EBlock(bl) }:
							arr = bl;
						case _:
							fn.expr = { expr: EBlock( arr = [fn.expr] ), pos: pos };
					}
					for (added in ctorAdded)
						arr.push(added);
				case _: throw "assert";
			}
		}
		return fields;
	}

	private static function getSuper(cls:Ref<ClassType>)
	{
		var sup = cls.get().superClass;
		if (sup == null)
			return null;

		var ctor = sup.t.get().constructor;
		if (ctor == null)
			return getSuper(sup.t);
		return switch ctor.get().type.follow() {
			case TFun(args,_):
				args;
			case _: throw "assert";
		}
	}

	private static function changePos(e:Expr,p)
	{
		function iter(e:Expr)
		{
			e.pos = p;
			e.iter(iter);
		}
		iter(e);
	}

	private static function exprFromType(ethis:Expr, field:ClassField, ?type):Expr
	{
		if (field == null) return null;
		if (type == null) type = field.type;
		var pos = field.pos;
		var pack = null,
				name = null,
				params = null;
		switch type {
			case TMono(r) if (r != null):
				exprFromType(ethis,field,r.get());

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
			case TType(_.get() => { pack:['unihx','inspector'], name:n },p):
				pack = ['unihx','inspector']; name = n; params = p;

			case TType(_,_):
				return exprFromType(ethis, field, follow(type,true));
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
				unity = true;
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

		var opts = field.doc == null ? null : nativeArray(getOptions(docs, field.pos), pos);
		if (opts == null)
			opts = macro null;
			// opts = macro new cs.NativeArray(0);

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
			case 'Layer' if (inspector):
				return macro $ethis = unityeditor.EditorGUILayout.LayerField($guiContent, $ethis, $opts);
			case 'Password' if (inspector):
				return macro $ethis = unityeditor.EditorGUILayout.PasswordField($guiContent, $ethis, $opts);
			case 'Range' if (inspector):
				return macro unityeditor.EditorGUILayout.MinMaxSlider($guiContent, $ethis.minValue, $ethis.maxValue, $ethis.minLimit, $ethis.maxLimit, $opts);
			case 'Rect' if (unity):
				return macro unityeditor.EditorGUILayout.RectField($guiContent, $ethis, $opts);
			case 'Select' if (inspector):
				return macro $ethis.selectedIndex = unityeditor.EditorGUILayout.Popup($guiContent, $ethis.selectedIndex, $ethis.options, $opts);
			case 'Space' if (inspector):
				return macro unityeditor.EditorGUILayout.Space();
			case 'Tag' if (inspector):
				return macro $ethis = unityeditor.EditorGUILayout.TagField($guiContent, $ethis, $opts);
			case 'Text' | 'String':
				return macro $ethis = unityeditor.EditorGUILayout.TextField($guiContent, $ethis, $opts);
			case 'TextArea' if (inspector):
				return macro $ethis = unityeditor.EditorGUILayout.TextArea($ethis, $opts);
			case 'Toggle' if (inspector):
				return macro $ethis = unityeditor.EditorGUILayout.Toggle($guiContent, $ethis, $opts);
			case _ if (field.type.unify( getType("unityengine.Object") )):
				var allowSceneObjects = parseBool(docs['scene-objects']),
						type = parse(pack.join(".") + (pack.length == 0 ? name : "." + name),pos);
				if (allowSceneObjects == null)
					allowSceneObjects = false;
				return macro $ethis = unityeditor.EditorGUILayout.ObjectField($guiContent, $ethis, cs.Lib.toNativeType($type), $v{allowSceneObjects}, $opts);
			case _ if (field.type.unify( getType('unihx.inspector.InspectorBuild') )):
				return macro $ethis.OnGUI();
			case _:
				return null;
		}
	}

	private static function nativeArray(arr:Array<Expr>,pos:Position):Expr
	{
		if (arr == null || arr.length == 0)
			return null;
		var ret = [];
		ret.push(macro var opts = new cs.NativeArray($v{arr.length}));
		for (i in 0...arr.length)
		{
			ret.push(macro opts[$v{i}] = ${arr[i]});
		}
		ret.push(macro opts);
		return { expr:EBlock(ret), pos:pos };
	}

	private static function getOptions(opts:Map<String,String>,pos:Position):Array<Expr>
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

	private static function parseComments(c:String):Array<{ tag:Null<String>, contents:String }>
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

	private static function toSep(s:String,sep:Int):String
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
#end
}
