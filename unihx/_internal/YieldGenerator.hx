package unihx._internal;
import haxe.macro.Expr;
import haxe.macro.Context.*;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.TypedExprTools;
using haxe.macro.ComplexTypeTools;
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
	var exc:TypedExpr;
	var pos:Position;

	var pack:String;
	var condGraph:Null<Int>;

	var onBreak:TypedExpr;
	var onContinue:TypedExpr;
	var catchStack:Array<Array<{ t:Type, gotoHandler:TypedExpr }>>;
	var bakedCatchStack:Array<{ t:Type, gotoHandler:TypedExpr }>;

	var rethrow:Expr;

	var thisUsed:Bool = false;

	public function new(pack:String, e:Expr)
	{
		var expr = typeExpr(macro { var __yield__:Dynamic = null; ${prepare(e)}; });
		switch(expr.expr)
		{
			case TBlock(bl):
				this.expr = bl[1];
			default: throw "assert";
		}

		this.catchStack = [];
		this.usedVars = new Map();
		this.cfgs = [];
		newFlow();
		this.current = cfgs[0];

		this.tbool = getType("Bool");
		this.tint = getType("Int");
		this.tdynamic = getType("Dynamic");

		this.goto = typeExpr( macro untyped __goto__ );
		this.gotoEnd = typeExpr( macro untyped __goto_end__ );
		this.exc = typeExpr( macro untyped __exc__ );
		this.pos = currentPos();

		this.pack = pack;
		this.rethrow = if (defined('cs'))
			macro cs.Lib.rethrow(exc);
		else if (defined('neko'))
			macro neko.Lib.rethrow(exc);
		else if (defined('cpp'))
			macro cpp.Lib.rethrow(exc);
		else if (defined('php'))
			macro php.Lib.rethrow(exc);
		else
			macro throw exc;
	}

	static function prepare(e:Expr):Expr
	{
		return switch(e) {
			// case macro for ($v in $iterator) $block:
			// 	var vname = switch(v.expr) {
			// 		case EConst(CIdent(i)):
			// 			i;
			// 		case _: throw new Error('Identifier expected in for var declaration', v.pos);
			// 	};
			// 	return macro { var y_iterator = unihx._internal.Yield.getIterator($iterator); while (y_iterator.hasNext()) { var $vname = y_iterator.next(); ${prepare(block)} } };
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

	private function bakeCatches()
	{
		var i = catchStack.length,
				stack = catchStack;
		var baked = this.bakedCatchStack = [];
		while (i --> 0)
		{
			var cur = stack[i];
			for (cur in cur)
			{
				var t = cur.t;
				var add = true;
				for (v in baked)
				{
					if (t.unify(v.t))
					{
						add = false;
						break;
					}
				}
				if (add)
					baked.push(cur);
			}
		}
	}

	inline function newFlow()
	{
		var ret = { block:[], tryctx:bakedCatchStack, id: ++id, next: null };
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
				throw new Error('@yield cannot be used here', e.pos);
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

	inline function mkGetExc(t:Type):TypedExpr
	{
		return { expr:TCast(exc, null), t:t, pos:pos };
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
				this.onBreak = lastOnBreak;
				this.onContinue = lastOnContinue;

			case TBreak:
				if (this.onBreak == null) throw new Error("Break outside loop",e.pos);
				current.block.push(onBreak);
			case TContinue:
				if (this.onContinue == null) throw new Error("Continue outside loop",e.pos);
				current.block.push(onContinue);

			case TSwitch(econd,ecases,edef):
				var cur = current,
						curBlock = cur.block,
						curNext = cur.next;
				ensureNoYield(econd);
				var currents = [cur];
				for (c in ecases)
				{
					current = cur;
					var bl = cur.block = [];
					cur.next = id + 1;
					for (v in c.values) ensureNoYield(v);
					iter(c.expr);
					c.expr = mk_block(bl);
					currents.push(current);
				}
				if (edef != null)
				{
					current = cur;
					var defs = cur.block = [];
					cur.next = id + 1;
					iter(edef);
					edef = mk_block(defs);
					currents.push(current);
				}
				current = cfgs[cfgs.length-1];

				cur.next = curNext;
				cur.block = curBlock;
				curBlock.push({ expr:TSwitch(econd, ecases, edef), t:e.t, pos:e.pos });
				if (cur != current)
				{
					newFlow();
					for (c in currents)
						c.next = current.id;
				}
			case TTry(etry, ecatches):
				var cur = current,
						curNext = cur.next,
						curBlock = cur.block;
				var currents = [];

				if (hasYield(etry))
				{
					var handlers = [ for (c in ecatches) { t:c.v.t, gotoHandler: mkNothing() } ];
					this.catchStack.push(handlers);
					var old = this.bakedCatchStack;
					bakeCatches();
					newFlow(); //we need a new flow since we'll change the handlers mask

					iter(etry);
					currents.push(current);
					this.catchStack.pop();
					this.bakedCatchStack = old;
					for (i in 0...ecatches.length)
					{
						var c = ecatches[i],
								handler = handlers[i];
						newFlow();
						replace(handler.gotoHandler, mkGoto(current.id, true));
						iter({ expr: TVar(c.v, mkGetExc(c.v.t)), t:tdynamic, pos:c.expr.pos });
						iter(c.expr);
						currents.push(current);
					}
				} else {
					var tryblock = cur.block = [];
					iter(etry);
					var newc = [];
					for (c in ecatches)
					{
						current = cur;
						cur.next = id + 1;
						var bl = cur.block = [];
						var newVar = alloc_var(c.v.name, c.v.t);
						iter({ expr: TVar(c.v, { expr: TLocal(newVar), t:newVar.t, pos:c.expr.pos }), t:tdynamic, pos:c.expr.pos });
						iter(c.expr);
						newc.push({ v: newVar, expr:mk_block(bl) });
						currents.push(current);
					}
					cur.block = curBlock;
					curBlock.push({ expr:TTry(mk_block(tryblock), newc), t: e.t, pos:e.pos });
					cur.next = curNext;
				}
				if (cur != current)
				{
					newFlow();
					for (c in currents)
						c.next = current.id;
				}

			case TMeta(meta,e1):
				iter(e1);

			case TFor(v,eit,eblock):
				if (hasYield(eblock))
				{
					switch (typeExpr( macro var _iterator_ ).expr) {
						case TVar(v2,_):
							v2.t = eit.t;
							iter({ expr:TVar(v2,eit), t:tdynamic, pos:eit.pos });
							var local = { expr:TLocal(v2), t:eit.t, pos:eit.pos };

							var wexpr = {
								expr:TWhile(
									{ expr:TCall( mk_field(local, 'hasNext', tdynamic), []), t:tbool, pos:eit.pos },
									{ expr:TBlock([{ expr:TVar(v, { expr:TCall( mk_field(local, 'next', tdynamic), []), t:v.t, pos:eit.pos }), t:tdynamic, pos:eit.pos }, eblock]), t:tdynamic, pos:eblock.pos },
									true),
								t: tdynamic,
								pos: e.pos };
							iter(wexpr);
						case _: throw 'assert';
					}
				} else {
					ensureNoYield(e);
					current.block.push(e);
				}

			case TCall( { expr:TLocal({ name:"__yield__" }) }, [ev]):
				// return value
				ensureNoYield(ev);
				current.block.push( { expr:TMeta({name:"yield", params:[], pos:ev.pos}, ev), t: ev.t, pos:ev.pos } );
				// current.block.push( mk_assign( mk_this('value', ev.t, e.pos), ev, e.pos) );
				if (current.next != null)
					current.block.push( mkGoto( current.next, false ) );
				else
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
		// trace(changed,used);
		// create cases function
		var ecases = [],
				acc = [];
		for (cfg in cfgs)
		{
			acc.push({ expr:EConst(CInt(cfg.id + "")), pos:pos });
			if (cfg.block.length == 0 && cfg.next == null)
				continue;
			//TODO tryctx
			var expr = getExprFromCg(cfg, used, changed);
			ecases.push({ values:acc, expr: expr });
			acc = [];
		}
		var eswitch = { expr:ESwitch(macro this.eip, ecases, macro return false), pos:pos };

		eswitch = macro try { @:privateAccess $eswitch; } catch(exc:Dynamic) { if (!this.handleError(exc)) {$rethrow; return false;} };
		// see if C#
		if (!false)
		{
			eswitch = macro while(true) $eswitch;
		}
		trace(eswitch.toString());

		var extChanged = [ for (ext in external) if (changed.exists(ext.id)) ext ];
		if (thisUsed)
		{
			var ethis = { id:-1, name:'this', t: typeof(macro this), capture:false, extra:null };
			extChanged.push(ethis);
			changed[ethis.id] = ethis;
		}
		//create new() function
		var nf = {
			name: "new",
			kind: FFun({
				args: [ for (arg in extChanged) { name: getVarName(arg), type: null } ],
				ret: null,
				expr: { expr:EBlock([ for (arg in extChanged) { var name = getVarName(arg); macro this.$name = $i{name}; } ]), pos:pos }
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
		var excHandler = getExcHandler();
		if (excHandler != null)
			cls.fields.push(excHandler);
		var pvtAcc = macro : unihx._internal.PrivateTypeAccess;
		for (changed in changed)
		{
			var t2 = toComplexType(changed.t);
			// trace(changed.name, changed.t.toString(), t2.toString());
			cls.fields.push({
				name:getVarName(changed),
				kind: FVar(t2,null),
				pos: pos
			});
		}
		cls.name = name;
		cls.pack = pack;
		defineType(cls);
		return { expr:ENew({ pack:pack, name: name }, [ for (arg in extChanged) macro $i{arg.name} ]), pos:pos };
	}

	function getExcHandler()
	{
		var all = new Map();
		var found = false;
		for (i in 0...cfgs.length)
		{
			var cfg = cfgs[i];
			if (cfg.tryctx != null)
			{
				found =true;
				var g = all[cfg.tryctx];
				if (g == null)
				{
					all[cfg.tryctx] = g = { ctx:cfg.tryctx, ids:[] };
				}
				g.ids.push(cfg.id);
			}
		}

		if (!found)
			return null;
		var used = new Map(),
				changed = new Map();
		var cases = [];
		for (ctx in all)
		{
			var ids = ctx.ids,
					ctx = ctx.ctx;
			var exprs = [];
			for (c in ctx)
			{
				var module = switch(c.t) {
					case TInst(c,_):
						exprModule(TClassDecl(c),pos);
					case TEnum(e,_):
						exprModule(TEnumDecl(e),pos);
					case TAbstract(a,_):
						exprModule(ModuleType.TAbstract(a),pos);
					case TType(t,_):
						exprModule(TTypeDecl(t),pos);
					case TDynamic(_):
						macro Dynamic;
					case _: throw 'assert: ' + c.t;
				};
				var gotoHandler = switch (c.gotoHandler.expr) {
					case TCall({ expr:TLocal({ name: "__goto__" }) }, [{ expr:TConst(TInt(i)) }, _]):
						macro { this.eip = $v{i}; return true; }
					case _:
						throw 'assert';
				};
				exprs.push(macro if(std.Std.is(exc,$module)) $gotoHandler);
			}

			cases.push({ values: [ for (v in ids) macro $v{v} ], expr: { expr:EBlock(exprs), pos:pos } });
		}
		var eswitch = { expr: ESwitch(macro this.eip, cases, null), pos:pos };
		var field = (macro class {
			override public function handleError(exc:Dynamic):Bool {
				this.exc = exc;
				$eswitch;
				this.eip = -1;
				this.exc = null;
				return false;
			}
		}).fields[0];
		return field;
	}

	function getExprFromCg(cfg:FlowGraph, used:Map<Int,Int>, changed:Map<Int,TVar>):Expr
	{
		var exprs = [ for (e in cfg.block) texprToExpr(e,used,changed) ];
		if (exprs.length == 0)
		{
			exprs = [texprToExpr(mkGotoEnd(cfg.id,true),used,changed)];
		} else switch (exprs[exprs.length-1]) {
			case macro return $_:
			case macro this.eip = $_:
			case macro continue:
			case _:
				exprs.push(texprToExpr(mkGotoEnd(cfg.id, true),used,changed));
		}
		return { expr: EBlock(exprs), pos: pos };
	}

	function mk_assign(e1:TypedExpr, e2:TypedExpr, pos:Position):TypedExpr
	{
		return { expr: TBinop(OpAssign, e1, e2), t: e1.t, pos:pos };
	}

	function mk_field(e:TypedExpr, field:String, type:Type):TypedExpr
	{
		return { expr: TField(e, FDynamic(field)), t:type, pos:e.pos };
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

	function alloc_var(name:String, t:Type):TVar
	{
		switch (typeExpr(macro var _).expr) {
			case TVar(v,_):
				v.name = name;
				v.t = t;
				return v;
			case _: throw 'assert';
		}
	}

	private function texprToExpr(e:TypedExpr, used:Map<Int,Int>, changed:Map<Int,TVar>):Expr
	{
		function map(e:TypedExpr):Expr
		{
			return switch(e.expr) {
				case TConst(TThis):
					thisUsed = true;
					return macro this.parent;
				case TMeta({name:"yield"}, v):
					return macro this.value = ${ map(v) };
				case TLocal({ name:"__exc__" }):
					return macro this.exc;
				case TLocal(v) if (used.get(v.id) > 1):
					changed[v.id] = v;
					var name = getVarName(v);
					macro @:pos(e.pos) this.$name;
				case TVar(v,eset) if (used.get(v.id) > 1):
					changed[v.id] = v;
					var name = getVarName(v);
					if (eset == null)
						macro @:pos(e.pos) this.$name = null;
					else
						macro @:pos(e.pos) this.$name = ${map(eset)};
				case TNew(c, params, el):
					var complex = switch(toComplexType( TInst(c,params) )) {
						case TPath(p):
							p;
						case _:
							throw 'assert';
					};
					{ expr: ENew( complex, [ for (e in el) map(e) ]), pos: e.pos };
				case TTypeExpr(m):
					return exprModule(m, e.pos);

				case TCall({ expr:TLocal({ name: "__goto__" }) }, [i, final]):
					switch(final.expr)
					{
						case TConst(TBool(true)):
							macro @:pos(e.pos) { this.eip = ${map(i)}; continue; };

						case TConst(TBool(false)):
							macro @:pos(e.pos) this.eip = ${map(i)};
						case _: throw new Error("Invalid goto expr", e.pos);
					}
				case TCall({ expr:TLocal({ name: "__goto_end__" }) }, [i, final]):
					var block = switch (i.expr) {
						case TConst(TInt(i)):
							cfgs[i];
						case _: throw "assert";
					};
					var i = if (block.next == null) block.id + 1; else block.next;
					switch(final.expr)
					{
						case TConst(TBool(true)):
							macro @:pos(e.pos) { this.eip = $v{i}; continue; };

						case TConst(TBool(false)):
							macro @:pos(e.pos) this.eip = $v{i};
						case _: throw new Error("Invalid goto expr", e.pos);
					}

				// conversion boilerplate
				case TConst(_):
					getTypedExpr(e);
				case TMeta({ name:":ast", params: [p] }, _):
					p;
				case TEnumParameter(e1,ef,idx):
					var params = switch(ef.type.follow()) {
						case TFun(args,_):args;
						case _: throw 'assert';
					};
					var ecase = macro $i{ef.name},
							c2 = { expr: ECall(ecase,[ for (i in 0...params.length) if (i == idx) macro val; else macro _ ]), pos:e.pos };
					@:pos(e.pos) macro switch (${map(e1)}) { case $c2: val; default: throw 'assert'; };
					// these are considered complex, so the AST is handled in TMeta(Meta.Ast)
					// throw new Error('assert', e.pos);
				case TLocal(v):
					macro @:pos(e.pos) $i{v.name};
				case TBreak:
					macro @:pos(e.pos) break;
				case TContinue:
					macro @:pos(e.pos) continue;
				case TArray(e1,e2):
					macro @:pos(e.pos) ${map(e1)}[${map(e2)}];
				case TBinop(op,e1,e2):
					{ expr: EBinop(op, map(e1), map(e2)), pos: e.pos };
				case TField(e1, fa):
					switch (fa) {
						case FInstance(_,cf) | FStatic(_,cf) | FAnon(cf) | FClosure(_,cf):
							var cf = cf.get();
							var field = { expr: EField(map(e1), cf.name), pos:e.pos };
							if (!cf.isPublic)
								macro @:pos(e.pos) $field;
							else
								field;
						case FDynamic(s):
							{ expr: EField(map(e1), s), pos:e.pos };
						case FEnum(_,ef):
							{ expr: EField(map(e1), ef.name), pos:e.pos };
					}
				case TParenthesis(e1):
					{ expr: EParenthesis(map(e1)), pos: e.pos };
				case TObjectDecl(fields):
					{ expr: EObjectDecl([ for (f in fields) { field:f.name, expr:map(f.expr) } ]), pos: e.pos };
				case TArrayDecl(el):
					{ expr: EArrayDecl([ for (e in el) map(e) ]), pos: e.pos };
				case TCall(e1, el):
					{ expr: ECall( map(e1), [ for ( e in el ) map(e) ] ), pos: e.pos };
				case TUnop(op,postFix,e1):
					{ expr: EUnop(op, postFix, map(e1)), pos:e.pos };
				case TFunction(tf):
					{ expr: EFunction(null, { args:[for (arg in tf.args) { name: arg.v.name, type:toComplexType(arg.v.t) }], ret:toComplexType(tf.t), expr:tf.expr == null ? null : map(tf.expr) }), pos:e.pos };
				case TVar(v, e1):
					{ expr: EVars([{ name: v.name, type: toComplexType(v.t), expr: e1 == null ? null : map(e1) }]), pos: e.pos };
				case TBlock(el):
					{ expr: EBlock([ for (e in el) map(e) ]), pos:e.pos };
				case TIf(econd,eif,eelse):
					{ expr: EIf(map(econd), map(eif), eelse == null ? null : map(eelse)), pos: e.pos };
				case TReturn(e1):
					{ expr: EReturn(map(e1)), pos: e.pos };
				case TThrow(e1):
					{ expr: EThrow(map(e1)), pos: e.pos };
				case TMeta(m, e1):
					{ expr: EMeta(m, map(e1)), pos: e.pos };
				case TWhile(econd,eblock,normal):
					{ expr:EWhile(map(econd),map(eblock),normal), pos:e.pos };
				case TCast(e1,_):
					var t = toComplexType(e.t);
					var e1 = map(e1);
					macro @:pos(e.pos) ( (cast $e1) : $t );
				case TFor(v,e1,e2):
					var e1 = map(e1);
					var e2 = map(e2);
					{ expr: EFor(macro $i{v.name} in $e1, e2), pos:e.pos };
				case TSwitch(econd, cases, edef):
					{ expr: ESwitch( map(econd), [ for (c in cases) { values: [ for (e in c.values) map(e) ], expr: map(c.expr) } ], edef == null ? null : map(edef) ), pos:e.pos };
				case TTry(etry, catches):
					{ expr: ETry(map(etry), [ for (c in catches) { name: c.v.name, type: toComplexType(c.v.t), expr: map(c.expr) } ]), pos: e.pos };
			}
		}
		return map(e);
	}

	private function exprModule(m:ModuleType,pos:Position):Expr
	{
		var base:BaseType = switch(m) {
			case TClassDecl(c):
				c.get();
			case TEnumDecl(e):
				e.get();
			case TTypeDecl(t):
				t.get();
			case TAbstract(a):
				a.get();
		};
		if (base.isPrivate)
		{
			// create a helper typedef
			var clsnum = packs.get(pack);
			if (clsnum == null)
				clsnum = 0;
			packs[pack] = clsnum + 1;
			var pack = pack.split('.'),
					name = base.name + "_Access_" + clsnum;
			var tparams = [for(p in base.params) tdynamic];
			var type = switch (m) {
				case TClassDecl(c):
					TInst(c,tparams);
				case TEnumDecl(e):
					TEnum(e,tparams);
				case TTypeDecl(t):
					TType(t,tparams);
				case TAbstract(a):
					TAbstract(a,tparams);
			};

			defineType({ pack:pack, name:name, pos:pos, kind: TDAlias( toComplexType(type) ), fields:[] });
			if (pack.length == 0)
				return macro @:pos(pos) $i{name};
			var expr = macro @:pos(pos) $i{pack[0]};
			for (i in 1...pack.length)
			{
				var p = pack[i];
				expr = macro @:pos(pos) $expr.$p;
			}
			expr = macro @:pos(pos) $expr.$name;
			return expr;
		} else {
			return getTypedExpr({ expr: TTypeExpr(m), t:tdynamic, pos:pos });
		}
	}

	private static function toComplexType(t:Type):ComplexType
	{
		// we need this function because there are some types that aren't compatible with toComplexType
		// for example, TMonos and private types
		// For TMonos, we'll transform them into Dynamic; For private types, we'll use unihx._internal.PrivateTypeAccess
		var params = null;
		var base:BaseType = switch (t.follow()) {
			case TInst(c,p):
				params = p;
				c.get();
			case TEnum(c,p):
				params = p;
				c.get();
			case TAbstract(c,p):
				params = p;
				c.get();
			case TMono(_):
				return macro : Dynamic;
			case _:
				null;
		}
		return if (base != null && base.isPrivate)
		{
			// use PrivateTypeAccess
			var t = base.module,
					name = base.name;
			var pvtAcc = macro : unihx._internal.PrivateTypeAccess;
			switch (pvtAcc) {
				case TPath(p):
					p.params = [TPExpr( macro $v{t} ), TPExpr( macro $v{name} )];
					for (param in params)
					{
						p.params.push(TPType( toComplexType(param) ));
					}
				case _: throw "assert";
			}
			pvtAcc;
		} else {
			t.toComplexType();
		}
	}

	private static function getVarName(v:TVar)
	{
		if (v.id == -1 && v.name == "this") return "parent";
		var name = if (v.name.startsWith('`')) 'tmp' else v.name;
		return name + '__' + v.id;
	}
}

typedef FlowGraph = { block:Array<TypedExpr>, tryctx:Array<{ t:Type, gotoHandler:TypedExpr }>, next:Null<Int>, id:Int };
