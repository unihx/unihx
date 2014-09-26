package unihx._internal;
import haxe.macro.Expr;
import haxe.macro.Context.*;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.TypedExprTools;
using Lambda;
using StringTools;

class YieldGenerator
{
	static var packs = new Map();
	var expr:TypedExpr;
	var usedVars:Map<Int, Map<FlowGraph,FlowGraph>>;

	// control flow graph
	var id = -1;
	var cfgs:Array<FlowGraph>;
	var current:FlowGraph;

	var tbool:Type;
	var tint:Type;
	var tdynamic:Type;

	var goto:TypedExpr;
	var gotoEnd:TypedExpr;
	var pos:Position;

	var pack:String;
	var condGraph:Null<Int>;

	var onBreak:TypedExpr;
	var onContinue:TypedExpr;

	public function new(pack:String, e:Expr)
	{
		var expr = typeExpr(macro { var __yield__:Dynamic = null; ${prepare(e)}; });
		switch(expr.expr)
		{
			case TBlock(bl):
				this.expr = bl[1];
			default: throw "assert";
		}

		this.usedVars = new Map();
		this.cfgs = [];
		newFlow();
		this.current = cfgs[0];

		this.tbool = getType("Bool");
		this.tint = getType("Int");
		this.tdynamic = getType("Dynamic");

		this.goto = typeExpr( macro untyped __goto__ );
		this.gotoEnd = typeExpr( macro untyped __goto_end__ );
		this.pos = currentPos();

		this.pack = pack;
	}

	static function prepare(e:Expr):Expr
	{
		return switch(e) {
			case macro for ($v in $iterator) $block:
				var vname = switch(v.expr) {
					case EConst(CIdent(i)):
						i;
					case _: throw new Error('Identifier expected in for var declaration', v.pos);
				};
				return macro { var y_iterator = unihx._internal.Yield.getIterator($iterator); while (y_iterator.hasNext()) { var $vname = y_iterator.next(); ${prepare(block)} } };
			case macro __yield__:
				throw new Error("Reserved variable name: __yield__", e.pos);
			case macro @yield $something:
				return macro __yield__(${prepare(something)});
			case _:
				return e.map(prepare);
		}
	}

	public static function make(pack,e:Expr):Expr
	{
		return new YieldGenerator(pack,e).change();
	}

	public static function getIterator(e:Expr):Expr
	{
		var t = typeof(e);
		switch (t.follow())
		{
			case TAnonymous(a):
				if (a.get().fields.exists(function(cf) return cf.name == "hasNext" || cf.name == "next"))
					return e;
				else
					return macro $e.iterator();
			case TInst(t,_):
				if (t.get().findField('iterator') != null)
					return macro $e.iterator();
				else
					return e;
			case _:
				throw new Error('This expression has type $t, but an Iterable or Iterator was expected', e.pos);
		}
	}

	inline function newFlow()
	{
		var ret = { block:[], tryctx: current == null ? null : current.tryctx, id: ++id, next: null };
		cfgs.push(ret);
		current = ret;
	}

	inline function setUsed(id:Int)
	{
		var ret =usedVars[id];
		if (ret == null)
		{
			usedVars[id] = ret = new Map();
		}
		ret[current] = current;
	}

	function ensureNoYield(e:TypedExpr)
	{
		switch (e.expr)
		{
			case TCall( { expr:TLocal({ name:"__yield__" }) }, [e]):
				throw new Error('A @yield cannot be used as an expression', e.pos);
			case TLocal(v) | TVar(v,_):
				setUsed(v.id);
				e.iter(ensureNoYield);
			case TReturn(_):
				throw new Error("Cannot return inside a 'yield' context", e.pos);
			case _:
				e.iter(ensureNoYield);
		}
	}

	function hasYield(e:TypedExpr)
	{
		var has = false;
		function iter(e:TypedExpr)
		{
			switch (e.expr)
			{
				case TCall( { expr:TLocal({ name:"__yield__" }) }, [e]):
					has = true;
				case _:
					if (!has) e.iter(iter);
			}
		}
		iter(e);
		return has;
	}

	function mkGoto(id:Int,final:Bool):TypedExpr
	{
		return { expr: TCall(goto, [{ expr:TConst(TInt(id)), t:tint, pos:pos }, { expr:TConst(TBool(final)), t:tbool, pos:pos }]), t:tdynamic, pos:pos };
	}

	function mkGotoEnd(id:Int,final:Bool):TypedExpr
	{
		return { expr: TCall(gotoEnd, [{ expr:TConst(TInt(id)), t:tint, pos:pos }, { expr:TConst(TBool(final)), t:tbool, pos:pos }]), t:tdynamic, pos:pos };
	}

	function mkNothing():TypedExpr
	{
		return { expr: TBlock([]), t:tdynamic, pos:pos };
	}

	static function replace(from:TypedExpr, to:TypedExpr):Void
	{
		from.expr = to.expr;
		from.t = to.t;
		from.pos = to.pos;
	}

	function iter(e:TypedExpr)
	{
		switch(e.expr)
		{
			case TVar(v,_) | TLocal(v):
				setUsed(v.id);
				current.block.push(e);
			case TFunction(f):
				ensureNoYield(e);
				current.block.push(e);
			case TBlock(el):
				for (e in el)
					iter(e);
			case TIf(econd,eif,eelse):
				ensureNoYield(econd);
				var yieldIf = hasYield(eif),
						yieldElse = eelse != null && hasYield(eelse);
				if (yieldIf || yieldElse)
				{
					// invert if and else  - if necessary
					if (yieldIf && !yieldElse && eelse != null)
					{
						econd = mk_not(econd);
						var tmp = eelse;
						eelse = eif;
						eif = tmp;

						yieldIf = false;
						yieldElse = true;
					}
					// if (!cond) goto else;
					var gotoElse = mkNothing();
					current.block.push({ expr: TIf(mk_not(econd),gotoElse,null), t: tdynamic, pos: econd.pos });

					// otherwise continue on eif
					iter(eif);
					var endIfBlock = current;
					// starting else
					newFlow();
					replace(gotoElse, mkGoto(current.id, true));

					// make else block
					if (eelse != null)
					{
						iter(eelse);
					}
					newFlow();

					endIfBlock.next = current.id;
				} else {
					ensureNoYield(eif);
					if (eelse != null)
						ensureNoYield(eelse);
					current.block.push(e);
				}

			case TWhile(econd, block, normalWhile) if(hasYield(block)):
				ensureNoYield(econd);

				var prelude = null;
				if (!normalWhile)
				{
					newFlow();
					prelude = current;
				}
				newFlow();
				var lastOnBreak = onBreak,
						lastOnContinue = onContinue;
				onBreak = mkNothing();
				onContinue = mkNothing();

				// while condition
				var condCfg = current;
				var changedCond = { expr: TIf( mk_not(econd), onBreak, null ), t: tdynamic, pos:econd.pos };
				iter(changedCond);

				//body
				newFlow();
				var bodyCfg = current;
				if (prelude != null)
					prelude.next = bodyCfg.id;
				iter(block);
				current.next = condCfg.id;
				newFlow();

				//returning last loop
				replace(onBreak,mkGoto(current.id,true));
				replace(onContinue,mkGoto(condCfg.id,true));
				trace(onBreak.toString());
				this.onBreak = lastOnBreak;
				this.onContinue = lastOnContinue;

			case TBreak:
				if (this.onBreak == null) throw new Error("Break outside loop",e.pos);
				current.block.push(onBreak);
			case TContinue:
				if (this.onContinue == null) throw new Error("Continue outside loop",e.pos);
				current.block.push(onContinue);

			case TFor(_,_,_): throw new Error("Unexpected for",e.pos);
			case TCall( { expr:TLocal({ name:"__yield__" }) }, [ev]):
				// return value
				ensureNoYield(ev);
				current.block.push( mk_assign( mk_this('value', ev.t, e.pos), ev, e.pos) );
				current.block.push( mkGotoEnd( current.id, false ) );
				// set to next
				current.block.push( { expr: TReturn( { expr:TConst(TBool(true)), t:tbool, pos:e.pos } ), t:tbool, pos:e.pos } );
				// break flow
				newFlow();
			case TReturn(_):
				throw new Error("Cannot return inside a 'yield' context", e.pos);

			case _:
				ensureNoYield(e);
				current.block.push(e);
		}
	}

	public function change():Expr
	{
		// create the control flow graph
		iter(expr);
		var used = new Map();
		{
			// get used vars - canonically
			for (k in usedVars.keys())
			{
				var cur = new Map();
				used[k] = cur;
				for (cfg in usedVars[k])
				{
					var cfg = cfg;
					cur[cfg.id] = true;
				}
			}
		}
		// get the variables that need to be changed
		var changed = new Map(),
				used = [ for (k in used.keys()) k => this.usedVars.get(k).count() ];
		var external = [ for (ext in getLocalTVars()) ext.id => ext ];
		for (ext in external)
			used[ext.id] = 2; //mark as used
		function mapVars(e:TypedExpr):TypedExpr
		{
			return switch (e.expr) {
				case TLocal(v) if (used.get(v.id) > 1):
					changed[v.id] = v;
					mk_this(v.name + "__" + v.id, v.t ,e.pos);
				case TLocal(v):
					e;
				case TVar(v,eset) if (used.get(v.id) > 1):
					changed[v.id] = v;
					mk_assign( mk_this(v.name + "__" + v.id, v.t, e.pos), eset == null ? { expr: TConst(TNull), t:tdynamic, pos:e.pos } : mapVars(eset), e.pos);
				case _:
					e.map(mapVars);
			}
		}
		trace(changed,used);
		// create cases function
		var ecases = [],
				acc = [];
		for (cfg in cfgs)
		{
			acc.push({ expr:EConst(CInt(cfg.id + "")), pos:pos });
			if (cfg.block.length == 0 && cfg.next == null)
				continue;
			//TODO tryctx
			var expr = getExprFromCg(cfg, cfg.block.map(mapVars));
			ecases.push({ values:acc, expr: expr });
			acc = [];
		}
		var eswitch = { expr:ESwitch(macro this.eip, ecases, macro return false), pos:pos };
		trace(eswitch.toString());

		eswitch = macro while(true) $eswitch;

		var extChanged = [ for (ext in external) if (changed.exists(ext.id)) ext ];
		//create new() function
		var nf = {
			name: "new",
			kind: FFun({
				args: [ for (arg in extChanged) { name: arg.name, type: arg.t.toComplexType() } ],
				ret: null,
				expr: { expr:EBlock([ for (arg in extChanged) { var name = arg.name + "__" + arg.id; macro this.$name = $i{arg.name}; } ]), pos:pos }
			}),
			pos: pos
		};

		//create all changed fields
		var clsnum = packs.get(pack);
		if (clsnum == null)
		{
			clsnum = 0;
		}
		packs[pack] = clsnum + 1;
		var pack = pack.split('.'),
				name = "__Yield_" + clsnum;

		var cls = macro class extends unihx._internal.YieldBase {
			override public function MoveNext():Bool
				$eswitch;
		};
		cls.fields.push(nf);
		for (changed in changed)
		{
			cls.fields.push({
				name:changed.name +"__" + changed.id,
				kind: FVar(changed.t.toComplexType(),null),
				pos: pos
			});
		}
		cls.name = name;
		cls.pack = pack;
		defineType(cls);
		return { expr:ENew({ pack:pack, name: name }, [ for (arg in extChanged) macro $i{arg.name} ]), pos:pos };
	}

	function getExprFromCg(cfg:FlowGraph, exprs:Array<TypedExpr>):Expr
	{
		if (exprs.length == 0)
		{
			exprs = [mkGotoEnd(cfg.id,false)];
		} else switch (exprs[exprs.length-1].expr) {
			case TReturn(_):
			case TCall( { expr: TLocal(v) }, [_]) if (v.name.startsWith("__goto_")):
			case _:
				exprs.push(mkGotoEnd(cfg.id, false));
		}
		var ret = getTypedExpr(mk_block(exprs));
		function map(e:Expr):Expr
		{
			return switch (e) {
				case macro __goto__($i, false):
					// we can avoid this call if i == next
					macro this.eip = $i ;
				case macro __goto_end__($i, false):
					switch (i.expr)
					{
						case EConst(CInt(i)):
							var i = Std.parseInt(i);
							var theBlock = cfgs[i];
							if (theBlock.next == null)
								i = theBlock.id + 1;
							else
								i = theBlock.next;
							macro this.eip = $v{i};
						case _: throw "assert";
					}
				case macro __goto__($i, true):
					// we can avoid this call if i == next
					macro {this.eip = $i; continue; }
				case macro __goto_end__($i, true):
					switch (i.expr)
					{
						case EConst(CInt(i)):
							var i = Std.parseInt(i);
							var theBlock = cfgs[i];
							if (theBlock.next == null)
								i = theBlock.id + 1;
							else
								i = theBlock.next;
							macro {this.eip = $v{i}; continue; };
						case _: throw "assert";
					}
				case _:
					e.map(map);
			}
		}
		return map(ret);
	}

	function mk_assign(e1:TypedExpr, e2:TypedExpr, pos:Position):TypedExpr
	{
		return { expr: TBinop(OpAssign, e1, e2), t: e1.t, pos:pos };
	}

	function mk_this(name:String, t:Type, pos:Position):TypedExpr
	{
		return { expr: TField({ expr:TConst(TThis), t:tdynamic, pos:pos }, FDynamic(name)), t: t, pos:pos };
	}

	static function mk_paren(e:TypedExpr):TypedExpr
	{
		return { expr: TParenthesis(e), t: e.t, pos: e.pos };
	}

	function mk_not(e:TypedExpr):TypedExpr
	{
		return switch(e.expr) {
			case TUnop(OpNot, false, e):
				e;
			case _:
				{ expr: TUnop(OpNot, false, mk_paren(e)), t: tbool, pos: e.pos };
		}
	}

	function mk_block(el:Array<TypedExpr>):TypedExpr
	{
		return { expr: TBlock(el), t: tdynamic, pos: el.length > 0 ? el[0].pos : pos };
	}
}

typedef FlowGraph = { block:Array<TypedExpr>, tryctx:Null<Int>, next:Null<Int>, id:Int };
