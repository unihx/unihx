package unihx.pvt.macros;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context.*;
import sys.FileSystem.*;

using haxe.macro.Tools;
using StringTools;
using Lambda;

class InspectorMacro
{
	public static function createInspectorIfNeeded(fields:Array<Field>, cl:Ref<ClassType>)
	{
		var cl2 = cl.get();
		var isUnity = TInst(cl, [ for (tp in cl2.params) getType('Dynamic') ]).unify(getType('unityengine.Object'));
		if (!isUnity) return;
		//check if there is any type that may need
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

		var dv = DefaultValues.defaultValues(fields, true);
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

		var ic = new InspectorCall();
		ic.getOrdersFrom(ComplexType.TAnonymous(toRun));
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
					exprs.push(ic.run(ethis,f,fields));
				}
				var expr = { expr:EBlock(exprs), pos: currentPos() };
				var field = (macro class { @:overload public function OnGUI() $expr; }).fields[0];
				if (fieldName != null) field.name = fieldName;
				fields.push(field);
			case _:
		}

		return fields;
	}

	private static function inspectorCall(ethis:Expr, field:ClassField, buildFields:Array<Field>):Expr
	{
		return new InspectorCall().run(ethis,field,buildFields);
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
			var docs = ctor.doc != null ? [ for (c in InspectorCall.parseComments(ctor.doc)) (c.tag == null ? "" : c.tag.trim() == "arg" ? c.tag.trim() + "-" + c.contents.trim().split(' ')[0] : c.tag.trim()) => c.contents.trim() ] : new Map();

			var label = docs.get('label');
			if (label == null)
				label = InspectorCall.toSep(ctor.name, ' '.code);
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
			var guiContent = ${InspectorCall.nativeArray(guiContent,pos)};
			var values = ${InspectorCall.nativeArray(values,pos)};
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

	private static function type(c:ComplexType, pos:Position):Type
	{
		return typeof( { expr:ECheckType(macro cast null, c), pos:pos } );
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
#end
}

#if macro
class InspectorCall
{
	var block:Array<Expr>;
	var ethis:Expr;
	var efield:Expr;
	var buildFields:Array<Field>;
	// var type:Type;

	@:isVar var field(default,set):ClassField;
	var docs:Map<String,String>;
	var guiContent:Expr;
	var opts:Expr;

	var fieldsOrder:Map<String,Array<String>>;

	public function new()
	{
		this.block = [];
		fieldsOrder = new Map();
	}

	public function getOrdersFrom(ct:ComplexType)
	{
		switch (ct)
		{
			case TPath(p):
				if (p.params != null) for (p in p.params)
				{
					switch (p)
					{
						case TPType(c):
							getOrdersFrom(c);
						case _:
					}
				}
			case TFunction(args,ret):
				for(arg in args) getOrdersFrom(arg);getOrdersFrom(ret);
			case TAnonymous(fields) | TExtend(_,fields):
				for (f in fields)
				{
					switch(f.kind)
					{
						case FVar(t,_):
							if (t != null)
								getOrdersFrom(t);
						case FProp(get,set,t,_):
							if (t != null)
								getOrdersFrom(t);
						case _:
					}
				}
				var rfields = [ for (f in fields) f.name ];
				var name = { var tmp = rfields.copy(); tmp.sort(Reflect.compare); tmp.join('$'); };
				fieldsOrder[name] = rfields;
			case TParent(t):
				getOrdersFrom(t);
			case TOptional(t):
				getOrdersFrom(t);
		}
	}

	public function run(ethis:Expr, field:ClassField, buildFields:Array<Field>):Expr
	{
		this.ethis = ethis;
		this.efield = { expr:EField(ethis,field.name), pos: field.pos };
		this.field = field;
		this.buildFields = buildFields;
		handleType(field.type);
		var b = block;
		block = [];
		var ret = { expr:EBlock(b), pos:field.pos };
		// trace(ret.toString());
		return ret;
	}

	private function recurseExpr(ethis:Expr, efield:Expr, field:ClassField, type:Type)
	{
		var lethis = this.ethis,
				lefield = this.efield,
				lfield = this.field;
		this.ethis = ethis;
		this.efield = efield;
		if (field != this.field)
			this.field = field;
		var lblock = block;
		this.block = [];

		handleType(type);

		var ret = { expr:EBlock(block), pos: field.pos };
		this.block = lblock;
		this.ethis = lethis;
		this.efield = lefield;
		this.field = lfield;
		// trace(ret.toString());
		return ret;
	}

	private function handleType(type:Type) while (true)
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
				var lastEThis = ethis,
						lastEField = efield,
						lastField = field;
				// ethis = { expr: EField(lastEThis, field.name), pos:lastEThis.pos };
				ethis = efield;
				var fnames = [ for (f in fields) f.name ];
				fnames.sort(Reflect.compare);
				var name = fnames.join("$");
				var fnamesOrder = this.fieldsOrder[name];
				if (fnamesOrder != null)
					fnames = fnamesOrder;
				var fields = [ for (f in fields) f.name => f ];
				for (fname in fnames)
				{
					var f = fields[fname];
					efield = { expr: EField(ethis, f.name), pos:ethis.pos };
					field = f;
					handleType(f.type);
				}
				ethis = lastEThis;
				efield = lastEField;
				field = null;
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
			// basic types
			case [[], 'String']:
				block.push(macro $efield = unityeditor.EditorGUILayout.TextField($guiContent, $efield, $opts));
			case [[], 'Int']:
				block.push(macro $efield = unityeditor.EditorGUILayout.IntField($guiContent, $efield, $opts));
			case [[], 'Bool']:
				block.push(macro $efield = unityeditor.EditorGUILayout.Toggle($guiContent, $efield, $opts));
			case [[], ('Float' | 'Single')]:
				block.push(macro $efield = unityeditor.EditorGUILayout.FloatField($guiContent, $efield, $opts));
			case [[], 'Array']:
				buildFields.push({
					name: field.name + "_is_folded",
					kind: FVar(TPath({ name:'Bool',pack:[] }),null),
					pos: field.pos
				});
				var content = guiContent;
				guiContent = macro label;
				var element = recurseExpr(ethis, { expr:EArray(efield, macro i), pos:efield.pos }, field, params[0]);
				var def = DefaultValues.getDefault(params[0].toComplexType(), efield.pos);
				var defExpr = def == null ? macro {} : macro for (i in 0...len) { if ($efield[i] == cast null) $efield[i] = $def; };
				var doLabelBeg = macro {}, doLabelEnd = macro {};
				switch (params[0].follow()) {
					case TAnonymous(_):
						doLabelBeg = macro {
							unityeditor.EditorGUILayout.LabelField(label,null);
							unityeditor.EditorGUI.indentLevel++;
						};
						doLabelEnd = macro unityeditor.EditorGUI.indentLevel--;
					case _:
				}
				var efield_folded = { expr:EField(ethis,field.name + '_is_folded'), pos:field.pos };
				block.push(macro {
					if ($efield_folded = unityeditor.EditorGUILayout.Foldout($efield_folded, $guiContent))
					{
						unityeditor.EditorGUI.indentLevel++;
						var len = unityeditor.EditorGUILayout.IntField('Size', $efield.length, $opts);
						if (len != $efield.length)
						{
							$efield = $efield.slice(0,len);
							$defExpr;
						}
						for (i in 0...len)
						{
							var label = 'Element ' + i;
							$doLabelBeg;
							$element;
							$doLabelEnd;
						}
						unityeditor.EditorGUI.indentLevel--;
					}
				});
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
			// inspector types
			case [['unihx','inspector'],'Fold']:
				buildFields.push({
					name: field.name + "_is_folded",
					kind: FVar(TPath({ name:'Bool',pack:[] }),null),
					pos: field.pos
				});
				var all = recurseExpr(ethis, efield, field, params[0]);
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
			case [['unihx','inspector'],'DirPath' | 'FilePath']:
				var funcName = null, sndArg = null;
				if (name == 'DirPath')
				{
					funcName = 'OpenFolderPanel';
				} else {
					funcName = 'OpenFilePanel';
					sndArg = docs.get('filter');
				}
				if (sndArg == null) sndArg = '';

				block.push(macro unityeditor.EditorGUILayout.BeginHorizontal(null));
				var title = docs.get('label');
				if (title == null)
					title = toSep(field.name, ' '.code);
				block.push(macro
						unityeditor.EditorGUILayout.PrefixLabel($guiContent,
							untyped "Button"
				));

				var tooltip = docs[''];
				var btnGuiContent = if (tooltip == null)
					macro new unityengine.GUIContent("<" + $efield + ">");
				else
					macro new unityengine.GUIContent("<" + $efield + ">", $v{tooltip});

				block.push(macro {
					var rect = unityengine.GUILayoutUtility.GetRect(new unityengine.GUIContent(""), untyped "Button");
					if (unityengine.GUI.Button(rect,$btnGuiContent))
					{
						$efield = unityeditor.EditorUtility.$funcName($v{title}, $efield, $v{sndArg});
					}
				});
				block.push(macro unityeditor.EditorGUILayout.EndHorizontal());
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

	private function set_field(field:ClassField):ClassField
	{
		if (field == null)
			return this.field = null;

		docs = field != null && field.doc != null ? [ for (c in parseComments(field.doc)) (c.tag == null ? "" : c.tag.trim()) => c.contents.trim() ] : new Map();
		guiContent =
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
		opts =
		{
			var opts = field.doc == null ? null : nativeArray(getOptions(docs, field.pos), field.pos);
			if (opts == null)
				opts = macro null;
			opts;
		}

		return this.field = field;
	}


	/// helpers
	public static function exprFromEnum(ethis:Expr, e:EnumType, t:Type, label, opts):Expr
	{
		//ensure created helper class
		var tname = ensureEnumHelper(e,t,ethis.pos);
		return macro $tname.editorHelper($ethis, $label, $opts);
	}

	static var helpers:Map<String,Bool> = new Map();
	static function __init__()
	{
		haxe.macro.Context.onMacroContextReused(function() {
			helpers = new Map();
			return true;
		});
	}

	private static function ensureEnumHelper(e:EnumType, type:Type, pos:Position):Expr
	{
		if (e.params.length > 0)
			throw new Error("Enum with type parameters is currently unsupported",pos);
		var tname = e.pack.join('.') + (e.pack.length == 0 ? "" : ".") + e.name;

		// var t = getType(tname + "_Helper__");
		if (!helpers.exists(tname))
		{
			helpers[tname] = true;
			var td = macro class { };
			switch macro @:build(unihx.pvt.macros.InspectorMacro.buildEnumHelper($v{e.module}, $v{e.name})) "" {
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

	public static function nativeArray(arr:Array<Expr>,pos:Position):Expr
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
				// buf.addChar( chr - ('A'.code - 'a'.code) );
				buf.addChar(chr);
				first = true;
			} else {
				if (i == 0)
					buf.addChar( chr - ('a'.code - 'A'.code) );
				else
					buf.addChar(chr);
				first = false;
			}
		}

		return buf.toString();
	}

}
