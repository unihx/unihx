package unihx.pvt.macros;
#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context.*;
import sys.FileSystem.*;

using haxe.macro.Tools;
using StringTools;
using Lambda;
#end

class InspectorMacro
{
#if macro
	/**
		Takes all default values from variables and sets them at constructor if needed
		If the fields' type is null, and no default value is made and `forceDefault` is true, a default non-null value is added

		Returns null if no changes are made
	**/
	private static function defaultValues(fields:Array<Field>, forceDefault:Bool):Null<Array<Field>>
	{
		var exprs = [];
		var newf = [],
				ctor = null;
		for (f in fields)
		{
			if (f.name == "_") continue;
			newf.push(f);
			if (f.name == "new") ctor = f;
			if (f.access.has(AStatic))
				continue;
			switch (f.kind)
			{
				case FVar(t,e):
					if (e == null && t != null)
					{
						e = getDefault(t, f.pos);
					}

					takeOffDefaults(t);
					if (e != null)
					{
						var ethis = { expr: EField(macro this, f.name), pos:f.pos };
						exprs.push(macro @:pos(f.pos) $ethis = $e);
					}
					f.kind = FVar(t,null);
				case FProp(get,set,t,e):
					if (e == null && t != null)
					{
						e = getDefault(t, f.pos);
					}

					takeOffDefaults(t);
					if (e != null)
					{
						var ethis = { expr: EField(macro this, f.name), pos:f.pos };
						exprs.push(macro @:pos(f.pos) $ethis = $e);
					}
					f.kind = FProp(get,set,t,null);
				case _:
			}
		}

		if (exprs.length == 0) return null;
		if (ctor == null)
		{
			var pos = currentPos();
			var sup = getSuper(getLocalClass()),
					block = [],
					expr = { expr:EBlock(block), pos:pos };
			var kind = sup == null || sup.length == 0 ? FFun({ args:[], ret:null, expr:expr}) : FFun({ args:[ for (s in sup) { name:s.name, opt:s.opt, type:null } ], ret:null, expr:expr });
			if (sup != null)
			{
				block.push({ expr:ECall(macro super, [ for (s in sup) macro $i{s.name} ]), pos:pos });
			}

			ctor = { name: "new", access: [APublic], pos:pos, kind:kind };
			newf.push(ctor);
		}

		switch (ctor.kind)
		{
			case FFun(fn):
				function add(e:Expr, block:Array<Expr>, i:Int):Bool
				{
					switch(e.expr)
					{
						case EBlock(bl):
							for (i in 0...bl.length)
								if (add(bl[i],bl,i))
									return true;
							var j = exprs.length;
							while (j --> 0)
								bl.unshift(exprs[j]);
							return true;
						case ECall(macro super,_):
							// add all expressions after super call
							var j = exprs.length;
							while (j --> 0)
								block.insert(i+1,exprs[j]);
							return true;
						case _:
							return false;
					}
				}
				add({ expr:EBlock([fn.expr]), pos:fn.expr.pos }, null, -1);
			case _: throw "assert";
		}

		return newf;
	}

	public static function build(fieldName:Null<String>):Array<Field>
	{
    if (defined('display'))
      return null;

		var fields = getBuildFields(),
				pos = currentPos();
		var toRun = [];
		for (f in fields)
		{
			switch (f.kind)
			{
				case FVar(t,e):
					if (!f.meta.exists(function(v) return v.name == ":skip") && f.access.has(APublic))
						toRun.push(f);
				case FProp(get,set,t,e):
					if (!f.meta.exists(function(v) return v.name == ":skip") && f.access.has(APublic))
						toRun.push(f);
				case _:
			}
		}

		var dv = defaultValues(fields, true);
		if (dv != null)
			fields = dv;

		function filter(f:Field)
		{
			switch (f.kind)
			{
				case FVar(t,_) | FProp(_,_,t,_):
					var t = t.toType();
					if (t != null) switch (t.follow())
					{
						case TAbstract(_.get() => { pack:[], name:"Void" },_):
							return false;
						case _:
							return true;
					}
				case _:
			}
			return true;
		}

		var f2 = fields.filter(filter);
		var i = 0;
		for (f in toRun)
			if (f.name == "_")
				f.name = "_" + i++;

		if (defined('cs')) switch (ComplexType.TAnonymous(toRun).toType())
		{
			case TAnonymous(f):
				var f = f.get();
				var exprs = [];
				var ethis= macro this;
				var tfields = [for (f in f.fields) f.name => f];
				for (fold in toRun)
				{
					var f = tfields[fold.name];
					exprs.push(inspectorCall(ethis,f,fields));
				}
				var expr = { expr:EBlock(exprs), pos: currentPos() };
				var field = (macro class { @:overload public function OnGUI() $expr; }).fields[0];
				if (fieldName != null) field.name = fieldName;
				fields.push(field);
			case _:
		}

		return fields;
	}

	private static function inspectorCall(ethis:Expr, field:ClassField, buildFields:Array<Field>, ?type:Type):Expr
	{
		var block = [];
		function handleType(field:ClassField, type:Type):Void
		{
			var docs = field != null && field.doc != null ? [ for (c in parseComments(field.doc)) (c.tag == null ? "" : c.tag.trim()) => c.contents.trim() ] : new Map();
			var guiContent =
			{
				var label = docs.get('label');
				if (label == null)
					label = toSep(field.name, ' '.code);
				var tooltip = docs[''];
				if (tooltip == null)
					// macro $v{label};
					macro new unityengine.GUIContent($v{label});
				else
					macro new unityengine.GUIContent($v{label}, $v{tooltip});
			}
			var opts =
			{
				var opts = field.doc == null ? null : nativeArray(getOptions(docs, field.pos), field.pos);
				if (opts == null)
					opts = macro null;
				opts;
			}

			var efield = { expr:EField(ethis,field.name), pos:field.pos };

			while (true)
			{
				inline function recurse(t:Type) { type = t; continue; }

				var pack = null, name=null, params=null;
				switch (type)
				{
					case TMono(r) if (r != null):
						recurse(r.get());
					case TMono(_) | TDynamic(_) | TFun(_,_):
						if (field != null)
							warning('Ignored field: Unsupported type. Please add @:skip to the field to avoid this warning', field.pos);
					case TAnonymous(anon):
						var fields = anon.get().fields;
						var lastEThis = ethis;
						for (f in fields)
						{
							ethis = { expr: EField(lastEThis, field.name), pos:lastEThis.pos };
							handleType(f,f.type);
						}
						ethis = lastEThis;
					case TEnum(e,p):
						block.push(macro $efield = ${exprFromEnum(efield, e.get(), type, guiContent, opts)});
					case TInst(i,p):
						var i = i.get();
						params = p; name = i.name; pack = i.pack;
					case TAbstract(a, p):
						var a = a.get();
						params = p; name = a.name; pack = a.pack;
					case TType(t,p):
						var t = t.get();
						switch (t.pack)
						{
							case ['unihx','inspector']:
							case _:
								recurse(follow(type,true));
						}
						params = p; name = t.name; pack = t.pack;
					case TLazy(_):
						recurse(follow(type,true));
				}

				if (pack != null) switch [pack, name]
				{
					// unityengine types
					case [['unityengine'], 'Vector2']:
						block.push(macro $efield = unityeditor.EditorGUILayout.Vector2Field($guiContent, $efield, $opts));
					case [['unityengine'], 'Vector3']:
						block.push(macro $efield = unityeditor.EditorGUILayout.Vector3Field($guiContent, $efield, $opts));
					case [['unityengine'], 'Vector4']:
						block.push(macro $efield = unityeditor.EditorGUILayout.Vector4Field($guiContent, $efield, $opts));
					case [['unityengine'], 'AnimationCurve']:
						var range = parseRect(docs['range']),
								color = parseColor(docs['color']);
						if (color == null)
							color = parseColor('green');
						if (range == null)
							block.push(macro $efield = unityeditor.EditorGUILayout.CurveField($guiContent, $efield, $opts));
						else
							block.push(macro $efield = unityeditor.EditorGUILayout.CurveField($guiContent, $efield, $color, $range, $opts));
					case [['unityengine'], 'Color']:
						block.push(macro $efield = unityeditor.EditorGUILayout.ColorField($guiContent, $efield, $opts));
					case [['unityengine'],'Rect']:
						block.push(macro unityeditor.EditorGUILayout.RectField($guiContent, $efield, $opts));
					// basic types
					case [[], 'String']:
						block.push(macro $efield = unityeditor.EditorGUILayout.TextField($guiContent, $efield, $opts));
					case [[], 'Int']:
						block.push(macro $efield = unityeditor.EditorGUILayout.IntField($guiContent, $efield, $opts));
					case [[], 'Bool']:
						block.push(macro $efield = unityeditor.EditorGUILayout.Toggle($guiContent, $efield, $opts));
					case [[], ('Float' | 'Single')]:
						block.push(macro $efield = unityeditor.EditorGUILayout.FloatField($guiContent, $efield, $opts));
					// inspector types
					case [['unihx','inspector'],'Fold']:
						buildFields.push({
							name: field.name + "_is_folded",
							kind: FVar(TPath({ name:'Bool',pack:[] }),null),
							pos: field.pos
						});
						var all = inspectorCall(ethis, field, buildFields, params[0]);
						var efield_folded = { expr:EField(ethis,field.name + '_is_folded'), pos:field.pos };
						block.push(macro {
							if ($efield_folded = unityeditor.EditorGUILayout.Foldout($efield_folded, $guiContent))
							{
								unityeditor.EditorGUI.indentLevel++;
								$all;
								unityeditor.EditorGUI.indentLevel--;
							}
						});
					case [['unihx','inspector'],'Slider']:
						switch (params)
						{
							case [ _.follow() => TAbstract(_.get() => { pack:[], name:name },_) ]: switch (name)
							{
								case "Int":
									block.push(macro $efield.value = unityeditor.EditorGUILayout.IntSlider($guiContent, $efield.value, $efield.minLimit, $efield.maxLimit, $opts));
								case "Float" | "Single":
									block.push(macro $efield.value = unityeditor.EditorGUILayout.Slider($guiContent, $efield.value, $efield.minLimit, $efield.maxLimit, $opts));
								case _:
									throw new Error("Invalid parameter for Slider: " + name, field.pos);
							}
							case _:
								throw new Error("Invalid parameter for Slider", field.pos);
						}
					case [['unihx','inspector'],'Layer']:
						block.push(macro $efield = unityeditor.EditorGUILayout.LayerField($guiContent, $efield, $opts));
					case [['unihx','inspector'],'Password']:
						block.push(macro $efield = unityeditor.EditorGUILayout.PasswordField($guiContent, $efield, $opts));
					case [['unihx','inspector'],'Range']:
						block.push(macro unityeditor.EditorGUILayout.MinMaxSlider($guiContent, $efield.minValue, $efield.maxValue, $efield.minLimit, $efield.maxLimit, $opts));
					case [['unihx','inspector'],'ConstLabel']:
						block.push(macro unityeditor.EditorGUILayout.LabelField($guiContent, $opts));
					case [['unihx','inspector'],'Select']:
						block.push(macro $efield.selectedIndex = unityeditor.EditorGUILayout.Popup($guiContent, $efield.selectedIndex, $efield.options, $opts));
					case [['unihx','inspector'],'Space']:
						block.push(macro unityeditor.EditorGUILayout.Space());
					case [['unihx','inspector'],'Tag']:
						block.push(macro $efield = unityeditor.EditorGUILayout.TagField($guiContent, $efield, $opts));
					case [['unihx','inspector'],'TextArea']:
						block.push(macro $efield = unityeditor.EditorGUILayout.TextArea($efield, $opts));
					// case [['unihx','inspector'],'Button']:
					// 	var e = macro $efield = unityengine.GUILayout.Button($guiContent, $opts);
					// 	if (docs['onclick'] != null)
					// 	{
					// 		var parsed = parse(docs['onclick'], pos);
					// 		return macro if ($e) $parsed;
					// 	}
					// 	return e;
					case _ if(type.unify( getType('unityengine.Object') )):
						var allowSceneObjects = parseBool(docs['scene-objects']),
								type = parse(pack.join(".") + (pack.length == 0 ? name : "." + name),field.pos);
						if (allowSceneObjects == null)
							allowSceneObjects = false;
						block.push(macro $efield = cast unityeditor.EditorGUILayout.ObjectField($guiContent, $efield, cs.Lib.toNativeType($type), $v{allowSceneObjects}, $opts));
					case _ if (type.unify( getType('unihx.inspector.InspectorBuild') )):
						block.push(macro if (efield != null) $efield.OnGUI());
					case _:
				}
				return;
			}
		}
		handleType( field, type == null ? field.type : type );
		return { expr:EBlock(block), pos:field.pos };
	}

	private static function getDefault(t:ComplexType, pos:Position, forceExpr=false):Null<Expr>
	{
		switch(t)
		{
			case TPath(p):
				switch [p.pack, p.name]
				{
					case [ [], 'Int' | 'Float' | 'Single' ]:
						return macro @:pos(pos) 0;
					case [ [], 'Array' ]:
						return macro @:pos(pos) [];
					case [ [], 'Bool']:
						return macro @:pos(pos) false;
					case [ [], 'Null']:
						return macro @:pos(pos) null;
					case [ ['unihx','inspector'] | [], 'Fold' ] if (p.params != null && p.params.length == 1):
						switch (p.params[0])
						{
							case TPType(c):
								return getDefault(c,pos,false);
							case _:
								return forceExpr ? macro @:pos(pos) null : null;
						}
					case _:
						return forceExpr ? macro @:pos(pos) null : null;
				}
			case TAnonymous(fields) | TExtend(_,fields):
				return { expr:EObjectDecl([for (f in fields) switch(f.kind) {
					case FVar(t,e):
						{ field: f.name, expr: e == null ? getDefault(t,f.pos,true) : e };
					case FProp(get,set,t,e):
						{ field: f.name, expr: e == null ? getDefault(t,f.pos,true) : e };
					case _:
						{ field: f.name, expr: macro null };
				} ]), pos:pos };
			case TFunction(_,_), TParent(_), TOptional(_):
				return forceExpr ? macro @:pos(pos) null : null;
		}
	}

	private static function takeOffDefaults(c:ComplexType)
	{
		switch (c)
		{
			case TPath(p):
				if (p.params != null) for (p in p.params)
				{
					switch (p)
					{
						case TPType(c):
							takeOffDefaults(c);
						case _:
					}
				}
			case TFunction(args,ret):
				for(arg in args) takeOffDefaults(arg);takeOffDefaults(ret);
			case TAnonymous(fields) | TExtend(_,fields):
				for (f in fields)
				{
					switch(f.kind)
					{
						case FVar(t,_):
							takeOffDefaults(t);
							f.kind = FVar(t,null);
						case FProp(get,set,t,_):
							takeOffDefaults(t);
							f.kind = FProp(get,set,t,null);
						case _:
					}
				}
			case TParent(t):
				takeOffDefaults(t);
			case TOptional(t):
				takeOffDefaults(t);
		}
	}

	private static function type(c:ComplexType, pos:Position):Type
	{
		return typeof( { expr:ECheckType(macro cast null, c), pos:pos } );
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
			case _:
				throw "assert";
		}
	}

	private static function exprFromEnum(ethis:Expr, e:EnumType, t:Type, label, opts):Expr
	{
		//ensure created helper class
		var tname = ensureEnumHelper(e,t,ethis.pos);
		return macro $tname.editorHelper($ethis, $label, $opts);
	}

	public static function buildEnumHelper(module:String, name:String)
	{
		var type = getModule(module).find(function(v) return switch(v.follow()) { case TEnum(e,_) if (e.get().name == name): true; case _: false; });
		var e = switch type {
			case TEnum(e,_):
				e.get();
			default:
				throw new Error("assert: not an enum : " + name, currentPos());
		};
		var pos = currentPos();

		// starting type definition
		var etype = type.toComplexType();
		var cases = [],
				guiContent = [],
				values = [];
		var i = 0;
		for (name in e.names)
		{
			var ctor = e.constructs.get(name);
			var docs = ctor.doc != null ? [ for (c in parseComments(ctor.doc)) (c.tag == null ? "" : c.tag.trim() == "arg" ? c.tag.trim() + "-" + c.contents.trim().split(' ')[0] : c.tag.trim()) => c.contents.trim() ] : new Map();

			var label = docs.get('label');
			if (label == null)
				label = toSep(ctor.name, ' '.code);
			// var ct = macro $v{label};
			var tooltip = docs[''];
			var ct = if (tooltip == null)
			{
				macro new unityengine.GUIContent($v{label});
			} else {
				macro new unityengine.GUIContent($v{label}, $v{tooltip});
			}
			guiContent.push(ct);
			values.push(macro $v{++i});
			switch ctor.type.follow() {
				case TEnum(_,_):
					cases.push( { values:[macro $v{i}], expr:macro return ${parse( etype.toString() + '.' + name, pos )}, guard:null } );
				case TFun(args,_):
					var exprs = [{ expr:EVars([ for (arg in args) { name:arg.name, expr:macro cast null, type:null } ]), pos:pos } ];
					exprs.push(macro unityeditor.EditorGUILayout.BeginHorizontal(null));
					exprs.push(macro unityeditor.EditorGUILayout.Space());
					exprs.push(macro unityeditor.EditorGUILayout.BeginVertical(null));
					exprs.push({ expr:ESwitch(
						macro current,
						[{
							values:[{ expr:ECall(macro $i{name}, [ for (arg in args) macro $i{arg.name + "_arg"} ]), pos:pos }],
							expr: { expr:EBlock([ for (arg in args) macro $i{arg.name} = $i{arg.name + "_arg" } ]), pos: pos }
						}],
						macro null),
					pos: pos });
					exprs.push( { expr:EVars([ for (arg in args) { name:arg.name + "__changed", expr:macro $i{arg.name}, type:null } ]), pos:pos } );
					for (arg in args)
					{
						var ret = inspectorCall( (macro $i{arg.name + "__changed"}), {
							name: arg.name,
							type: arg.t,
							isPublic: true,
							params: [],
							meta: null,
							kind: FVar(AccNormal,AccNever),
							expr: null,
							pos: ctor.pos,
							doc: docs['arg-' + arg.name]
						},[]);
						if (ret != null)
							exprs.push(ret);
					};
					exprs.push(macro unityeditor.EditorGUILayout.EndVertical());
					exprs.push(macro unityeditor.EditorGUILayout.EndHorizontal());
					var cond = macro popup != $v{i};
					for (arg in args)
						cond = macro $cond || !std.Type.enumEq($i{arg.name}, $i{arg.name + "__changed"});
					exprs.push(
							macro if ($cond)
								return ${ { expr:ECall(parse( etype.toString() + '.' + name, pos ), [ for (arg in args) macro $i{arg.name+"__changed"} ]), pos:pos } };
							else
								return current
					);
					cases.push( { values:[macro $v{i}], expr: { expr:EBlock(exprs), pos:pos }, guard:null } );
				case _:
					throw "assert";
			}
		}
		var eswitch = { expr:ESwitch(macro p2, cases, macro return null), pos: pos };
		var expr = macro {
			var popup = current == null ? 0 : std.Type.enumIndex(current) + 1;
			var guiContent = ${nativeArray(guiContent,pos)};
			var values = ${nativeArray(values,pos)};
			var p2 = unityeditor.EditorGUILayout.IntPopup( label, popup, guiContent, values, opts );
			$eswitch;
			return null;
		};

		var target = e.module.split('.').join('/') + ".hx";
		for (path in getClassPath())
		{
			if (exists(path + "/" + target))
			{
				registerModuleDependency(getLocalModule(), path + "/" + target);
				break;
			}
		}

		var td = macro class { public static function editorHelper( current:Null<$etype>, label:unityengine.GUIContent, opts:cs.NativeArray<unityengine.GUILayoutOption> ) : Null<$etype> $expr; };
		return td.fields;
	}

	private static function ensureEnumHelper(e:EnumType, type:Type, pos:Position):Expr
	{
		if (e.params.length > 0)
			throw new Error("Enum with type parameters is currently unsupported",pos);
		var tname = e.pack.join('.') + (e.pack.length == 0 ? "" : ".") + e.name;

		var t = try getType(tname + "_Helper__") catch(e:Dynamic) null;
		if (t == null)
		{
			var td = macro class { };
			switch macro @:build(unihx.inspector.Macro.buildEnumHelper($v{e.module}, $v{e.name})) "" {
				case { expr: EMeta(m,_) }:
					td.meta = [m];
				default: throw "assert";
			}
			td.name = e.name + "_Helper__";
			td.pack = e.pack;
			try {
				defineType(td);
			} catch(e:Dynamic) { trace(e); }
		}
		return parse( tname + "_Helper__", pos );
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
				// buf.addChar( chr - ('A'.code - 'a'.code) );
				buf.addChar(chr);
				first = true;
			} else {
				if (first)
					buf.addChar( chr - ('a'.code - 'A'.code) );
				else
					buf.addChar(chr);
				first = false;
			}
		}

		return buf.toString();
	}
#end

#if false
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
	private static function getDefault(t:Null<ComplexType>, pos:Position):Expr
	{
		switch (t)
		{
			case TAnonymous(fields):
				var objDecl = [];
				for (f in fields)
				{
					switch f.kind {
						case FVar(_,null):
							objDecl.push({ field:f.name, expr: macro @:pos(f.pos) cast null });
						case FVar(t,e):
							objDecl.push({ field:f.name, expr: e });
							f.kind = FVar(t,null);
						case _:
					}
				}
				return { expr:EObjectDecl(objDecl), pos:pos };
			case TPath({ name:"Fold", pack:[], params:[TPType(p)] } | { name:"Fold", pack:["unihx","inspector"], params:[TPType(p)] }):
				var d = getDefault(p,pos);
				if (d == null) d = macro null;
				return macro new unihx.inspector.Fold($d);
			case null | _:
				return null;
		}
	}

	public static function build(fieldName:Null<String>):Array<Field>
	{
    if (defined('display'))
      return null;
		var fields = getBuildFields(),
				pos = currentPos();
		var addedFields = [];
		var ctorAdded = [],
				ctor = null;

		for (f in fields)
		{
			switch f.kind {
				case FVar(t,e):
					if (!f.meta.exists(function(v) return v.name == ":skip") && f.access.has(APublic))
						addedFields.push(f);
					if (e == null)
					{
						e = getDefault(t, f.pos);
					}

					if (e != null)
					{
						var ethis = { expr: EField(macro this, f.name), pos:f.pos };
						ctorAdded.push(macro $ethis = $e);
						f.kind = FVar(t,null);
					}
				case FProp(get,set,t,e):
					if (!f.meta.exists(function(v) return v.name == ":skip") && f.access.has(APublic))
						addedFields.push(f);
					if (e != null)
					{
						var ethis = { expr: EField(macro this, f.name), pos:f.pos };
						ctorAdded.push(macro $ethis = $e);
						f.kind = FProp(get,set,t,null);
					}
				case _:
			}
		}

		function filter(f:Field)
		{
			switch (f.kind)
			{
				case FVar(t,_) | FProp(_,_,t,_):
					var t = t.toType();
					if (t != null) switch (t.follow())
					{
						case TAbstract(_.get() => { pack:[], name:"Void" },_):
							return false;
						case _:
							return true;
					}
				case _:
			}
			return true;
		}

		var f2 = fields.filter(filter);
		var i = 0;
		for (f in addedFields)
			if (f.name == "_")
				f.name = "_" + i++;

		if (haxe.macro.Context.defined('cs'))
		{
			if (fields.exists(function (cf) return cf.name == fieldName))
			{
				if (ctorAdded.length == 0 && f2.length == fields.length)
					return null;
			} else {
				switch ComplexType.TAnonymous(addedFields).toType() {
					case TAnonymous(_.get() => f):
						var complex = getLocalType().toComplexType();
						var allfields = [],
								ethis = if (fieldName == null)
									macro ( (cast this.target) : $complex);
								else
									macro this;
						var fs = [ for (f in f.fields) f.name => f ];
						for (cf in addedFields)
						{
							var ethis = { expr:EField(ethis, cf.name), pos:pos };
							var expr = exprFromType(ethis, fs[cf.name]);
							if (expr == null)
								continue;

							changePos(expr,cf.pos);
							allfields.push(expr);
						}
						var block = { expr:EBlock(allfields), pos:pos };
						var td = macro class extends unityeditor.Editor { @:overload public function OnGUI() $block; };

						if (fieldName == null)
						{
							var cl = getLocalClass().get();
							allfields.push(macro unityeditor.EditorUtility.SetDirty(this.target));
							// trace(block.toString());
							switch macro @:meta(UnityEditor.CustomEditor(typeof($i{cl.name}))) "" {
								case { expr:EMeta(m,_) }:
									td.meta = [m];
								case _: throw "assert";
							}

							if (cl.meta.has(':editMulti'))
							{
								switch macro @:meta(UnityEditor.CanEditMultipleObjects) "" {
									case { expr:EMeta(m,_) }:
										td.meta.push(m);
									case _: throw "assert";
								}
							}

							//define type
							td.name = cl.name + '_Helper__';
							td.pack = cl.pack.copy();
							td.pack.push('editor');
							td.fields[0].access.push(AOverride);
							td.fields[0].name = "OnInspectorGUI";
							f2 = f2.filter(function(f) {
								if (f.meta.exists(function(m) return m.name == ":editor"))
								{
									switch (f.kind) {
										case FFun(fun) if (fun.expr != null):
											function map(e:Expr)
											{
												switch(e.expr)
												{
													case EConst(CIdent("this")):
														return ethis;
													case EConst(CIdent(id)):
														return try getTypedExpr( typeExpr(e) ) catch(exc:Dynamic) e;
													case _:
														return e.map(map);
												}
											}
											fun.expr = map(fun.expr);
										case _:
									}
									td.fields.push(f);
									return false;
								} else {
									return true;
								}
							});
							if (cl.pack.length != 0)
							{
								cl.meta.add(':native', [macro $v{cl.name}], cl.pos);
							}
							try {
								defineType(td);
							} catch(e:Dynamic) { trace(e); }
						} else {
							td.fields[0].name = fieldName;
							f2.push(td.fields[0]);
						}
					case _: throw "assert";
				}
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
				f2.push(ctor);
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
		return f2;
	}

	private static function exprFromType(ethis:Expr, field:ClassField, ?type):Expr
	{
		if (field == null) return null;
		if (type == null) type = field.type;
		var pos = field.pos;
		var pack = null,
				name = null,
				params = null,
				etype = null;
		switch type {
			case TMono(r) if (r != null):
				exprFromType(ethis,field,r.get());

			case TMono(_) | TDynamic(_):
				// pack = []; name = "Dynamic"; params = [];
				// throw new Error('Unsupported Dynamic',pos);
				return null;
			case TEnum(e,p):
				var e = e.get();
				etype = e;
				pack = e.pack; name = e.name; params = p;
			case TInst(c,p):
				var c = c.get();
				pack = c.pack; name = c.name; params = p;
			case TAnonymous(a):
				var a = a.get();
				var fields = a.fields;
				fields.sort(function(v1,v2) return Reflect.compare(getPosInfos(v1.pos).min, getPosInfos(v2.pos).min));
				var arr = [];
				for (cf in fields)
				{
					var e =  exprFromType({ expr:EField(ethis, cf.name), pos:cf.pos },cf, cf.type);
					if (e != null)
						arr.push(e);
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
			// macro $v{label};
			macro new unityengine.GUIContent($v{label});
		} else {
			macro new unityengine.GUIContent($v{label}, $v{tooltip});
		}

		var opts = field.doc == null ? null : nativeArray(getOptions(docs, field.pos), pos);
		if (opts == null)
			opts = macro null;
			// opts = macro new cs.NativeArray(0);

		switch name {
			case _ if (field.type.unify( getType("unityengine.Object") )):
				var allowSceneObjects = parseBool(docs['scene-objects']),
						type = parse(pack.join(".") + (pack.length == 0 ? name : "." + name),pos);
				if (allowSceneObjects == null)
					allowSceneObjects = false;
				return macro $ethis = cast unityeditor.EditorGUILayout.ObjectField($guiContent, $ethis, cs.Lib.toNativeType($type), $v{allowSceneObjects}, $opts);
			case _ if (field.type.unify( getType('unihx.inspector.InspectorBuild') )):
				return macro if (ethis != null) $ethis.OnGUI();
			case _ if (etype != null):
				return macro $ethis = ${exprFromEnum(ethis, etype, type, guiContent, opts)};
			case _:
				return null;
		}
	}

#end
#end
}
