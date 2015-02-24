package unihx.pvt.macros;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context.*;
import sys.FileSystem.*;

using haxe.macro.Tools;
using StringTools;
using Lambda;

class DefaultValues
{
	/**
		Takes all default values from variables and sets them at constructor if needed
		If the fields' type is null, and no default value is made and `forceDefault` is true, a default non-null value is added

		Returns null if no changes are made
	**/
	public static function defaultValues(fields:Array<Field>, forceDefault:Bool):Null<Array<Field>>
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
						e = getDefault(t, f.pos, forceDefault);
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
						e = getDefault(t, f.pos, forceDefault);
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

	public static function getDefault(t:ComplexType, pos:Position, forceExpr=false):Null<Expr>
	{
		switch(t)
		{
			case TPath(p):
				var pack = p.pack, name = p.name;
				if (pack.length == 0 && name == 'StdTypes')
					name = p.sub;
				switch [pack, name]
				{
					case [ [], 'Int' | 'Float' | 'Single' ] if (forceExpr && !defined('static')):
						return macro @:pos(pos) 0;
					case [ [], 'Array' ] if (forceExpr):
						return macro @:pos(pos) [];
					case [ [], 'Bool'] if (forceExpr && !defined('static')):
						return macro @:pos(pos) false;
					case [ [], 'Null'] if (forceExpr):
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
						{ field: f.name, expr: isNull(e) ? getDefault(t,f.pos,true) : e };
					case FProp(get,set,t,e):
						{ field: f.name, expr: isNull(e) ? getDefault(t,f.pos,true) : e };
					case _:
						{ field: f.name, expr: macro cast null };
				} ]), pos:pos };
			case TFunction(_,_), TParent(_), TOptional(_):
				return forceExpr ? macro @:pos(pos) cast null : null;
		}
	}

	private static function isNull(e:Expr)
	{
		return e == null || switch(e.expr) {
			case EConst(CIdent('null')): true;
			case _: false;
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

}
